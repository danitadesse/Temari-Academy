import { NextResponse } from "next/server";
import { prisma } from "../../../lib/prisma";
import { getAuth } from "../../../lib/auth";
import { TOPICS } from "../../../lib/clientConstants";

// Lightweight in-memory rate limiter: 5 submissions per 15 minutes per IP.
const WINDOW_MS = 15 * 60 * 1000;
const MAX_PER_WINDOW = 5;
const hits = new Map<string, number[]>();

function limited(ip: string): boolean {
  const now = Date.now();
  const recent = (hits.get(ip) || []).filter((t) => now - t < WINDOW_MS);
  if (recent.length >= MAX_PER_WINDOW) {
    hits.set(ip, recent);
    return true;
  }
  recent.push(now);
  hits.set(ip, recent);
  return false;
}

export async function POST(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0].trim() || "local";
  if (limited(ip)) {
    return NextResponse.json(
      { error: "Too many messages from this address. Please try again in a few minutes." },
      { status: 429 }
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  // Honeypot: real users never fill this. Pretend success, store nothing.
  if (typeof body.website === "string" && body.website.length > 0) {
    return NextResponse.json({ ok: true });
  }

  const name = String(body.name || "").trim();
  const email = String(body.email || "").trim();
  const topic = String(body.topic || "").trim();
  const text = String(body.body || "").trim();

  if (!name || name.length > 120) {
    return NextResponse.json({ error: "Name is required (max 120 characters)." }, { status: 400 });
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 200) {
    return NextResponse.json({ error: "Enter a valid email address." }, { status: 400 });
  }
  if (!TOPICS.includes(topic as (typeof TOPICS)[number])) {
    return NextResponse.json({ error: "Select a valid topic." }, { status: 400 });
  }
  if (!text || text.length > 4000) {
    return NextResponse.json({ error: "Message is required (max 4000 characters)." }, { status: 400 });
  }

  const user = await getAuth();

  try {
    await prisma.contactMessage.create({
      data: { name, email, topic, body: text, userId: user?.id ?? null }
    });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json(
      { error: "Could not save your message. If this is a fresh install, run: npx prisma db push" },
      { status: 500 }
    );
  }
}
