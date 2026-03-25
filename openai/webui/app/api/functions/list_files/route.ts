import { NextResponse } from "next/server";
import { readdir, stat } from "fs/promises";
import { join } from "path";
import { glob } from "fs/promises";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const path = searchParams.get("path");

  if (!path) {
    return NextResponse.json({ error: "path is required" }, { status: 400 });
  }

  try {
    // If it looks like a glob pattern, use glob
    if (path.includes("*") || path.includes("?") || path.includes("{")) {
      const files: string[] = [];
      for await (const entry of glob(path)) {
        files.push(entry.toString());
      }
      return NextResponse.json({ pattern: path, files });
    }

    // Otherwise, list directory
    const entries = await readdir(path, { withFileTypes: true });
    const files = entries.map((e) => ({
      name: e.name,
      path: join(path, e.name),
      type: e.isDirectory() ? "directory" : "file",
    }));
    return NextResponse.json({ path, entries: files });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
