-- Table for significant individuals
CREATE TABLE people (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

-- Table for contact information (email addresses or phone numbers)
CREATE TABLE address (
    address VARCHAR(255) PRIMARY KEY,
    person_id INTEGER REFERENCES people(id) ON DELETE CASCADE
);

-- Table for messages (emails and SMS)
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    msgid VARCHAR(512) UNIQUE,  -- SMS/MMS ID or email Message-ID header
    their_addr VARCHAR(255) NOT NULL REFERENCES address(address),
    my_addr VARCHAR(255) NOT NULL,
    direction CHAR(1) NOT NULL, -- 's' for sent, 'r' for received
    body TEXT,
    message_timestamp TIMESTAMPTZ NOT NULL
);

-- Index for faster lookups by timestamp
CREATE INDEX idx_messages_timestamp ON messages(message_timestamp);
