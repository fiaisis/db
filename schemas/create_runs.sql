DROP TABLE IF EXISTS runs_reductions;
DROP TABLE IF EXISTS reductions;
DROP TYPE IF EXISTS job_type;
DROP TABLE IF EXISTS scripts;
DROP TABLE IF EXISTS runs;
DROP TABLE IF EXISTS instruments;

-- Create the table that contains all instrument specific data
CREATE TABLE IF NOT EXISTS instruments (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    instrument_name VARCHAR UNIQUE
);

-- Create the table that contains all our requested runs
CREATE TABLE IF NOT EXISTS runs (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    filename VARCHAR,
    instrument_id INT REFERENCES instruments(id),
    title VARCHAR,
    users VARCHAR,
    experiment_number INT,
    run_start TIMESTAMP,
    run_end TIMESTAMP,
    good_frames INT,
    raw_frames INT
);

-- Create the table that contains unique script values
CREATE TABLE IF NOT EXISTS scripts (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    script VARCHAR UNIQUE
);

-- Create the state enum but only if not already made
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'state') THEN
        CREATE TYPE state AS ENUM ('SUCCESSFUL', 'UNSUCCESSFUL', 'ERROR', 'NOT_STARTED');
    END IF;
END $$;

-- Create the table that holds all reductions that have been completed
CREATE TABLE IF NOT EXISTS reductions (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    reduction_start TIMESTAMP,
    reduction_end TIMESTAMP,
    reduction_state state,
    reduction_status_message VARCHAR,
    reduction_inputs jsonb,
    script_id INT REFERENCES scripts(id),
    reduction_outputs VARCHAR
);

-- This table ties each reduction to a respective run, it is a 1 run to many reduction relationship
CREATE TABLE IF NOT EXISTS runs_reductions (
    run_id INT REFERENCES runs(id),
    reduction_id INT REFERENCES reductions(id)
);

-- Migration 1
ALTER TABLE instruments DROP COLUMN latest_run;
ALTER TABLE instruments ADD latest_run VARCHAR;

-- Migration 2
ALTER TABLE scripts ADD sha VARCHAR;

-- Migration 3
ALTER TABLE scripts ADD script_hash VARCHAR UNIQUE;
ALTER TABLE scripts DROP CONSTRAINT scripts_script_key;
ALTER TABLE reductions ALTER COLUMN reduction_state SET NOT NULL;

-- Migration 4
ALTER TABLE reductions ADD stacktrace VARCHAR;

-- Migration 5
ALTER TABLE reductions ADD runner_image VARCHAR;

-- Migration 6
CREATE TABLE IF NOT EXISTS staff (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    user_number INT NOT NULL
);

-- Migration 7
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_type') THEN
        CREATE TYPE job_type AS ENUM ('RERUN', 'SIMPLE', 'AUTOREDUCTION');
    END IF;
END $$;
CREATE TABLE IF NOT EXISTS job_owners (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    experiment_number INT UNIQUE,
    user_number INT UNIQUE
);
INSERT INTO job_owners(experiment_number) SELECT DISTINCT experiment_number FROM runs;
ALTER TABLE runs ADD owner_id INT REFERENCES job_owners(id);
UPDATE runs SET owner_id = job_owners.id FROM job_owners WHERE runs.experiment_number = job_owners.experiment_number;
ALTER TABLE runs DROP experiment_number;
ALTER TABLE reductions ADD owner_id INT REFERENCES job_owners(id);
UPDATE reductions SET owner_id = big.o_id FROM (SELECT reductions.id AS r_id, runs.owner_id AS o_id FROM runs INNER JOIN runs_reductions ON runs.id = runs_reductions.run_id INNER JOIN reductions ON runs_reductions.reduction_id = reductions.id) as big WHERE reductions.id = big.r_id;
ALTER TABLE reductions ADD instrument_id INT REFERENCES instruments(id);
UPDATE reductions SET instrument_id = big.i_id FROM (SELECT reductions.id AS r_id, runs.instrument_id AS i_id FROM runs INNER JOIN runs_reductions ON runs.id = runs_reductions.run_id INNER JOIN reductions ON runs_reductions.reduction_id = reductions.id) as big WHERE reductions.id = big.r_id;
ALTER TABLE reductions RENAME TO jobs;
ALTER TABLE jobs RENAME COLUMN reduction_start TO start;
ALTER TABLE jobs RENAME COLUMN reduction_end TO "end";
ALTER TABLE jobs RENAME COLUMN reduction_state TO state;
ALTER TABLE jobs RENAME COLUMN reduction_status_message TO status_message;
ALTER TABLE jobs RENAME COLUMN reduction_inputs TO inputs;
ALTER TABLE jobs RENAME COLUMN reduction_outputs TO outputs;
ALTER TABLE jobs ADD job_type job_type;
ALTER TABLE runs_reductions RENAME TO runs_jobs;
ALTER TABLE runs_jobs RENAME COLUMN reduction_id TO job_id;

-- Undo Migration 7
ALTER TABLE jobs DROP COLUMN job_type;
ALTER TABLE jobs RENAME COLUMN start TO reduction_start;
ALTER TABLE jobs RENAME COLUMN "end" TO reduction_end;
ALTER TABLE jobs RENAME COLUMN state TO reduction_state;
ALTER TABLE jobs RENAME COLUMN status_message TO reduction_status_message;
ALTER TABLE jobs RENAME COLUMN inputs TO reduction_inputs;
ALTER TABLE jobs RENAME COLUMN outputs TO reduction_outputs;
ALTER TABLE jobs RENAME TO reductions;
ALTER TABLE runs ADD experiment_number INT;
UPDATE runs SET experiment_number = job_owners.experiment_number FROM job_owners WHERE runs.owner_id = job_owners.id;
ALTER TABLE runs DROP owner_id;
ALTER TABLE reductions DROP instrument_id;
ALTER TABLE reductions DROP owner_id;
DROP TABLE job_owners;
DROP TYPE IF EXISTS job_type;
ALTER TABLE runs_jobs RENAME TO runs_reductions;
ALTER TABLE runs_reductions RENAME COLUMN job_id TO reduction_id;

-- Migration 8
ALTER TABLE jobs ADD run_id INT REFERENCES runs(id);
UPDATE jobs SET run_id = runs_jobs.run_id FROM (SELECT * FROM runs_jobs) as runs_jobs WHERE jobs.id = runs_jobs.job_id;
DROP TABLE IF EXISTS runs_jobs;

-- Undo Migration 8
CREATE TABLE IF NOT EXISTS runs_jobs (
    run_id INT REFERENCES runs(id),
    job_id INT REFERENCES jobs(id)
);
INSERT INTO runs_jobs(run_id, job_id) SELECT run_id, id FROM jobs;
ALTER TABLE jobs DROP run_id;

-- Migration 9
ALTER TABLE instruments ADD specification JSONB;

-- Undo Migration 9
ALTER TABLE instruments DROP specification;