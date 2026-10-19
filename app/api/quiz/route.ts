import { NextResponse } from "next/server";
import { prisma } from "../../../lib/prisma";
import { getAuth } from "../../../lib/auth";
import { QUIZ_PASS_FRACTION } from "../../../lib/clientConstants";

type QuizQuestion = { q: string; options: string[]; answer: number };

export async function POST(req: Request) {
  const user = await getAuth();
  if (!user) {
    return NextResponse.json({ error: "Sign in to take the quiz." }, { status: 401 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  const slug = String(body.slug || "").trim();
  const answers = Array.isArray(body.answers) ? body.answers.map(Number) : null;
  if (!slug || !answers) {
    return NextResponse.json({ error: "Course and answers are required." }, { status: 400 });
  }

  const course = await prisma.course.findUnique({
    where: { slug },
    include: { enrollments: { where: { userId: user.id } } }
  });
  if (!course || course.enrollments.length === 0) {
    return NextResponse.json({ error: "Enroll in the course first." }, { status: 403 });
  }

  let questions: QuizQuestion[] = [];
  try {
    questions = JSON.parse(course.quizJson);
  } catch {
    questions = [];
  }
  if (questions.length === 0) {
    return NextResponse.json({ error: "This course has no quiz yet." }, { status: 400 });
  }

  let score = 0;
  const correct: boolean[] = questions.map((q, i) => {
    const ok = answers[i] === q.answer;
    if (ok) score++;
    return ok;
  });
  const total = questions.length;
  const passed = score / total >= QUIZ_PASS_FRACTION;

  try {
    await prisma.quizResult.create({
      data: { userId: user.id, courseId: course.id, score, total, passed }
    });
    return NextResponse.json({ ok: true, score, total, passed, correct });
  } catch {
    return NextResponse.json({ error: "Could not save your quiz result." }, { status: 500 });
  }
}
