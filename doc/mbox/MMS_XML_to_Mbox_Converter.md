# SMS/MMS XML to Mbox Converter

This Perl script converts SMS Backup & Restore XML files into standard mbox format, suitable for importing into email clients or archiving.

## Features

The script processes both SMS and MMS messages from Android backup files and converts them into a threaded mbox format with the following capabilities:

- **SMS messages** are converted directly to mbox format with proper headers and body text
- **MMS text content** is extracted and treated as the message body
- **MMS attachments** (images, audio, video, etc.) are saved to a separate directory with references in the message body
- **SMIL parts** (presentation metadata) are ignored as they contain no user content
- **HTML entities** in message text are properly decoded (e.g., `&#10;` becomes a newline)
- Messages are **sorted chronologically** for easy threading
- Proper **mbox format compliance** including "From " line quoting

## Requirements

The script requires the following Perl modules:

- `XML::LibXML` - for parsing the XML backup file
- `MIME::Base64` - for decoding attachment data
- `HTML::Entities` - for decoding HTML entities in text

On Ubuntu/Debian systems, install with:

```bash
sudo apt-get install libxml-libxml-perl libhtml-parser-perl
```

## Usage

Basic usage:

```bash
./sms2mbox.pl --input sms-backup.xml
```

Full options:

```bash
./sms2mbox.pl --input <xml_file> [options]

Required:
  --input <file>        Input XML file from SMS Backup & Restore

Options:
  --output <file>       Output mbox file (default: messages.mbox)
  --attachments <dir>   Directory for attachments (default: attachments/)
  --skip-mms            Skip MMS messages, only convert SMS
  --help                Show help message
```

### Example

```bash
./sms2mbox.pl --input sms-20251226000123.xml \
              --output my-messages.mbox \
              --attachments my-attachments
```

This will create:
- `my-messages.mbox` - mbox file with all messages
- `my-attachments/` - directory containing extracted attachments

## Output Format

### Mbox Messages

Each message in the mbox file follows standard RFC 4155 format:

```
From +17345551234@phone.local Tue Oct 22 04:37:20 2024
From: Contact Name <sms+17345551234@phone.local>
To: Me
Date: Oct 22, 2024 4:37:20 AM
Subject: 
Content-Type: text/plain; charset=UTF-8

Message body text here.

```

### Attachment Handling

When an MMS message contains attachments, they are:

1. **Extracted** to the attachments directory with filenames like `<timestamp>_<original_name>.<ext>`
2. **Referenced** in the message body as `[Attachment: filename.jpg]`

For example:

```
From: Contact Name <sms+17345551234@phone.local>
To: Me
Date: Jan 31, 2025 8:40:25 AM
Subject: 
Content-Type: text/plain; charset=UTF-8

Check out this photo!

[Attachment: 1738330825000_image.jpg]
```

### MMS Text Parts

If an MMS message contains multiple text parts, they are concatenated with blank lines between them. Non-text attachments are listed at the end.

### SMIL Parts

SMIL (Synchronized Multimedia Integration Language) parts are presentation instructions that tell the phone how to display MMS content (timing, layout, etc.). Since these don't contain actual user content, the script ignores them entirely. This is the correct behavior as SMIL is metadata, not message content.

## Message Types

The script handles:

- **SMS** - Simple text messages
- **MMS** - Multimedia messages with:
  - Text content (extracted as body)
  - Images (JPEG, PNG, GIF, etc.)
  - Audio (MP3, AMR, etc.)
  - Video (MP4, 3GP, etc.)
  - Other attachments (PDF, vCard, etc.)

## Threading

Messages are sorted chronologically by timestamp, which creates a natural threading effect when viewed in email clients that support conversation threading. All messages are in a single mbox file, making it easy to search and browse your complete message history.

## Character Encoding

All output is UTF-8 encoded, ensuring proper display of international characters, emoji, and special symbols.

## Importing into Email Clients

The generated mbox file can be imported into most email clients:

- **Thunderbird**: File → Import → Import from a file → Mbox
- **Apple Mail**: File → Import Mailboxes → Files in mbox format
- **mutt**: Point to the mbox file directly
- **Gmail**: Use Google Takeout import (may require additional formatting)

## Notes

- Phone numbers are converted to email-like addresses (e.g., `sms+17345551234@phone.local`)
- Group MMS messages show all participants in the address field
- The script preserves message direction (sent vs. received)
- Empty MMS messages are marked as `[Empty MMS message]`
- Lines starting with "From " in message bodies are properly quoted with ">" to avoid breaking mbox format

## Troubleshooting

If you encounter issues:

1. **XML parsing errors**: Ensure the input file is a valid SMS Backup & Restore XML file
2. **Missing modules**: Install required Perl modules (see Requirements section)
3. **Permission errors**: Ensure write permissions for output file and attachments directory
4. **Large files**: The script loads the entire XML into memory; for very large backups (10,000+ messages), you may need sufficient RAM

## License

This script is provided as-is for personal use. Feel free to modify and distribute.
