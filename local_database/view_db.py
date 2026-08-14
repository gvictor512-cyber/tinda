"""Print the contents of the local SQLite database to the console."""
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), 'roommatematch_local.db')


def print_table(conn: sqlite3.Connection, name: str, limit: int = 50):
    cursor = conn.cursor()
    print(f"\n{'=' * 60}")
    print(f"Tabla: {name}")
    print('=' * 60)

    cursor.execute(f"PRAGMA table_info({name})")
    columns = [row[1] for row in cursor.fetchall()]
    print(' | '.join(columns))
    print('-' * 60)

    cursor.execute(f"SELECT * FROM {name} ORDER BY created_at DESC LIMIT ?", (limit,))
    rows = cursor.fetchall()
    if not rows:
        print('(sin filas)')
    else:
        for row in rows:
            print(' | '.join(str(value) for value in row))


def main():
    if not os.path.exists(DB_PATH):
        print(f"No existe la base de datos: {DB_PATH}")
        print("Ejecuta primero create_local_db.py")
        return

    with sqlite3.connect(DB_PATH) as conn:
        for table in ['users', 'payments', 'user_cancellations']:
            print_table(conn, table)

    print(f"\nTotal filas:")
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        for table in ['users', 'payments', 'user_cancellations']:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"  {table}: {count}")


if __name__ == '__main__':
    main()
