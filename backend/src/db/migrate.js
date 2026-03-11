const fs = require('fs');
const path = require('path');
const { pool } = require('../config/db');

/**
 * Run all SQL migration files in order.
 * Reads .sql files from the migrations directory and executes them.
 */
async function runMigrations() {
    const migrationsDir = path.join(__dirname, 'migrations');
    const files = fs
        .readdirSync(migrationsDir)
        .filter((f) => f.endsWith('.sql'))
        .sort();

    console.log(`📦 Found ${files.length} migration(s)`);

    for (const file of files) {
        const filePath = path.join(migrationsDir, file);
        const sql = fs.readFileSync(filePath, 'utf-8');

        // Strip comment-only lines, then split by semicolons
        const stripped = sql
            .split('\n')
            .filter((line) => !line.trim().startsWith('--'))
            .join('\n');

        const statements = stripped
            .split(';')
            .map((s) => s.trim())
            .filter((s) => s.length > 0);

        console.log(`  ▶ Running ${file} (${statements.length} statements)...`);

        for (const statement of statements) {
            try {
                await pool.query(statement);
            } catch (err) {
                // Ignore "database/table already exists" and "duplicate index" errors
                if (
                    err.code === 'ER_DB_CREATE_EXISTS' ||
                    err.code === 'ER_TABLE_EXISTS_ERROR' ||
                    err.code === 'ER_DUP_KEYNAME' ||
                    err.code === 'ER_DUP_FIELDNAME'
                ) {
                    continue;
                }
                console.error(`  ❌ Error in ${file}:`, err.message);
                throw err;
            }
        }

        console.log(`  ✅ ${file} completed`);
    }

    console.log('📦 All migrations complete');
}

module.exports = { runMigrations };
