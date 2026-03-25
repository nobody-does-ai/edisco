import { NextResponse } from "next/server";
import { readFile } from "fs/promises";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const path = searchParams.get("path");
  const offset = parseInt(searchParams.get("offset") || "0", 10);
  const limit = parseInt(searchParams.get("limit") || "2000", 10);

  if (!path) {
    return NextResponse.json({ error: "path is required" }, { status: 400 });
  }

  try {
    const content = await readFile(path, "utf-8");
    const lines = content.split("\n");
    const sliced = lines.slice(offset, offset + limit);
    return NextResponse.json({
      path,
      total_lines: lines.length,
      offset,
      lines_returned: sliced.length,
      content: sliced.join("\n"),
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
