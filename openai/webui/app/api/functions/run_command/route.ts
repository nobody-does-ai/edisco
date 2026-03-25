import { NextResponse } from "next/server";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

export async function POST(request: Request) {
  try {
    const { command, cwd } = await request.json();

    if (!command) {
      return NextResponse.json({ error: "command is required" }, { status: 400 });
    }

    const { stdout, stderr } = await execAsync(command, {
      cwd: cwd || process.env.HOME,
      maxBuffer: 1024 * 1024 * 10,
      timeout: 120000,
    });

    return NextResponse.json({ stdout, stderr });
  } catch (error: any) {
    return NextResponse.json({
      stdout: error.stdout || "",
      stderr: error.stderr || "",
      exit_code: error.code,
      error: error.message,
    });
  }
}
