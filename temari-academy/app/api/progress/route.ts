import { NextResponse } from "next/server";
import { prisma } from "../../../lib/prisma";
import { getAuth } from "../../../lib/auth";

// Marks a single lesson complete for the signed-in student.
export async function POST(req: Request) {
  const user = await getAuth();
  if (!user) {
    return NextResponse.json({ error: "Sign in to save progress." }, { status: 401 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  const lessonId = Number(body.lessonId);
  if (!Number.isInteger(lessonId) || lessonId <= 0) {
    return NextResponse.json({ error: "Invalid lesson." }, { status: 400 });
  }

  // The student must be enrolled in the course that owns this lesson.
  const lesson = await prisma.lesson.findUnique({
    where: { id: lessonId },
    include: { course: { include: { enrollments: { where: { userId: user.id } } } } }
  });
  if (!lesson || lesson.course.enrollments.length === 0) {
    return NextResponse.json({ error: "Enroll in the course first." }, { status: 403 });
  }

  try {
    await prisma.lessonProgress.upsert({
      where: { userId_lessonId: { userId: user.id, lessonId } },
      update: {},
      create: { userId: user.id, lessonId }
    });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "Could not save progress." }, { status: 500 });
  }
}
