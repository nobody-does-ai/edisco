# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

proc-pdf is a command-line PDF processing toolkit for the **disco** eDiscovery suite. It converts PDFs to images via OCR, extracts text into TSV format, and processes structured data (investments, transactions) from legal/financial documents. Part of a larger monorepo at `edisco/`.

## Environment Setup

```bash
bin/activate    # Opens bash shell with bin/ in PATH and lib/ in PERL5LIB
```

## Key Commands

```bash
bin/ppdf-tsv                  # PDF → PNG → TSV pipeline (OCR via Tesseract)
bin/tsv-json                  # Extract structured JSON from TSV data
bin/tsv-html                  # Generate HTML reports from TSV
bin/tsv-rows                  # Display TSV rows grouped by lines
bin/tsv-prune                 # Remove TSV files with unwanted sections
bin/regen-db                  # Rebuild Postgres schema, regenerate sql/tsv.sql
```

## Testing

No formal test suite. Smoke-test by:
1. Split a sample PDF, recombine, validate with `pdfinfo`
2. After SQL/data flow changes, run `bin/regen-db` and verify SQL diffs are intentional

## Architecture

**Data pipeline:**
```
src/*.pdf → ppdf-tsv → png/ (images) + tsv/ (OCR text)
                                            ↓
                                    PostgreSQL (tsv table)
                                            ↓
                            ┌───────────────┼──────────────┐
                        tsv-html        tsv-json        tsv-rows
                        → html/         → JSON stdout   → grouped text
```

**Database layers** (in `sql/`):
- `tsv.sql` — raw OCR data (one row per word, with page coordinates and confidence)
- `xlate.sql` — semantic translation layer (physical OCR coords → logical business concepts)
- `bix-views.sql` — business data views (investments, transactions)

**Shared Perl modules** live in `lib/` (symlink to `../lib`):
- `TsvFile`/`TsvDoc` — load and parse TSV OCR data
- `TsvUtil` — text grouping utilities (vert_sort, group_find, words_merge)
- `TsvRect`/`TsvWord`/`TsvGroup` — data structure classes
- `Nobody::Util` — common utilities (path handling, logging)
- `Nobody::PP` — pretty-printing

## Coding Conventions

- **Language:** Perl 5 with `common::sense` and `autodie`
- **Indent:** 2 spaces (`# vim: ts=2 sw=2 ft=perl`)
- **Executables:** kebab-case in `bin/` (e.g., `ppdf-unite`)
- **Modules:** CamelCase.pm in `lib/` (e.g., `TsvFile.pm`)
- **CLI pattern:** `-o` for output, stdout for machine-readable results, stderr for diagnostics
- Keep reusable logic in `lib/`; keep `bin/` scripts as thin wrappers

## Dependencies

- **qpdf**, **poppler-utils** (pdfinfo, pdfunite), **tesseract-ocr**, **PostgreSQL 15**
- Perl modules: `common::sense`, `autodie`, `JSON::PP`

## Commit Style

Use imperative, scoped subjects (e.g., `ppdf-unite: reject missing inputs`). Keep schema regen commits separate from logic changes.
