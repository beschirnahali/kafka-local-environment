SELECT 'CREATE DATABASE inventory'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'inventory'
)\gexec

\c inventory

CREATE TABLE IF NOT EXISTS customers
(
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255)
);

INSERT INTO customers
(first_name,last_name,email)
VALUES
('John','Doe','john@example.com'),
('Alice','Smith','alice@example.com');
