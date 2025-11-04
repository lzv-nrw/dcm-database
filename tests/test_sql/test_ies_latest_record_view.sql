-- setup tables and views
CREATE TABLE ies (
    id TEXT NOT NULL PRIMARY KEY,
    other TEXT
);

CREATE TABLE records (
    id TEXT NOT NULL PRIMARY KEY,
    ie_id TEXT REFERENCES ies (id),
    datetime_changed TEXT,
    data TEXT
);

CREATE VIEW ies_with_latest_record AS
SELECT
    ies.*,
    records.id AS latest_record_id,
    records.datetime_changed AS latest_record_datetime_changed,
    records.data AS latest_record_data
FROM ies
LEFT JOIN records
    ON records.id = (
        SELECT id FROM records
        WHERE ie_id = ies.id
        ORDER BY datetime_changed DESC NULLS LAST
        LIMIT 1
    );

-- insert data
INSERT INTO ies VALUES ('ie-0', 'ie-0-data');
INSERT INTO records VALUES ('record-0', 'ie-0', '4444', 'record-0-data');
INSERT INTO records VALUES ('record-1', NULL, '9999', 'record-1-data');
INSERT INTO records VALUES ('record-2', 'ie-0', '8888', 'record-2-data');
INSERT INTO records VALUES ('record-3', 'ie-0', '1111', 'record-3-data');

-- assert
SELECT '* TEST: Expected output: "record-2-data"';
SELECT latest_record_data FROM ies_with_latest_record WHERE id = 'ie-0';
SELECT 'TEST - COMPLETED';

-- insert data
INSERT INTO records VALUES ('record-4', 'ie-0', '9999', 'record-4-data');

-- assert
SELECT '* TEST: Expected output: "record-4-data"';
SELECT latest_record_data FROM ies_with_latest_record WHERE id = 'ie-0';
SELECT 'TEST - COMPLETED';

-- insert data
INSERT INTO ies VALUES ('ie-1', 'ie-1-data');

-- assert
SELECT '* TEST: Expected output: NULL';
SELECT latest_record_data FROM ies_with_latest_record WHERE id = 'ie-1';
SELECT 'TEST - COMPLETED';
