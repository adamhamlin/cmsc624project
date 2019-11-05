\c main

CREATE TABLE dummy (
    id SERIAL PRIMARY KEY,
    name TEXT,
    amount DOUBLE PRECISION
);
INSERT INTO dummy VALUES
    (1, 'a', 2.5),
    (2, 'b', 14.9),
    (3, 'c', 11),
    (4, 'd', 0);