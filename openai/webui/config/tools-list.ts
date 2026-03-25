// List of tools available to the assistant
// No need to include the top-level wrapper object as it is added in lib/tools/tools.ts
// More information on function calling: https://platform.openai.com/docs/guides/function-calling

export const toolsList = [
  {
    name: "read_file",
    description: "Read the contents of a file. Returns the file content as text. Use offset and limit for large files.",
    required: ["path"],
    parameters: {
      path: {
        type: "string",
        description: "Absolute path to the file to read",
      },
      offset: {
        type: "number",
        description: "Line number to start reading from (0-based). Optional, defaults to 0.",
      },
      limit: {
        type: "number",
        description: "Maximum number of lines to read. Optional, defaults to 2000.",
      },
    },
  },
  {
    name: "write_file",
    description: "Write content to a file. Creates the file if it doesn't exist, overwrites if it does.",
    required: ["path", "content"],
    parameters: {
      path: {
        type: "string",
        description: "Absolute path to the file to write",
      },
      content: {
        type: "string",
        description: "Content to write to the file",
      },
    },
  },
  {
    name: "edit_file",
    description: "Edit a file by replacing an exact string match with new text. The old_string must match exactly once in the file.",
    required: ["path", "old_string", "new_string"],
    parameters: {
      path: {
        type: "string",
        description: "Absolute path to the file to edit",
      },
      old_string: {
        type: "string",
        description: "The exact text to find and replace",
      },
      new_string: {
        type: "string",
        description: "The replacement text",
      },
    },
  },
  {
    name: "list_files",
    description: "List files and directories at a given path. Supports glob patterns.",
    required: ["path"],
    parameters: {
      path: {
        type: "string",
        description: "Directory path or glob pattern (e.g., '/home/user/src' or '/home/user/src/**/*.ts')",
      },
    },
  },
  {
    name: "search_files",
    description: "Search file contents using a regular expression pattern, like grep. Returns matching lines with file paths and line numbers.",
    required: ["pattern", "path"],
    parameters: {
      pattern: {
        type: "string",
        description: "Regular expression pattern to search for",
      },
      path: {
        type: "string",
        description: "Directory to search in",
      },
      glob: {
        type: "string",
        description: "File glob to filter (e.g., '*.ts', '*.py'). Optional.",
      },
    },
  },
  {
    name: "run_command",
    description: "Execute a shell command and return its stdout and stderr. Use for git, npm, build tools, etc.",
    required: ["command"],
    parameters: {
      command: {
        type: "string",
        description: "The shell command to execute",
      },
      cwd: {
        type: "string",
        description: "Working directory for the command. Optional.",
      },
    },
  },
];
