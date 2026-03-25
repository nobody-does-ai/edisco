import { NextResponse } from "next/server";
import { writeFile, mkdir } from "fs/promises";
import { dirname } from "path";

export async function POST(request: Request) {
  try {
    const { path, content } = await request.json();

    if (!path) {
      return NextResponse.json({ error: "path is required" }, { status: 400 });
    }

    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, content, "utf-8");

    return NextResponse.json({ ok: true, path, bytes_written: Buffer.byteLength(content, "utf-8") });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
