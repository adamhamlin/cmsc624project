\c main

-- NOTE: Expects variable 'container_num' to be set

CREATE TABLE inventory_:container_num (
    id SERIAL PRIMARY KEY,
    product TEXT,
    cost DOUBLE PRECISION
);
INSERT INTO inventory_:container_num VALUES
    (1, 'candy bar', 2.5),
    (2, 'sunglasses', 14.9),
    (3, 'shampoo', 11),
    (4, 'gum', 1);

CREATE TABLE customers_:container_num (
    id SERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    age INT
);
INSERT INTO customers_:container_num VALUES
    (1, 'Aaron', 'Shiver', 25),
    (2, 'Bill', 'Karson', 51),
    (3, 'Carol', 'Brown', 34),
    (4, 'Darcy', 'Yates', 18),
    (5, 'Edgar', 'Zaryna', 67);