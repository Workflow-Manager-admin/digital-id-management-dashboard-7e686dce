#!/bin/bash

# Minimal MySQL startup/setup script
DB_NAME="myapp"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

echo "Starting MySQL setup..."

# (For Docker: you can launch a MySQL server using the official image:)
# docker run --name digital_id_mysql -p ${DB_PORT}:3306 -e MYSQL_ROOT_PASSWORD=rootpwd -e MYSQL_DATABASE=${DB_NAME} -e MYSQL_USER=${DB_USER} -e MYSQL_PASSWORD=${DB_PASSWORD} -d mysql:8

# Wait for MySQL to be ready
# (skip actual server management here; edit as per environment)

# Set up schema and initial data
echo "Setting up database schema..."
mysql --protocol=TCP -h 127.0.0.1 -P ${DB_PORT} -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME} < schema.sql

# Save connection command to a file
echo "mysql://$DB_USER:$DB_PASSWORD@localhost:$DB_PORT/$DB_NAME" > db_connection.txt
echo "Connection string saved to db_connection.txt"

# Save environment variables to a file
cat > db_visualizer/mysql.env << EOF
export MYSQL_URL="mysql://localhost:${DB_PORT}/${DB_NAME}"
export MYSQL_USER="${DB_USER}"
export MYSQL_PASSWORD="${DB_PASSWORD}"
export MYSQL_DB="${DB_NAME}"
export MYSQL_PORT="${DB_PORT}"
EOF

echo "MySQL setup and initialization complete!"
echo "Database: ${DB_NAME}"
echo "User: ${DB_USER}"
echo "Port: ${DB_PORT}"

echo ""
echo "Environment variables saved to db_visualizer/mysql.env"
echo "To use with Node.js viewer, run: source db_visualizer/mysql.env"

echo "To connect to the database, use:"
echo "mysql -h localhost -P ${DB_PORT} -u ${DB_USER} -p ${DB_NAME}"
echo "$(cat db_connection.txt)"
