// Functions mapping to tool calls
// Define one function per tool call - each tool call should have a matching function
// Parameters for a tool call are passed as an object to the corresponding function

export const read_file = async ({
  path,
  offset,
  limit,
}: {
  path: string;
  offset?: number;
  limit?: number;
}) => {
  const params = new URLSearchParams({ path });
  if (offset !== undefined) params.set("offset", String(offset));
  if (limit !== undefined) params.set("limit", String(limit));
  return fetch(`/api/functions/read_file?${params}`).then((res) => res.json());
};

export const write_file = async ({
  path,
  content,
}: {
  path: string;
  content: string;
}) => {
  return fetch("/api/functions/write_file", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ path, content }),
  }).then((res) => res.json());
};

export const edit_file = async ({
  path,
  old_string,
  new_string,
}: {
  path: string;
  old_string: string;
  new_string: string;
}) => {
  return fetch("/api/functions/edit_file", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ path, old_string, new_string }),
  }).then((res) => res.json());
};

export const list_files = async ({ path }: { path: string }) => {
  return fetch(`/api/functions/list_files?path=${encodeURIComponent(path)}`).then((res) => res.json());
};

export const search_files = async ({
  pattern,
  path,
  glob,
}: {
  pattern: string;
  path: string;
  glob?: string;
}) => {
  const params = new URLSearchParams({ pattern, path });
  if (glob) params.set("glob", glob);
  return fetch(`/api/functions/search_files?${params}`).then((res) => res.json());
};

export const run_command = async ({
  command,
  cwd,
}: {
  command: string;
  cwd?: string;
}) => {
  return fetch("/api/functions/run_command", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ command, cwd }),
  }).then((res) => res.json());
};

export const functionsMap = {
  read_file,
  write_file,
  edit_file,
  list_files,
  search_files,
  run_command,
};
