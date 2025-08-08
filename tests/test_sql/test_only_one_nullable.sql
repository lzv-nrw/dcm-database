-- setup table
CREATE TABLE table0 (
  a text,
  b text,
  CONSTRAINT only_one_nullable CHECK (
    (CASE WHEN a IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN b IS NOT NULL THEN 1 ELSE 0 END)
    = 1
  )
);

-- insert data
INSERT INTO table0 (a) VALUES ('a');
INSERT INTO table0 (b) VALUES ('b');

-- assert
SELECT '* TEST: Expected output: "b"';
SELECT b FROM table0 WHERE a IS NULL;
SELECT 'TEST - COMPLETED';

-- assert
SELECT '* TEST: Expected output: <error due to only_one_nullable-constraint>';
INSERT INTO table0 VALUES ('a2', 'b2');
SELECT 'TEST - COMPLETED';
