-- setup table
CREATE TABLE table0 (
  a text
);
CREATE UNIQUE INDEX only_one_a ON table0 ((1)) WHERE a IS NOT NULL;

-- insert data
INSERT INTO table0 VALUES ('a');

-- assert
SELECT '* TEST: Expected output: <no error>';
INSERT INTO table0 VALUES (NULL);
SELECT 'TEST - COMPLETED';

-- assert
SELECT '* TEST: Expected output: <error due to only_one_a-constraint>';
INSERT INTO table0 VALUES ('a2');
SELECT 'TEST - COMPLETED';
