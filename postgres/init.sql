CREATE TABLE configurations (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config JSONB
);
CREATE TABLE reports (
    token UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report JSONB
);
-- CREATE TABLE preservation (
-- );