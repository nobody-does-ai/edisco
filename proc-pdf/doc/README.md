# proc-pdf: PDF Processing Toolkit

**Part of the disco eDiscovery suite**

A collection of command-line tools for PDF manipulation with consistent, composable interfaces. Built for legal document processing, but useful for anyone working with PDFs at scale.

## Philosophy

**Access to justice shouldn't require expensive software.**

Legal document discovery costs can bankrupt people before they get their day in court. Commercial eDiscovery platforms charge thousands of dollars for operations that amount to OCR and database queries. We're changing that.

This toolkit provides:
- **Free and open source** tools anyone can use
- **Consistent interfaces** that compose naturally
- **Transparent operation** - you can see exactly what's happening
- **No vendor lock-in** - standard PDF formats throughout

## Design Principles

### 1. Consistent Command-Line Interface

All tools follow these conventions:

- **`-o` for output**: Every tool that creates files uses `-o` to specify output
- **stdout for results**: Non-filter tools print created filenames to stdout (one per line)
- **stderr for diagnostics**: Progress, errors, and informational messages go to stderr
- **Composable**: Tools pipe together naturally

### 2. Predictable Behavior

- Tools fail fast with clear error messages
- No silent failures or data loss
- Existing files are never overwritten without explicit confirmation
- Exit codes: 0 for success, non-zero for failure

### 3. Unix Philosophy

- Do one thing well
- Work together with other tools
- Handle text streams (filenames) as a universal interface

## Tools

### ppdf-split

Split a PDF into individual pages.

**Usage:**
```bash
ppdf-split -o <pattern> <input.pdf>
```

**Examples:**
```bash
# Split into page-001.pdf, page-002.pdf, ...
ppdf-split -o page-%03d.pdf document.pdf

# Capture list of created files
files=$(ppdf-split -o p%d.pdf input.pdf)

# Pipe to further processing
ppdf-split -o page-%03d.pdf doc.pdf | while read f; do
    echo "Processing $f"
done
```

**Output pattern:**
- `%d` - Page number (1, 2, 3, ...)
- `%03d` - Zero-padded page number (001, 002, 003, ...)
- `%05d` - Five-digit padding (00001, 00002, ...)

### ppdf-unite

Merge multiple PDFs into one.

**Usage:**
```bash
ppdf-unite -o <output.pdf> <input1.pdf> [input2.pdf ...]
ppdf-unite -o <output.pdf> -i <file-list.txt>
ppdf-unite -o <output.pdf>  # reads from stdin
```

**Examples:**
```bash
# Merge specific files
ppdf-unite -o combined.pdf file1.pdf file2.pdf file3.pdf

# Merge from file list
ppdf-unite -o combined.pdf -i files.txt

# Merge from stdin
ls *.pdf | ppdf-unite -o combined.pdf

# Round-trip test
ppdf-split -o page-%03d.pdf original.pdf | ppdf-unite -o reconstructed.pdf
```

## Workflows

### Split, Filter, Recombine

```bash
# Split document into pages
ppdf-split -o page-%03d.pdf document.pdf > all-pages.txt

# Remove unwanted pages
grep -v -E '(page-005|page-010|page-015)' all-pages.txt > keep-pages.txt

# Recombine
ppdf-unite -o filtered.pdf -i keep-pages.txt
```

### Categorize and Separate

```bash
# Split into individual pages
ppdf-split -o page-%03d.pdf document.pdf

# Manually categorize (or use automated tools)
mkdir overview account investments transactions

# Move pages to categories
mv page-001.pdf page-003.pdf overview/
mv page-010.pdf page-015.pdf account/
# ... etc

# Create separate PDFs for each category
ppdf-unite -o overview.pdf overview/*.pdf
ppdf-unite -o account.pdf account/*.pdf
ppdf-unite -o investments.pdf investments/*.pdf
ppdf-unite -o transactions.pdf transactions/*.pdf
```

### Parallel Processing

```bash
# Split document
ppdf-split -o page-%03d.pdf document.pdf | \
    # Process each page in parallel
    xargs -P 4 -I {} sh -c 'process-page {} > {}.txt'
```

## Dependencies

### Required

- **qpdf** - PDF manipulation library
  ```bash
  sudo apt-get install qpdf
  ```

- **poppler-utils** - PDF utilities (pdfinfo, pdfunite)
  ```bash
  sudo apt-get install poppler-utils
  ```

- **Perl 5** - With common::sense module
  ```bash
  sudo apt-get install perl libcommon-sense-perl
  ```

### Optional

- **tesseract-ocr** - For OCR processing (used by other disco tools)
  ```bash
  sudo apt-get install tesseract-ocr
  ```

## Installation

```bash
# Clone or download the tools
git clone https://github.com/yourusername/proc-pdf.git
cd proc-pdf

# Add to PATH
export PATH="$PWD/bin:$PATH"

# Or install system-wide
sudo cp bin/ppdf-* /usr/local/bin/
```

## Integration with disco

The proc-pdf toolkit is part of the larger **disco** eDiscovery suite. While these tools are useful standalone, they're designed to integrate with:

- **disco-import**: Convert PDFs to searchable database
- **disco-export**: Generate reports and reconstructed documents
- **disco-analyze**: Extract tables, detect document types, find patterns

## Future Tools

Planned additions to the toolkit:

- **ppdf-extract**: Extract specific pages or page ranges
- **ppdf-rotate**: Rotate pages
- **ppdf-info**: Display PDF metadata and structure
- **ppdf-compress**: Optimize PDF size
- **ppdf-decrypt**: Remove passwords
- **ppdf-watermark**: Add watermarks or stamps

## Contributing

This is open source software built for the public good. Contributions welcome!

**Areas where we need help:**
- Additional PDF manipulation tools
- Better error messages and user feedback
- Performance optimization
- Documentation and tutorials
- Testing on different platforms

## License

[To be determined - likely GPL or MIT]

## Support

**Free (Community):**
- GitHub issues and discussions
- Documentation and tutorials

**Paid (Paralegal Service):**
- We train paralegals to use these tools
- Available for hire at affordable hourly rates
- Same tools, professional assistance
- No vendor lock-in

Contact: [to be added]

## Philosophy: Why This Matters

The legal system has become inaccessible to ordinary people. Document discovery alone can cost tens of thousands of dollars, pricing out anyone who can't afford BigLaw rates.

**This has to change.**

These tools are our contribution to leveling the playing field. They won't solve every problem, but they make it possible for:

- Pro se defendants to process their own documents
- Small law firms to compete with large ones
- Legal aid organizations to serve more clients
- Anyone to verify and audit their legal documents

**Access to justice is not a luxury. It's a right.**

---

*Part of the disco eDiscovery suite - Because everyone deserves discovery.*
