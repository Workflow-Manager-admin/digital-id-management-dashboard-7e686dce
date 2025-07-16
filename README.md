# digital-id-management-dashboard-7e686dce

## Digital ID Database Container

This container runs the PostgreSQL instance for the Digital ID Management Dashboard.

### Connection/Environment Variables

Make sure these environment variables are set (for the backend or any database client):
- `POSTGRES_URL`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`
- `POSTGRES_PORT`

Example:
```
POSTGRES_URL=localhost
POSTGRES_USER=appuser
POSTGRES_PASSWORD=dbuser123
POSTGRES_DB=myapp
POSTGRES_PORT=5000
```

### Usage

- A sample connection string is in `digital_id_database/db_connection.txt`.  
- To connect (from the backend or psql):
  ```
  psql postgresql://appuser:dbuser123@localhost:5000/myapp
  ```
- The backend/other clients should read .env or explicit environment variables for these settings to assure correct connectivity between components.

See `db_visualizer/postgres.env` for a compatible format for JS/TS tools.
