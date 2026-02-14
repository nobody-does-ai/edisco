# Deferred Work

This file tracks intentionally deferred ideas so we can stay focused on the immediate case workflow.

## Current Priority

- Import statements reliably.
- Extract business-relevant data with minimal manual cleanup.
- Keep iteration fast (`dropdb`/rebuild is cheap).

## Deferred (Intentional)

1. Multi-engine OCR reconciliation ("binocular vision")
- Run two OCR engines on the same pages (for example Tesseract + another engine).
- Compare at semantic level (`doc,row,col`), not raw layout text.
- Flag disagreements for review or rules.

2. Full view migration after schema settles
- Existing views still reflect older `tsv` shape.
- Rebuild views only after `ocr/xlate/biz` table design is stable.

3. DSL-driven extraction rules
- Define document format rules that map physical regions to logical targets.
- Use this to identify table/body areas and destination business fields.
- Treat this as the long-term "missing semantic layer" in OCR import.

4. `xlate.body` population automation
- `xlate.body` exists to model non-tabular document flow and table placement.
- Auto-detection/population is deferred until table extraction is stable.

## Long-Term Vision

Serious semantic import for legal/financial documents:
- Preserve OCR facts (`ocr`).
- Translate via explicit mapping (`xlate`).
- Publish clean consumer data (`biz`) without exposing OCR internals.
