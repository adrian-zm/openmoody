CREATE TABLE boards (
  id INTEGER PRIMARY KEY,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  last_seen TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE links (
  token_hash BLOB NOT NULL PRIMARY KEY CHECK (length(token_hash) = 32),
  board_id INTEGER NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('view', 'edit', 'admin')),
  UNIQUE (board_id, role)
);
CREATE TABLE items(
    id INTEGER PRIMARY KEY,
    board_id INTEGER NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('text', 'url', 'img', 'iframe', 'color')),
    content TEXT NOT NULL CHECK (length(content) >= 1), 
  size_bytes INTEGER CHECK (size_bytes IS NULL OR size_bytes >= 0),
    title TEXT, 
    image TEXT, 
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
-- No te rayes que esto tiene sentido, que te pensabas que era un comentario de IA eh, anda y ponte a trabajar que hay que tener esto terminado para mañana
CREATE INDEX items_board_id ON items (board_id);

