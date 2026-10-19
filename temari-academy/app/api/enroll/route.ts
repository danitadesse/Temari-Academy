import { NextResponse } from "next/server";
import { prisma } from "../../../lib/prisma";
import { getAuth } from "../../../lib/auth";

export async function POST(req: Request) {
  const user = await getAuth();
  if (!user) {
    return NextResponse.json({ error: "Sign in to enroll." }, { status: 401 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  const slug = String(body.slug || "").trim();
  if (!slug) {
    return NextResponse.json({ error: "Course is required." }, { status: 400 });
  }

  const course = await prisma.course.findUnique({ where: { slug } });
  if (!course || !course.published) {
    return NextResponse.json({ error: "Course not found." }, { status: 404 });
  }

  const existing = await prisma.enrollment.findUnique({
    where: { userId_courseId: { userId: user.id, courseId: course.id } }
  });
  if (existing) {
    return NextResponse.json({ ok: true, already: true });
  }

  try {
    await prisma.enrollment.create({ data: { userId: user.id, courseId: course.id } });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json(
      { error: "Enrollment failed. If this is a fresh install, run: npx prisma db push" },
      { status: 500 }
    );
  }
}
