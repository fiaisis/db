import hashlib
from typing import Any

from sqlalchemy import NullPool, create_engine
from sqlalchemy.orm import sessionmaker

from db.data_models import Instrument, Job, Run, Script, State, JobOwner, JobType, run_job_junction_table
from db.utils import DatabaseInconsistency


def create_hash_of_script(script: str) -> str:
    """
    Create a hash of the script that in theory is unique
    :param script: str, The script to be hashed
    :return: str, a sha512 of the passed in script
    """
    return hashlib.sha512(script.encode()).hexdigest()


class DBUpdater:
    """
    The class responsible for handling session state, and sending SQL queries via SQLAlchemy
    """

    def __init__(self, ip: str, username: str, password: str):
        connection_string = f"postgresql+psycopg2://{username}:{password}@{ip}:5432/fia"
        engine = create_engine(connection_string, poolclass=NullPool)
        self.session_maker_func = sessionmaker(bind=engine)

    # pylint: disable=too-many-arguments, too-many-locals
    def find_owner_db_entry_or_create(self, experiment_number: int | None = None, user_number: int | None = None) -> JobOwner:
        """
        Find the owner db entry or create a new one and return it. Defaults to the user number over the experiment
        number if one is provided.
        :param experiment_number: int, The experiment number that is unique
        :param user_number: int, the User number for the owner
        :return:
        """
        with self.session_maker_func() as session:
            if user_number is not None:
                owner = session.query(JobOwner).filter_by(user_number=user_number).first()
                if owner is None:
                    owner = JobOwner(user_number=user_number, experiment_number=None)
            elif experiment_number is not None:
                owner = session.query(JobOwner).filter_by(experiment_number=experiment_number).first()
                if owner is None:
                    owner = JobOwner(user_number=None, experiment_number=experiment_number)
            else:
                raise ValueError("Please provide an experiment number or user number")

            session.add(owner)
            session.commit()
            return owner

    def add_detected_run(
            self,
            instrument_name: str,
            run: Run,
            reduction_inputs: dict[str, Any],
            runner_image: str,
    ) -> Job:
        """
        This function submits data to the database from what is initially available on detected-runs message broker
        station/topic\
        :param instrument_name: str
        :param run: the run that needs to be reduced
        :param reduction_inputs: The reduction inputs
        :param runner_image: The image to be used by the runner
        :return: The created Reduction object
        """
        with self.session_maker_func() as session:
            instrument = session.query(Instrument).filter_by(instrument_name=instrument_name).first()
            if instrument is None:
                instrument = Instrument(instrument_name=instrument_name)

            existing_run = session.query(Run).filter_by(filename=run.filename).first()
            if existing_run is None:
                run.instrument = instrument
            else:
                run = existing_run

            job = Job(
                start=None,
                end=None,
                state=State.NOT_STARTED,
                inputs=reduction_inputs,
                script_id=None,
                outputs=None,
                runner_image=runner_image,
                job_type=JobType.AUTOREDUCTION
            )
            # Now create the run_reduction entry and add it
            run_reduction = run_job_junction_table(run_relationship=run, job_relationship=job)
            session.add(run_reduction)
            session.commit()

            return job

    def add_simple_job(self, job: Job) -> None:
        with self.session_maker_func() as session:
            session.add(job)
            session.commit()

    def add_rerun_job(self, original_job_id: int, new_script: str, new_owner_id: int, new_runner_image: str) -> tuple[Run, Job]:
        with self.session_maker_func() as session:
            original_job = session.get(Job, original_job_id)
            if original_job is None:
                raise DatabaseInconsistency("Database is not consistent with expected behaviour")
            # Assume the Many jobs to 1 run is still the expected relationship
            run = original_job.runs.get(0, None)
            new_job = Job(
                state=State.NOT_STARTED,
                inputs={},
                script=new_script,
                runner_image=new_runner_image,
                run=run,
                owner_id=new_owner_id,
                job_type=JobType.RERUN
            )
            session.add(new_job)
            session.commit()
        return run, new_job


    def update_script(self, job: Job, job_script: str, script_sha: str) -> None:
        """
        Updates the script tied to a reduction in the DB
        :param job: The reduction to be updated
        :param job_script: The contents of the script to be added
        :param script_sha: The sha of that script
        :return:
        """
        with self.session_maker_func() as session:
            script_hash = create_hash_of_script(job_script)
            script = session.query(Script).filter_by(script_hash=script_hash).first()
            if script is None:
                script = Script(script=job_script, sha=script_sha, script_hash=script_hash)

            job.script = script
            session.add(job)
            session.commit()