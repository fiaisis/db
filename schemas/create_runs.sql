DROP TABLE IF EXISTS runs_reductions;
DROP TABLE IF EXISTS reductions;
DROP TYPE IF EXISTS state;
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
ALTER TABLE reductions ADD reduction_stack_trace VARCHAR;
