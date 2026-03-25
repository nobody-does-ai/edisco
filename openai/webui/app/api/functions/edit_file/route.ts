import { NextResponse } from "next/server";
import { readFile, writeFile } from "fs/promises";

export async function POST(request: Request) {
  try {
    const { path, old_string, new_string } = await request.json();

    if (!path || old_string === undefined || new_string === undefined) {
      return NextResponse.json({ error: "path, old_string, and new_string are required" }, { status: 400 });
    }

    const content = await readFile(path, "utf-8");
    const occurrences = content.split(old_string).length - 1;

    if (occurrences === 0) {
      return NextResponse.json({ error: "old_string not found in file" }, { status: 400 });
    }
    if (occurrences > 1) {
      return NextResponse.json({ error: `old_string found ${occurrences} times, must be unique` }, { status: 400 });
    }

    const updated = content.replace(old_string, new_string);
    await writeFile(path, updated, "utf-8");

    return NextResponse.json({ ok: true, path });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
