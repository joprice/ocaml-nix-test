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
