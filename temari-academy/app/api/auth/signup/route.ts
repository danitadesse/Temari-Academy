import { NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import { hashPassword, createSessionToken, sessionCookieName, sessionMaxAge } from "../../../../lib/auth";

export async function POST(req: Request) {
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  // Honeypot: silently accept bot signups without creating anything.
  if (typeof body.website === "string" && body.website.length > 0) {
    return NextResponse.json({ ok: true, next: "/dashboard" });
  }

  const name = String(body.name || "").trim();
  const email = String(body.email || "").trim().toLowerCase();
  const password = String(body.password || "");

  if (!name || name.length > 120) {
    return NextResponse.json({ error: "Enter your name (max 120 characters)." }, { status: 400 });
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 200) {
    return NextResponse.json({ error: "Enter a valid email address." }, { status: 400 });
  }
  if (password.length < 8) {
    return NextResponse.json({ error: "Password must be at least 8 characters." }, { status: 400 });
  }

  try {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return NextResponse.json({ error: "An account with this email already exists. Try signing in." }, { status: 409 });
    }
    const user = await prisma.user.create({
      data: { name, email, passwordHash: hashPassword(password), role: "student" }
    });
    const res = NextResponse.json({ ok: true, next: "/dashboard" });
    res.cookies.set(sessionCookieName, createSessionToken(user.id), {
      httpOnly: true,
      sameSite: "lax",
      path: "/",
      maxAge: sessionMaxAge
    });
    return res;
  } catch {
    return NextResponse.json(
      { error: "Could not create your account. If this is a fresh install, run: npx prisma db push && npm run db:seed" },
      { status: 500 }
    );
  }
}
