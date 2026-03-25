# SMS/MMS XML to Mbox Conversion Design

## XML Structure Analysis

### SMS Messages
- Simple structure with attributes directly on the `<sms>` element
- Key attributes:
  - `address`: Phone number
  - `date`: Timestamp in milliseconds
  - `type`: 1=received, 2=sent
  - `body`: Message text (HTML-encoded)
  - `readable_date`: Human-readable date
  - `contact_name`: Contact name

### MMS Messages
- More complex structure with nested elements
- Key attributes on `<mms>` element:
  - `address`: Phone number(s), may be tilde-separated for group messages
  - `date`: Timestamp in milliseconds
  - `msg_box`: 1=received, 2=sent
  - `readable_date`: Human-readable date
  - `contact_name`: Contact name
  
- Contains `<parts>` element with zero or more `<part>` elements:
  - `ct`: Content type (text/plain, image/jpeg, etc.)
  - `text`: Text content (for text/plain parts)
  - `data`: Base64-encoded binary data (for attachments)
  - `name` or `cl`: Filename
  
- Contains `<addrs>` element with multiple `<addr>` elements for participants

### SMIL Parts
- Some MMS messages contain SMIL (Synchronized Multimedia Integration Language) parts
- These are presentation instructions for how to display MMS content
- **Decision**: We'll ignore SMIL parts as they're metadata about presentation, not content

## Conversion Strategy

### Mbox Format
Each message will be formatted as:
```
From <phone_number> <date>
From: <contact_name> <phone_number>
To: <recipient>
Date: <readable_date>
Subject: <blank or derived from content>

<message body>

```

### MMS Handling Strategy

1. **Text parts** (`ct="text/plain"`):
   - Extract text and include in message body
   - If it's the only part, treat as main body
   
2. **Non-text attachments** (images, audio, video):
   - Save to separate files in an "attachments" directory
   - Name format: `<timestamp>_<sequence>_<original_name>`
   - Replace in message body with: `[Attachment: <filename>]`
   
3. **SMIL parts** (`ct="application/smil"`):
   - Ignore these entirely (presentation metadata)

4. **Multiple text parts**:
   - Concatenate all text parts into the message body
   - Separate with blank lines

### Threading
- Messages will be sorted by date (chronological order)
- Each message is a separate email in the mbox
- Thread detection could be based on:
  - Same phone number/contact
  - Proximity in time
  - But for simplicity, we'll just sort chronologically

### Character Encoding
- HTML entities in the XML (like `&#10;` for newline) need to be decoded
- Output should be UTF-8

### Command Line Options
- Input XML file (required)
- Output mbox file (default: messages.mbox)
- Attachments directory (default: attachments/)
- Option to skip MMS messages
- Option to filter by date range
