import { NextResponse } from "next/server";
import { execFile } from "child_process";
import { promisify } from "util";

const execFileAsync = promisify(execFile);

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const pattern = searchParams.get("pattern");
  const path = searchParams.get("path") || ".";
  const fileGlob = searchParams.get("glob");

  if (!pattern) {
    return NextResponse.json({ error: "pattern is required" }, { status: 400 });
  }

  try {
    const args = ["-rn", "--max-count=100"];
    if (fileGlob) {
      args.push("--include", fileGlob);
    }
    args.push(pattern, path);

    const { stdout, stderr } = await execFileAsync("grep", args, {
      maxBuffer: 1024 * 1024,
      timeout: 10000,
    });

    const matches = stdout
      .trim()
      .split("\n")
      .filter(Boolean)
      .map((line) => {
        const match = line.match(/^(.+?):(\d+):(.*)$/);
        if (match) {
          return { file: match[1], line: parseInt(match[2], 10), text: match[3] };
        }
        return { text: line };
      });

    return NextResponse.json({ pattern, path, matches });
  } catch (error: any) {
    // grep returns exit code 1 for no matches
    if (error.code === 1) {
      return NextResponse.json({ pattern, path, matches: [] });
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
