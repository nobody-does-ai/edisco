# Deduplication Feature

## Overview

The script now automatically deduplicates messages when running successive backups. If the output mbox file already exists, it will load existing messages and skip duplicates.

## How It Works

**Deduplication Key**: `timestamp:address:msg_type:body_snippet`

- **timestamp**: Millisecond precision (13 digits)
- **address**: Phone number or contact identifier
- **msg_type**: 1=received, 2=sent
- **body_snippet**: First 50 characters of message body (whitespace normalized)

This combination ensures uniqueness while keeping the key simple.

## Why This Key?

We started with just `timestamp:address` but discovered edge cases:

1. **Same timestamp, different direction**: You can send and receive messages at the exact same millisecond
2. **Same timestamp, same person, different messages**: Rare but possible - two messages received in the same millisecond

The body snippet solves both problems without making the key unnecessarily complex.

## Usage

Just run the script multiple times with the same output file:

```bash
# First run - creates file with 570 messages
./sms2mbox.pl --input backup1.xml --output messages.mbox --filter paul_family_filter.txt

# Second run - loads existing, adds only new messages
./sms2mbox.pl --input backup2.xml --output messages.mbox --filter paul_family_filter.txt
```

Output:
```
Loading existing messages for deduplication...
Loaded 569 existing messages
...
Wrote 569 of 1533 messages (filtered), skipped 1 duplicates
```

## Implementation Details

### Custom Headers

The script adds two custom headers to each message for deduplication:

```
X-Timestamp: 1729382477000
X-MsgType: 1
```

These are extracted when loading the existing mbox file.

### Hash-Based Lookup

```perl
my %seen_messages;
# Key: "timestamp:address:msg_type:body_snippet"
# Value: 1 (just a flag)

if($seen_messages{$key}) {
    # Skip duplicate
} else {
    # Write message
    $seen_messages{$key} = 1;
}
```

Fast O(1) lookups using Perl's built-in hash.

### File Handling

The script:
1. Loads existing mbox file BEFORE opening for write
2. Builds hash of existing messages
3. Opens output file (truncates it)
4. Writes all messages (old + new), skipping duplicates

This ensures the output file is always complete and sorted chronologically.

## Edge Cases Handled

- **Empty messages**: Uses `[Empty MMS message]` as body
- **Whitespace differences**: Normalized in body snippet
- **Missing msg_type**: Defaults to empty string
- **File doesn't exist**: Silently skips deduplication

## Performance

- Loading 569 existing messages: ~0.1 seconds
- Hash lookups: O(1) - instant
- Total overhead: Negligible

## Limitations

If two messages have:
- Same timestamp (to the millisecond)
- Same address
- Same direction (sent/received)
- Same first 50 characters of body

They will be considered duplicates. This is extremely unlikely in practice.

## For Court Cases

This feature is particularly useful for court cases where you need to:
- Maintain a running archive of messages
- Add new backups without duplicating evidence
- Ensure chronological consistency
- Have a complete, deduplicated record

The deduplication is deterministic - running the same backup twice produces identical results.
