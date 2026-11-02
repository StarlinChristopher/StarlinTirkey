import Database from 'better-sqlite3';
import 'dotenv/config';
import path from 'node:path';
import fs from 'node:fs';

const databasePath = process.env.DATABASE_URL || '/mnt/e/StarlinTirkey/db_storage/meralocal.db';
fs.mkdirSync(path.dirname(databasePath), { recursive: true });

const db = new Database(databasePath);
db.pragma('journal_mode = WAL');
db.pragma('synchronous = NORMAL');
db.exec(`
  CREATE TABLE IF NOT EXISTS project_audits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT NOT NULL,
    status TEXT NOT NULL,
    issues_found INTEGER DEFAULT 0,
    commit_hash TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
`);

export default db;
