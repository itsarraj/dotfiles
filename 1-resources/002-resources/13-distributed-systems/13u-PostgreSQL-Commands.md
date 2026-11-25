# PostgreSQL Commands - Complete Reference
## Database Operations
CREATE DATABASE `CREATE DATABASE database_name;` - Creates a new database with the specified name
DROP DATABASE `DROP DATABASE database_name;` - Permanently deletes the specified database
ALTER DATABASE `ALTER DATABASE database_name RENAME TO new_name;` - Renames an existing database
SELECT DATABASE `\c database_name` or `\connect database_name` - Connects to a specific database (psql command)
## Table Operations
CREATE TABLE `CREATE TABLE table_name (column_name data_type constraints, ...);` - Creates a new table with specified columns and constraints
DROP TABLE `DROP TABLE table_name;` - Deletes a table and all its data permanently
ALTER TABLE `ALTER TABLE table_name action;` - Modifies table structure (add column, drop column, rename, etc.)
TRUNCATE TABLE `TRUNCATE TABLE table_name;` - Removes all rows from a table but keeps the table structure
## Data Manipulation (DML)
INSERT `INSERT INTO table_name (columns) VALUES (values);` - Adds new rows to a table
SELECT `SELECT columns FROM table_name WHERE condition;` - Retrieves data from tables
UPDATE `UPDATE table_name SET column = value WHERE condition;` - Modifies existing data in rows
DELETE `DELETE FROM table_name WHERE condition;` - Removes rows from a table
## Query Clauses and Operators
WHERE `SELECT * FROM table WHERE column = 'value';` - Filters rows based on conditions
ORDER BY `SELECT * FROM table ORDER BY column ASC/DESC;` - Sorts results in ascending or descending order
GROUP BY `SELECT column, COUNT(*) FROM table GROUP BY column;` - Groups rows that have the same values
HAVING `SELECT column, COUNT(*) FROM table GROUP BY column HAVING COUNT(*) > 1;` - Filters grouped results
LIMIT `SELECT * FROM table LIMIT 10;` - Limits the number of rows returned
OFFSET `SELECT * FROM table LIMIT 10 OFFSET 20;` - Skips a specified number of rows
## JOIN Operations
INNER JOIN `SELECT * FROM table1 INNER JOIN table2 ON table1.id = table2.id;` - Returns rows with matching values in both tables
LEFT JOIN `SELECT * FROM table1 LEFT JOIN table2 ON condition;` - Returns all rows from left table and matching rows from right table
RIGHT JOIN `SELECT * FROM table1 RIGHT JOIN table2 ON condition;` - Returns all rows from right table and matching rows from left table
FULL OUTER JOIN `SELECT * FROM table1 FULL OUTER JOIN table2 ON condition;` - Returns all rows when there's a match in either table
CROSS JOIN `SELECT * FROM table1 CROSS JOIN table2;` - Returns Cartesian product of both tables
## Aggregate Functions
COUNT() `SELECT COUNT(*) FROM table;` - Returns number of rows
SUM() `SELECT SUM(column) FROM table;` - Returns sum of numeric column values
AVG() `SELECT AVG(column) FROM table;` - Returns average of numeric column values
MIN() `SELECT MIN(column) FROM table;` - Returns minimum value in column
MAX() `SELECT MAX(column) FROM table;` - Returns maximum value in column
## String Functions
CONCAT() `SELECT CONCAT(first_name, ' ', last_name) FROM users;` - Concatenates strings
UPPER() `SELECT UPPER(column) FROM table;` - Converts string to uppercase
LOWER() `SELECT LOWER(column) FROM table;` - Converts string to lowercase
LENGTH() `SELECT LENGTH(column) FROM table;` - Returns length of string
SUBSTRING() `SELECT SUBSTRING(column FROM 1 FOR 10) FROM table;` - Extracts substring
## Date/Time Functions
NOW() `SELECT NOW();` - Returns current timestamp
CURRENT_DATE `SELECT CURRENT_DATE;` - Returns current date
CURRENT_TIME `SELECT CURRENT_TIME;` - Returns current time
EXTRACT() `SELECT EXTRACT(YEAR FROM date_column) FROM table;` - Extracts part of date (YEAR, MONTH, DAY, etc.)
AGE() `SELECT AGE(date1, date2);` - Calculates age between two dates
## Constraints and Keys
PRIMARY KEY `CREATE TABLE table (id SERIAL PRIMARY KEY, ...);` - Uniquely identifies each row
FOREIGN KEY `ALTER TABLE child ADD FOREIGN KEY (parent_id) REFERENCES parent(id);` - Links tables together
UNIQUE `CREATE TABLE table (email VARCHAR(255) UNIQUE, ...);` - Ensures column values are unique
NOT NULL `CREATE TABLE table (name VARCHAR(255) NOT NULL, ...);` - Prevents null values
CHECK `CREATE TABLE table (age INT CHECK (age >= 18), ...);` - Validates data against condition
## Index Operations
CREATE INDEX `CREATE INDEX index_name ON table (column);` - Creates an index on a column for faster queries
DROP INDEX `DROP INDEX index_name;` - Removes an index
CREATE UNIQUE INDEX `CREATE UNIQUE INDEX index_name ON table (column);` - Creates unique index
REINDEX `REINDEX INDEX index_name;` - Rebuilds an index
## User and Role Management
CREATE USER `CREATE USER username WITH PASSWORD 'password';` - Creates a new database user
ALTER USER `ALTER USER username PASSWORD 'new_password';` - Changes user password
DROP USER `DROP USER username;` - Deletes a user
CREATE ROLE `CREATE ROLE role_name;` - Creates a new role
GRANT `GRANT privilege ON object TO user/role;` - Gives permissions to users/roles
REVOKE `REVOKE privilege ON object FROM user/role;` - Removes permissions from users/roles
## Transaction Control
BEGIN `BEGIN;` - Starts a transaction
COMMIT `COMMIT;` - Saves all changes made in transaction
ROLLBACK `ROLLBACK;` - Undoes all changes made in transaction
SAVEPOINT `SAVEPOINT savepoint_name;` - Creates a savepoint within transaction
ROLLBACK TO `ROLLBACK TO savepoint_name;` - Rolls back to a savepoint
## Backup and Restore
pg_dump `pg_dump database_name > backup.sql` - Creates SQL dump of database
pg_dumpall `pg_dumpall > all_databases.sql` - Dumps all databases including roles
psql `psql database_name < backup.sql` - Restores database from SQL dump
pg_restore `pg_restore -d database_name backup.dump` - Restores from custom format dump
## System Information and Monitoring
\l or \list - Lists all databases
\dt - Lists all tables in current database
\d table_name - Shows table structure
\du - Lists all users and roles
\dn - Lists all schemas
\df - Lists all functions
\dv - Lists all views
## Schema Operations
CREATE SCHEMA `CREATE SCHEMA schema_name;` - Creates a new schema
DROP SCHEMA `DROP SCHEMA schema_name;` - Deletes a schema
ALTER SCHEMA `ALTER SCHEMA schema_name RENAME TO new_name;` - Renames a schema
SET search_path `SET search_path TO schema_name;` - Sets default schema for operations
## View Operations
CREATE VIEW `CREATE VIEW view_name AS SELECT ... FROM ...;` - Creates a virtual table based on query
DROP VIEW `DROP VIEW view_name;` - Deletes a view
ALTER VIEW `ALTER VIEW view_name RENAME TO new_name;` - Renames a view
## Sequence Operations
CREATE SEQUENCE `CREATE SEQUENCE sequence_name;` - Creates a sequence for auto-incrementing values
NEXTVAL() `SELECT NEXTVAL('sequence_name');` - Gets next value from sequence
CURRVAL() `SELECT CURRVAL('sequence_name');` - Gets current value from sequence
DROP SEQUENCE `DROP SEQUENCE sequence_name;` - Deletes a sequence
## Data Types
SERIAL - Auto-incrementing integer (1, 2, 3...)
INTEGER/INT - Whole numbers (-2,147,483,648 to +2,147,483,647)
BIGINT - Large integers (-9,223,372,036,854,775,808 to +9,223,372,036,854,775,807)
SMALLINT - Small integers (-32,768 to +32,767)
DECIMAL/NUMERIC - Exact decimal numbers (precision, scale)
REAL - Single precision floating-point
DOUBLE PRECISION - Double precision floating-point
VARCHAR(n) - Variable-length string with max length n
TEXT - Unlimited length text
CHAR(n) - Fixed-length string of exactly n characters
BOOLEAN - True/false values
DATE - Date (YYYY-MM-DD)
TIME - Time (HH:MM:SS)
TIMESTAMP - Date and time with timezone
UUID - Universally unique identifier
JSON/JSONB - JSON data (JSONB is binary, faster for queries)
## Advanced Query Features
DISTINCT `SELECT DISTINCT column FROM table;` - Returns unique values only
AS `SELECT column AS alias FROM table;` - Renames columns in output
CASE `SELECT CASE WHEN condition THEN 'value1' ELSE 'value2' END FROM table;` - Conditional logic in queries
UNION `SELECT columns FROM table1 UNION SELECT columns FROM table2;` - Combines results from multiple queries
EXCEPT `SELECT columns FROM table1 EXCEPT SELECT columns FROM table2;` - Returns rows in first query but not second
INTERSECT `SELECT columns FROM table1 INTERSECT SELECT columns FROM table2;` - Returns rows common to both queries
## Performance and Analysis
EXPLAIN `EXPLAIN SELECT * FROM table WHERE condition;` - Shows query execution plan
ANALYZE `ANALYZE table_name;` - Updates table statistics for query planner
VACUUM `VACUUM table_name;` - Reclaims storage and updates statistics
VACUUM FULL `VACUUM FULL table_name;` - Aggressive vacuum that rewrites entire table
REINDEX `REINDEX TABLE table_name;` - Rebuilds all indexes on a table
## Window Functions
ROW_NUMBER() `SELECT ROW_NUMBER() OVER (ORDER BY column) FROM table;` - Assigns sequential numbers to rows
RANK() `SELECT RANK() OVER (ORDER BY column) FROM table;` - Ranks rows with gaps for ties
DENSE_RANK() `SELECT DENSE_RANK() OVER (ORDER BY column) FROM table;` - Ranks rows without gaps for ties
LAG() `SELECT LAG(column) OVER (ORDER BY date_column) FROM table;` - Accesses previous row's value
LEAD() `SELECT LEAD(column) OVER (ORDER BY date_column) FROM table;` - Accesses next row's value
## Common psql Commands
\h - Shows help on SQL commands
\? - Shows help on psql commands
\q - Quit psql
\i filename - Execute commands from file
\o filename - Send query results to file
\x - Toggle expanded output format
\timing - Toggle query execution time display
