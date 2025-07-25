-- setup table
CREATE TABLE table0 (
  id text,
  field1 text NOT NULL,
  field2 text NOT NULL,
  field3 text,
  UNIQUE (field1, field2, field3)
);

-- Add unique constraint to reject duplicates of (field1, field2) if
-- field3 is NULL
CREATE UNIQUE INDEX table0_missing_field3
ON table0 (field1, field2)
WHERE field3 is NULL;

-- assert constraint if field3 not null
SELECT '* TEST: Expected output: <error regarding unique-constraint>';
INSERT INTO table0 VALUES ('0', 'field1-0', 'field2-0', 'field3-0');
INSERT INTO table0 VALUES ('1', 'field1-0', 'field2-0', 'field3-0');
SELECT 'TEST - COMPLETED';

-- assert constraint if field3 null
SELECT '* TEST: Expected output: <error regarding unique-constraint>';
INSERT INTO table0 VALUES ('2', 'field1-0', 'field2-0', NULL);
INSERT INTO table0 VALUES ('3', 'field1-0', 'field2-0', NULL);
SELECT 'TEST - COMPLETED';
