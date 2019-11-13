-- Everything in this file will be executed by user 'buddy' in database main

-- Expects variable 'suffix' to be set

\c main

CREATE TABLE inventory_:suffix (
    id SERIAL PRIMARY KEY,
    product TEXT,
    cost DOUBLE PRECISION
);
INSERT INTO inventory_:suffix VALUES
    (1, 'candy bar', 2.5),
    (2, 'sunglasses', 14.9),
    (3, 'shampoo', 11),
    (4, 'gum', 1);

CREATE TABLE customers_:suffix (
    id SERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    age INT
);
INSERT INTO customers_:suffix VALUES
    (1, 'Aaron', 'Shiver', 25),
    (2, 'Bill', 'Karson', 51),
    (3, 'Carol', 'Brown', 34),
    (4, 'Darcy', 'Yates', 18),
    (5, 'Edgar', 'Zaryna', 67);