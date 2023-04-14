DROP TABLE IF EXISTS runs_reductions;
DROP TABLE IF EXISTS reductions;
DROP TYPE IF EXISTS state;
DROP TABLE IF EXISTS scripts;
DROP TABLE IF EXISTS runs;
DROP TABLE IF EXISTS instruments;

-- Create the table that contains all instrument specific data
CREATE TABLE IF NOT EXISTS instruments (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    instrument_name VARCHAR
);

-- Create the table that contains all our requested runs
CREATE TABLE IF NOT EXISTS runs (
    id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    filename VARCHAR,
    instrument INT REFERENCES instruments(id),
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
        CREATE TYPE state AS ENUM ('Successful', 'Unsuccessful', 'Error', 'NotStarted');
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
    script INT REFERENCES scripts(id),
    reduction_outputs VARCHAR
);

-- This table ties each reduction to a respective run, it is a 1 run to many reduction relationship
CREATE TABLE IF NOT EXISTS runs_reductions (
    run INT REFERENCES runs(id),
    reduction INT REFERENCES reductions(id)
);