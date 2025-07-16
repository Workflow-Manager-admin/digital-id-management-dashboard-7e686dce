# digital-id-management-dashboard-7e686dce

## Digital ID Database Container

This container now runs a MySQL instance for the Digital ID Management Dashboard.

### Connection/Environment Variables

Make sure these environment variables are set (for the backend or any database client):
- `MYSQL_URL`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `MYSQL_DB`
- `MYSQL_PORT`

Example:
```
MYSQL_URL=localhost
MYSQL_USER=appuser
MYSQL_PASSWORD=dbuser123
MYSQL_DB=myapp
MYSQL_PORT=5000
```

### Usage

- A sample MySQL connection string is in `digital_id_database/db_connection.txt`.
- To connect (from backend, CLI, or MySQL Workbench):
  ```
  mysql -h localhost -P 5000 -u appuser -p myapp
  ```
  or use (node-mysql etc):
  ```
  mysql://appuser:dbuser123@localhost:5000/myapp
  ```
- The backend and other clients should read the appropriate environment variables for these settings to assure correct connectivity between components.

See `db_visualizer/mysql.env` for a compatible format for JS/TS tools.

**Note:** The schema (`schema.sql`) is now written for MySQL, not PostgreSQL.
