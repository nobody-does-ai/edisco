CREATE SCHEMA IF NOT EXISTS xlate;

CREATE TABLE xlate.body (
  body integer GENERATED ALWAYS AS IDENTITY,
  doc integer NOT NULL,
  page_num integer,
  ord integer NOT NULL DEFAULT 1,
  left integer,
  top integer,
  width integer,
  height integer,
  note text,
  PRIMARY KEY (body),
  FOREIGN KEY (doc) REFERENCES public.doc(doc)
);

CREATE TABLE xlate.tab (
  tab integer GENERATED ALWAYS AS IDENTITY,
  doc integer NOT NULL,
  body integer,
  page_num integer,
  tab_type text NOT NULL DEFAULT 'table',
  ord integer NOT NULL DEFAULT 1,
  left integer,
  top integer,
  width integer,
  height integer,
  row_base integer NOT NULL DEFAULT 0,
  col_base integer NOT NULL DEFAULT 0,
  header_row integer,
  rule_json jsonb,
  PRIMARY KEY (tab),
  FOREIGN KEY (doc) REFERENCES public.doc(doc),
  FOREIGN KEY (body) REFERENCES xlate.body(body),
  CHECK (tab_type in ('table','prose','other'))
);

CREATE TABLE xlate.row (
  row integer GENERATED ALWAYS AS IDENTITY,
  doc integer NOT NULL,
  tab integer NOT NULL,
  row_num integer NOT NULL,
  row_kind text NOT NULL DEFAULT 'data',
  PRIMARY KEY (row),
  FOREIGN KEY (doc) REFERENCES public.doc(doc),
  FOREIGN KEY (tab) REFERENCES xlate.tab(tab),
  UNIQUE (doc, row_num)
);

CREATE TABLE xlate.col (
  col integer GENERATED ALWAYS AS IDENTITY,
  doc integer NOT NULL,
  tab integer NOT NULL,
  col_num integer NOT NULL,
  col_kind text NOT NULL DEFAULT 'data',
  label text,
  PRIMARY KEY (col),
  FOREIGN KEY (doc) REFERENCES public.doc(doc),
  FOREIGN KEY (tab) REFERENCES xlate.tab(tab),
  UNIQUE (doc, col_num)
);

CREATE TABLE xlate.word (
  word integer GENERATED ALWAYS AS IDENTITY,
  tsv bigint NOT NULL,
  doc integer NOT NULL,
  row integer NOT NULL,
  col integer NOT NULL,
  text_raw text NOT NULL,
  text_norm text,
  conf double precision,
  reject integer NOT NULL DEFAULT 0,
  parser_version text NOT NULL DEFAULT 'v1',
  PRIMARY KEY (word),
  FOREIGN KEY (tsv) REFERENCES public.tsv(tsv),
  FOREIGN KEY (doc) REFERENCES public.doc(doc),
  FOREIGN KEY (row) REFERENCES xlate.row(row),
  FOREIGN KEY (col) REFERENCES xlate.col(col)
);

CREATE INDEX xlate_tab_doc_idx ON xlate.tab(doc, ord);
CREATE INDEX xlate_tab_body_idx ON xlate.tab(body, ord);
CREATE INDEX xlate_body_doc_idx ON xlate.body(doc, ord);
CREATE INDEX xlate_row_doc_idx ON xlate.row(doc, row_num);
CREATE INDEX xlate_col_doc_idx ON xlate.col(doc, col_num);
CREATE INDEX xlate_word_doc_idx ON xlate.word(doc);
CREATE INDEX xlate_word_row_col_idx ON xlate.word(row, col);
CREATE INDEX xlate_word_tsv_idx ON xlate.word(tsv);
