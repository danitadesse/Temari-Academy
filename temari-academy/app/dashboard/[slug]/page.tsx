import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { prisma } from "../../../lib/prisma";
import { getAuth } from "../../../lib/auth";
import { pct } from "../../../lib/clientConstants";
import LearnClient from "./LearnClient";

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const course = await prisma.course.findUnique({ where: { slug: params.slug } });
  return { title: (course ? course.title : "Learn") + " - Temari Academy" };
}

export default async function LearnPage({ params }: { params: { slug: string } }) {
  const user = await getAuth();
  if (!user) redirect("/login?next=/dashboard/" + params.slug);

  const course = await prisma.course.findUnique({
    where: { slug: params.slug },
    include: {
      lessons: {
        orderBy: { idx: "asc" },
        include: { progress: { where: { userId: user.id } } }
      }
    }
  });
  if (!course) notFound();

  const enrollment = await prisma.enrollment.findUnique({
    where: { userId_courseId: { userId: user.id, courseId: course.id } }
  });
  if (!enrollment) redirect("/courses/" + params.slug);

  const bestQuiz = await prisma.quizResult.findFirst({
    where: { userId: user.id, courseId: course.id },
    orderBy: { score: "desc" }
  });

  // Never send answers to the client - grading happens server-side.
  let questions: { q: string; options: string[] }[] = [];
  try {
    const raw = JSON.parse(course.quizJson) as { q: string; options: string[]; answer: number }[];
    questions = raw.map((q) => ({ q: q.q, options: q.options }));
  } catch {
    questions = [];
  }

  const lessons = course.lessons.map((l) => ({
    id: l.id,
    idx: l.idx,
    title: l.title,
    minutes: l.minutes,
    done: l.progress.length > 0
  }));

  return (
    <div className="wrap section">
      <div className="page-head">
        <div>
          <h1>{course.title}</h1>
          <p className="sub">
            {lessons.filter((l) => l.done).length} of {lessons.length} lessons complete
            {" "}({pct(lessons.filter((l) => l.done).length, lessons.length)}%)
          </p>
        </div>
      </div>
      <LearnClient
        slug={course.slug}
        courseTitle={course.title}
        lessons={lessons}
        questions={questions}
        bestQuizScore={bestQuiz ? bestQuiz.score : null}
        quizTotal={questions.length}
        enrollmentId={enrollment.id}
      />
    </div>
  );
}
