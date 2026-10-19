import { redirect } from "next/navigation";
import { prisma } from "../../lib/prisma";
import { getAuth } from "../../lib/auth";
import { etb, pct, LEVEL_LABELS } from "../../lib/clientConstants";
import Link from "next/link";

export default async function DashboardPage() {
  const user = await getAuth();
  if (!user) redirect("/login?next=/dashboard");
  if (user.role === "admin") redirect("/admin");

  const enrollments = await prisma.enrollment.findMany({
    where: { userId: user.id },
    orderBy: { createdAt: "desc" },
    include: {
      course: {
        include: {
          lessons: { include: { progress: { where: { userId: user.id } } } }
        }
      }
    }
  });

  const quizzes = await prisma.quizResult.findMany({
    where: { userId: user.id },
    orderBy: { createdAt: "desc" }
  });
  const bestQuiz = new Map<number, number>();
  for (const q of quizzes) {
    if (!bestQuiz.has(q.courseId) || q.score > bestQuiz.get(q.courseId)!) {
      bestQuiz.set(q.courseId, q.score);
    }
  }

  const totalLessons = enrollments.reduce((s, e) => s + e.course.lessons.length, 0);
  const doneLessons = enrollments.reduce(
    (s, e) => s + e.course.lessons.filter((l) => l.progress.length > 0).length,
    0
  );

  return (
    <div className="wrap section">
      <div className="page-head">
        <div>
          <h1>My learning</h1>
          <p className="sub">
            {enrollments.length} enrolled course{enrollments.length === 1 ? "" : "s"} -
            {doneLessons} of {totalLessons} lessons complete
            {totalLessons > 0 ? " (" + pct(doneLessons, totalLessons) + "%)" : ""}.
          </p>
        </div>
        <Link className="btn" href="/courses">Find a course</Link>
      </div>

      {enrollments.length === 0 ? (
        <div className="panel">
          <div className="empty">
            You have not enrolled yet. <Link href="/courses">Browse the catalog</Link> and start with a free course.
          </div>
        </div>
      ) : (
        <div className="grid-2">
          {enrollments.map((e) => {
            const done = e.course.lessons.filter((l) => l.progress.length > 0).length;
            const total = e.course.lessons.length;
            const percent = pct(done, total);
            const quizScore = bestQuiz.get(e.courseId);
            const certified = percent === 100 && quizScore !== undefined &&
              quizScore / total >= 0.7;
            return (
              <div className="panel" key={e.id} style={{ marginBottom: 0 }}>
                <div className="panel-head">
                  <h2>{e.course.title}</h2>
                  <span className="chip neutral">{LEVEL_LABELS[e.course.level] || e.course.level}</span>
                </div>
                <div className="panel-body">
                  <p className="sub" style={{ marginBottom: 6 }}>
                    {done} of {total} lessons - {percent}%{" "}
                    {quizScore !== undefined && "(best quiz: " + quizScore + "/" + total + ")"}
                  </p>
                  <div className="meter"><div style={{ width: percent + "%" }}></div></div>
                  <div style={{ display: "flex", gap: 10, marginTop: 14, alignItems: "center", flexWrap: "wrap" }}>
                    <Link className="btn sm" href={"/dashboard/" + e.course.slug}>
                      {done === 0 ? "Start course" : "Continue"}
                    </Link>
                    {certified && <span className="chip ok">Certificate earned</span>}
                  </div>
                  <p className="sub" style={{ marginTop: 10, marginBottom: 0, fontSize: 12.5 }}>
                    Enrolled {e.createdAt.toISOString().slice(0, 10)} -
                    {e.course.priceCents === 0 ? " free track" : " " + etb(e.course.priceCents)}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
