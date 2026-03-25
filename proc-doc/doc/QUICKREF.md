# proc-pdf Quick Reference

## Common Workflows

### Split PDF into pages
```bash
ppdf-split -o page-%03d.pdf document.pdf
```

### Merge PDFs
```bash
ppdf-unite -o combined.pdf file1.pdf file2.pdf file3.pdf
```

### Split, remove pages, recombine
```bash
# Split
ppdf-split -o p%03d.pdf doc.pdf > pages.txt

# Remove unwanted pages (delete files or filter list)
rm p005.pdf p010.pdf p015.pdf

# Recombine remaining
ls p*.pdf | ppdf-unite -o filtered.pdf
```

### Categorize pages into separate PDFs
```bash
# Split
ppdf-split -o page-%03d.pdf document.pdf

# Organize
mkdir overview account investments transactions
mv page-001.pdf page-002.pdf overview/
mv page-010.pdf page-015.pdf account/
# ... etc

# Create category PDFs
ppdf-unite -o overview.pdf overview/*.pdf
ppdf-unite -o account.pdf account/*.pdf
ppdf-unite -o investments.pdf investments/*.pdf
ppdf-unite -o transactions.pdf transactions/*.pdf
```

## Tool Conventions

### All tools follow these rules:

1. **`-o` specifies output**
   - Required for all tools that create files
   - Can be a filename or pattern (with %d for numbers)

2. **stdout = machine-readable output**
   - List of created files (one per line)
   - Can be piped to other commands

3. **stderr = human-readable messages**
   - Progress indicators
   - Error messages
   - Informational output

4. **Exit codes**
   - 0 = success
   - Non-zero = failure

### Pattern syntax (for ppdf-split)

- `%d` - Page number: 1, 2, 3, ...
- `%03d` - Zero-padded: 001, 002, 003, ...
- `%05d` - Five digits: 00001, 00002, 00003, ...

## Examples

### Capture file list
```bash
files=$(ppdf-split -o page-%03d.pdf doc.pdf)
echo "$files" | wc -l  # Count pages
```

### Process each page
```bash
ppdf-split -o p%d.pdf doc.pdf | while read f; do
    echo "Processing $f"
    # Do something with $f
done
```

### Parallel processing
```bash
ppdf-split -o page-%03d.pdf doc.pdf | \
    xargs -P 4 -I {} sh -c 'process {}'
```

### Conditional filtering
```bash
ppdf-split -o p%03d.pdf doc.pdf | \
    grep -v 'p005\|p010\|p015' | \
    ppdf-unite -o filtered.pdf
```

## Installation

```bash
# Install dependencies
sudo apt-get install qpdf poppler-utils perl libcommon-sense-perl

# Add tools to PATH
export PATH="/path/to/proc-pdf/bin:$PATH"
```

## Getting Help

```bash
ppdf-split -h
ppdf-unite -h
```
