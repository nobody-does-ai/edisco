# Filtering Messages for Court Case

## Overview

The script now supports filtering messages by contact names and phone numbers using a simple text file. This is particularly useful for court cases where you only need messages involving specific parties.

## How It Works

The filter uses a **hash-based lookup** for fast matching:

```perl
my %filter_hash;
# Loads entries from file into hash with value = 1
# Then checks: if($filter_hash{$address}) { include_message(); }
```

The filter checks:
1. **Contact name** (exact match)
2. **Phone number/address** (exact match)
3. **All MMS participants** (for group messages)
4. **Partial contact name match** (substring search)

## Filter File Format

Create a text file with one entry per line:

```
# Comments start with #
# Blank lines are ignored

# Contact names
John Paul
Lisa Paul

# Phone numbers
+17343551065
+17342726715

# Your aliases
Nobody
Church Of The Invisible Hand
```

## Usage

```bash
./sms2mbox.pl --input backup.xml \
              --output filtered.mbox \
              --filter paul_family_filter.txt
```

## Your Current Filter Results

**Input**: 1,533 total messages  
**Output**: 570 filtered messages (37% of total)

**Breakdown**:
- John Paul: 235 messages
- Lisa Paul: 104 messages
- Shirley Paul: 0 messages (excluded as requested)
- Your messages (Nobody, Church Of The Invisible Hand): 44 messages
- Group conversations: ~187 messages

**Attachments**: 4 files extracted

## Why This Approach?

Using a hash with `if($hash{$key})` is:
- **Fast**: O(1) lookup time
- **Simple**: Easy to understand and modify
- **Flexible**: Supports both names and numbers
- **Maintainable**: Filter file is plain text, easy to edit

## Adding More Filters

To add someone to the filter:

1. Edit `paul_family_filter.txt`
2. Add their contact name or phone number
3. Re-run the script

Example:
```
# Add attorney
Jane Smith Attorney
+17345551234
```

## Group Messages

The filter automatically includes group MMS messages if **any participant** matches the filter. For example:

- Group: "Church Of The Invisible Hand, Lisa Paul, John Paul"
- Matches because: Lisa Paul AND John Paul are in the filter
- Result: All messages in this group conversation are included

## Court Presentation

The filtered mbox file:
- Contains only relevant conversations
- Maintains chronological order
- Preserves all metadata (dates, times, participants)
- Can be imported into email clients for easy review
- Attachments are extracted separately with references

This makes it easy to:
- Review conversations chronologically
- Search for specific content
- Print or export specific threads
- Present in court with proper context
