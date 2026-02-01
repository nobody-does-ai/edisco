# Litigation Message Archiver

This project provides a set of Perl scripts to download your Gmail messages and import your Android SMS/MMS messages into a PostgreSQL database. The database schema is designed to support litigation research by organizing messages and linking them to specific individuals.

## Database Schema

The database consists of three tables:

1.  `people`: Stores the names of significant individuals.
2.  `address`: Stores email addresses and phone numbers, linking them to individuals in the `people` table.
3.  `messages`: Stores the content of emails and SMS/MMS messages, with sender, receiver, direction, and timestamp.

Here is the SQL schema (`schema.sql`):

```sql
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
```

## Prerequisites

### 1. PostgreSQL

You need a running PostgreSQL server. You can install it on your local machine or use a cloud-based service.

### 2. Perl Modules

You need to install several Perl modules from CPAN. You can install them using the `cpan` command:

```bash
cpan install DBI DBD::Pg JSON::PP Compress::Raw::Zlib Mail::IMAPClient IO::Socket::SSL Email::MIME Getopt::Long Digest::MD5
```

### 3. Gmail App Password

For the Gmail import to work, you need to enable 2-Factor Authentication on your Google account and create an "App Password". This is more secure than using your main password.

1.  Go to your Google Account settings.
2.  Navigate to the "Security" section.
3.  Under "Signing in to Google", click on "App passwords".
4.  Generate a new password for this application and save it securely.

## Scripts

This project includes the following scripts:

-   `schema.sql`: The database schema.
-   `decompress.pl`: Decompresses the raw zlib data from Android backups.
-   `import_sms.pl`: Parses and imports SMS/MMS JSON files into the database.
-   `import_gmail.pl`: Downloads and imports Gmail messages into the database.

## Workflow

Here is the step-by-step process to get your messages into the database.

### 1. Set up the Database

First, create the database and the tables using the `schema.sql` file.

```bash
createdb messages
psql -d messages -f schema.sql
```

### 2. Import SMS/MMS Messages

If you have an Android backup file (e.g., `sms-xxxxxxxx.ab`), you can process it as follows.

1.  **Decompress the backup file:**

    ```bash
    dd if=sms-xxxxxxxx.ab bs=24 skip=1 | perl decompress.pl > sms.json
    ```

    This will create a `sms.json` file containing your messages.

2.  **Import into the database:**

    ```bash
    perl import_sms.pl sms.json
    ```

    You can also process MMS files if you have them in a similar JSON format.

### 3. Import Gmail Messages

To import your Gmail messages, run the `import_gmail.pl` script with your credentials:

```bash
perl import_gmail.pl --gmail-user "your_email@gmail.com" --gmail-pass "your_app_password"
```

You can also specify a folder and other options:

```bash
# Import from the "Sent" folder
perl import_gmail.pl --gmail-user "..." --gmail-pass "..." --folder "[Gmail]/Sent Mail"

# Import the last 100 messages from the last 30 days
perl import_gmail.pl --gmail-user "..." --gmail-pass "..." --limit 100 --since-days 30
```

### 4. Link Addresses to People

After importing your messages, the `address` table will be populated with all the email addresses and phone numbers from your communications. You can now manually link these addresses to the significant individuals in your `people` table.

First, add the people:

```sql
INSERT INTO people (name) VALUES (
  ('Person One'),
  ('Person Two')
);
```

Then, update the `address` table to link the addresses to the people:

```sql
UPDATE address SET person_id = 1 WHERE address = 'person.one@example.com';
UPDATE address SET person_id = 2 WHERE address = '1234567890';
```

## Duplicate Prevention

The system prevents duplicate imports using the `msgid` field:

- **For emails**: Uses the standard Message-ID header (e.g., `email:<CABcd1234@mail.gmail.com>`)
- **For SMS**: Generates an MD5 hash from normalized phone number, normalized timestamp (seconds), and first 100 characters of message body (e.g., `sms:a1b2c3d4...`)
- **For MMS**: Generates an MD5 hash similar to SMS (e.g., `mms:e5f6g7h8...`)

The hash uses **normalized/processed data** (timestamps converted to seconds, phone numbers stripped of formatting) to ensure the same message always generates the same ID regardless of the source format. You can safely run the import scripts multiple times—duplicate messages will be automatically skipped based on their unique message ID.

## Key Design Decisions

- The `address` table uses the email/phone number as the primary key, so you can query messages by address without needing joins
- Direction is stored as 's' (sent) or 'r' (received) as you specified
- All scripts use consistent Perl (no Python!) and avoid underscores in table names where possible
- The Gmail script uses App Passwords instead of OAuth2 for simplicity
- Both phone numbers and email addresses are normalized for consistent matching
- Message deduplication uses email Message-ID headers for emails and MD5 hashes for SMS/MMS
