"""Create a local SQLite database for RoomMate Match with sample data."""
import sqlite3
import os
from datetime import datetime, timedelta

DB_PATH = os.path.join(os.path.dirname(__file__), 'roommatematch_local.db')


def create_tables(conn: sqlite3.Connection):
    cursor = conn.cursor()

    cursor.executescript(
        """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            firebase_uid TEXT UNIQUE,
            phone TEXT,
            first_name TEXT,
            last_name TEXT,
            city TEXT,
            is_active BOOLEAN DEFAULT 1,
            is_premium BOOLEAN DEFAULT 0,
            is_verified BOOLEAN DEFAULT 0,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
            amount INTEGER NOT NULL,
            currency TEXT DEFAULT 'EUR',
            status TEXT CHECK(status IN ('pending', 'succeeded', 'failed', 'refunded')),
            provider TEXT DEFAULT 'stripe',
            provider_payment_id TEXT,
            plan_type TEXT,
            created_at TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS user_cancellations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
            cancellation_type TEXT CHECK(cancellation_type IN ('account_deletion', 'subscription_cancel', 'manual_deactivation')),
            reason TEXT,
            created_at TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
        CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at);
        CREATE INDEX IF NOT EXISTS idx_cancellations_created_at ON user_cancellations(created_at);
        """
    )
    conn.commit()


def seed_data(conn: sqlite3.Connection):
    cursor = conn.cursor()

    # Sample users
    users = [
        ('alice@example.com', 'uid_001', '600111222', 'Alice', 'García', 'Madrid', 1, 1, 1),
        ('bob@example.com', 'uid_002', '600333444', 'Bob', 'Martínez', 'Barcelona', 1, 0, 1),
        ('carol@example.com', 'uid_003', '600555666', 'Carol', 'López', 'Valencia', 1, 1, 0),
        ('dave@example.com', 'uid_004', '600777888', 'Dave', 'Sánchez', 'Sevilla', 0, 0, 0),
        ('eve@example.com', 'uid_005', '600999000', 'Eve', 'Fernández', 'Madrid', 1, 1, 1),
        ('frank@example.com', 'uid_006', '611000111', 'Frank', 'Pérez', 'Bilbao', 1, 0, 0),
    ]

    now = datetime.now()
    user_ids = []
    for i, u in enumerate(users):
        created_at = (now - timedelta(days=30 - i * 5)).isoformat()
        cursor.execute(
            """
            INSERT INTO users (email, firebase_uid, phone, first_name, last_name, city, is_active, is_premium, is_verified, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (*u, created_at),
        )
        user_ids.append(cursor.lastrowid)

    # Sample payments
    payments = [
        (user_ids[0], 999, 'EUR', 'succeeded', 'stripe', 'pi_001', 'premium_yearly'),
        (user_ids[2], 999, 'EUR', 'succeeded', 'stripe', 'pi_002', 'premium_yearly'),
        (user_ids[4], 1099, 'EUR', 'succeeded', 'stripe', 'pi_003', 'premium_monthly'),
        (user_ids[1], 999, 'EUR', 'failed', 'stripe', 'pi_004', 'premium_yearly'),
    ]

    for j, p in enumerate(payments):
        created_at = (now - timedelta(days=20 - j * 3)).isoformat()
        cursor.execute(
            """
            INSERT INTO payments (user_id, amount, currency, status, provider, provider_payment_id, plan_type, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (*p, created_at),
        )

    # Sample cancellations
    cancellations = [
        (user_ids[3], 'account_deletion', 'Found a roommate elsewhere'),
        (user_ids[5], 'subscription_cancel', 'Too expensive'),
    ]

    for k, c in enumerate(cancellations):
        created_at = (now - timedelta(days=10 - k * 2)).isoformat()
        cursor.execute(
            """
            INSERT INTO user_cancellations (user_id, cancellation_type, reason, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (*c, created_at),
        )

    conn.commit()


def main():
    # Remove old database to start fresh
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    with sqlite3.connect(DB_PATH) as conn:
        create_tables(conn)
        seed_data(conn)

    print(f"Base de datos local creada: {DB_PATH}")


if __name__ == '__main__':
    main()
