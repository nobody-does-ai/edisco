# Repository Guidelines

## Project Structure & Module Organization
This repository is a command-line PDF processing toolkit built around Perl scripts.

- `bin/`: executable workflows and utilities (`ppdf-split`, `ppdf-unite`, `ppdf-pages`, `ocr-pdf`, `tsv-*`).
- `lib/`: shared Perl modules (`Tsv*.pm`, `Visit.pm`, config helpers).
- `sql/`: schema and query files used by TSV/DB pipelines.
- `doc/`: user-facing docs (`README.md`, `QUICKREF.md`).
- `html/`, `pdf/`, `png/`, `tsv/`, `log/`: generated outputs/artifacts.

Keep reusable logic in `lib/` and keep `bin/` scripts thin wrappers.

## Build, Test, and Development Commands
- `bin/activate`: open a shell with local `bin/` and `lib/` prepended to `PATH`/`PERL5LIB`.
- `bin/ppdf-split -o page-%03d.pdf input.pdf`: split a PDF into per-page files.
- `bin/ppdf-unite -o merged.pdf page-*.pdf`: merge PDFs in order.
- `bin/tsv-pg`: run TSV/Postgres pipeline steps (project-specific data flow).
- `bin/regen-db`: rebuild local Postgres schema and regenerate `sql/tsv.sql`.

Dependencies are external CLI tools (`qpdf`, `pdfunite`/`pdfinfo` from poppler, Perl 5 modules).

## Coding Style & Naming Conventions
- Language: Perl (scripts/modules commonly use `common::sense` and `autodie`).
- Indentation/style marker is consistent: `# vim: ts=2 sw=2 ft=perl` (2-space indent).
- File naming:
  - executables: kebab-case in `bin/` (for example `ppdf-unite`);
  - modules: `CamelCase.pm` in `lib/`.
- Follow CLI conventions already documented: `-o` for outputs, machine-readable stdout, diagnostics on stderr.

## Testing Guidelines
There is no formal `prove`/`Test::More` suite in this repo yet. Use command-level smoke tests:

1. Split a known sample PDF.
2. Recombine with `ppdf-unite`.
3. Validate output pages with `pdfinfo`.

When changing SQL/data flows, run `bin/regen-db` and verify generated SQL diffs are intentional.

## Commit & Pull Request Guidelines
Recent history includes short operational commits (`pre-regen`, `post-regen`, `x`). Prefer clearer messages going forward:

- Use imperative, scoped subjects (`ppdf-unite: reject missing inputs`).
- Keep schema regen commits separate from logic changes when possible.
- PRs should include: purpose, impacted commands/modules, test/smoke steps run, and sample input/output snippets when behavior changes.
