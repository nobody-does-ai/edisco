# Contacts File

## Overview

The `contacts.json` file maps all phone numbers, email addresses, and RCS identifiers to their contact names as they appear in the SMS/MMS backup.

## Format

Standard JSON object with address→name mappings:
```json
{
  "+17343551065": "John Paul",
  "+17342726715": "Lisa Paul",
  "+16034000820": "Nobody",
  "d4vtcnrqgm2dambq...@rcs.google.com": "(Unknown)"
}
```

## Address Types

The file includes three types of addresses:

### 1. Phone Numbers
Standard format with country code:
```json
{
  "+17343551065": "John Paul",
  "+16034000820": "Nobody"
}
```

### 2. Group MMS Addresses
Multiple phone numbers separated by `~`:
```json
{
  "+16037620273~+17342726715~+17343551065": "Church Of The Invisible Hand, Lisa Paul, John Paul"
}
```

### 3. RCS/Email Addresses
Google RCS identifiers and email addresses:
```json
{
  "d4vtcnrqgm2dambqhazdah3cgrrdgyjsgiytcyzwha2dkztghaytozrzg43giobrmm2wknlcgm======@rcs.google.com": "(Unknown)"
}
```

## Your Phone Numbers

Based on the MMS address analysis, your phone numbers are:
- `+16034000820` (appears as "Nobody")
- `+16037620273` (appears as "Church Of The Invisible Hand")

## Statistics

From your backup:
- **119 unique addresses**
- **24 known contacts**
- **95 unknown contacts**
- **Phone numbers**: ~100
- **RCS addresses**: ~8
- **Group addresses**: ~5
- **Short codes**: ~6 (e.g., `35433`, `99513`)

## Usage in Perl

```perl
use JSON::PP;

# Load contacts
open(my $fh, '<:utf8', 'contacts.json') or die $!;
local $/;  # Slurp mode
my $json_text = <$fh>;
close($fh);

my $contacts = decode_json($json_text);

# Look up a contact
my $name = $contacts->{'+17343551065'};  # "John Paul"

# Search for contacts
foreach my $addr (keys %$contacts) {
    if ($contacts->{$addr} =~ /Paul/i) {
        print "$addr => $contacts->{$addr}\n";
    }
}
```

See `contacts_example.pl` for a complete working example.

## Generating the File

```bash
./extract_contacts.pl backup.xml > contacts.json
```

The extraction script:
- Parses the entire XML file
- Extracts all `address` and `contact_name` pairs
- Deduplicates (prefers named contacts over "(Unknown)")
- Outputs pretty-printed JSON sorted by key

## Contact Name Conflicts

If the same address appears with multiple contact names, the script prefers:
1. Named contacts over `(Unknown)`
2. The last occurrence in the XML

## For Court Cases

This contacts file provides:
- Complete mapping of all parties involved
- Evidence of contact relationships
- Timeline context (who you were messaging)
- Group conversation participants
- Easy integration with other Perl scripts

You can use it to:
- Identify all communications with specific people
- Verify contact information
- Document relationships
- Cross-reference with phone records
- Automate contact lookups in email scripts

## Why JSON?

JSON format advantages:
- **Easy to parse** in Perl with `JSON::PP` (core module)
- **Human-readable** for manual inspection
- **Standard format** compatible with many tools
- **Structured data** easier to work with than flat files
- **No escaping issues** with special characters in names
