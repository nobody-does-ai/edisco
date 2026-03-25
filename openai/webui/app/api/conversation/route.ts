import pool from "@/lib/db";
import { NextResponse } from "next/server";

// GET — load all messages for the default session
export async function GET() {
  try {
    const { rows } = await pool.query(
      `SELECT role, content, metadata, created_at
       FROM messages
       WHERE session_id = 1
       ORDER BY created_at ASC`
    );
    return NextResponse.json({ messages: rows });
  } catch (error) {
    console.error("Error loading conversation:", error);
    return NextResponse.json({ error: "Failed to load conversation" }, { status: 500 });
  }
}

// POST — append messages to the default session
export async function POST(request: Request) {
  try {
    const { messages } = await request.json();

    for (const msg of messages) {
      await pool.query(
        `INSERT INTO messages (session_id, role, content, metadata)
         VALUES (1, $1, $2, $3)`,
        [msg.role, JSON.stringify(msg.content), msg.metadata ? JSON.stringify(msg.metadata) : null]
      );
    }

    // Update session timestamp
    await pool.query(`UPDATE sessions SET updated_at = NOW() WHERE id = 1`);

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Error saving messages:", error);
    return NextResponse.json({ error: "Failed to save messages" }, { status: 500 });
  }
}

// DELETE — clear the conversation (start fresh)
export async function DELETE() {
  try {
    await pool.query(`DELETE FROM messages WHERE session_id = 1`);
    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Error clearing conversation:", error);
    return NextResponse.json({ error: "Failed to clear conversation" }, { status: 500 });
  }
}
