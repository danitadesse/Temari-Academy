import { NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import { getAuth } from "../../../../lib/auth";

export async function POST(req: Request) {
  const user = await getAuth();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Admin access required." }, { status: 403 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  if (String(body.action || "") !== "delete") {
    return NextResponse.json({ error: "Unknown action." }, { status: 400 });
  }

  const id = Number(body.id);
  if (!Number.isInteger(id) || id <= 0) {
    return NextResponse.json({ error: "Invalid message id." }, { status: 400 });
  }

  try {
    await prisma.contactMessage.delete({ where: { id } });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "Could not delete the message." }, { status: 500 });
  }
}
