-- setup tables
CREATE TABLE table0 (
  id text PRIMARY KEY
);

CREATE TABLE table1 (
  id text PRIMARY KEY,
  other_id text REFERENCES table0 (id) ON DELETE SET NULL
);

-- insert data
INSERT INTO table0 VALUES ('table0-0');
INSERT INTO table1 VALUES ('table1-0', 'table0-0');

-- assert
SELECT '* TEST: Expected output: "table0-0"';
SELECT other_id FROM table1 WHERE id = 'table1-0';
SELECT 'TEST - COMPLETED';

-- remove data
DELETE FROM table0;

-- assert
SELECT '* TEST: Expected output: <Null>';
SELECT other_id FROM table1 WHERE id = 'table1-0';
SELECT 'TEST - COMPLETED';
