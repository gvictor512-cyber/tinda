# Base de datos local de RoomMate Match

Esta carpeta contiene una base de datos SQLite local que puedes abrir y consultar en tu ordenador.

## Archivos

- `create_local_db.py`: crea y rellena la base de datos con datos de ejemplo.
- `view_db.py`: muestra el contenido de las tablas en la terminal.
- `roommatematch_local.db`: la base de datos SQLite generada.

## Uso

```powershell
# Crear / regenerar la base de datos
python local_database/create_local_db.py

# Ver los datos en consola
python local_database/view_db.py
```

## Tablas

- `users`: datos de usuarios, altas y estado.
- `payments`: pagos realizados.
- `user_cancellations`: bajas y cancelaciones.

## Abrir con un visor gráfico

Puedes abrir `roommatematch_local.db` con cualquier cliente SQLite, por ejemplo:

- [DB Browser for SQLite](https://sqlitebrowser.org/)
- Extensión SQLite en VS Code
- DBeaver
