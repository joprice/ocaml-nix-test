CREATE TABLE IF NOT EXISTS comment (
  id SERIAL,
  text TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dream_session (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  expires_at REAL NOT NULL,
  payload TEXT NOT NULL
);

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE TABLE sensors (
  id SERIAL PRIMARY KEY,
  type TEXT NOT NULL,
  location TEXT NOT NULL
);

CREATE TABLE sensor_data (
    time TIMESTAMPTZ NOT NULL,
    sensor_id INTEGER REFERENCES sensors (id),
    value DOUBLE PRECISION
);

SELECT create_hypertable('sensor_data', 'time');
