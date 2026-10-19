import Link from "next/link";
import { prisma } from "../../lib/prisma";
import { etb } from "../../lib/clientConstants";

export default async function AdminOverviewPage() {
  const [users, courses, enrollments, quizResults, messages, lessonProgress, unreadMessages] = await Promise.all([
    prisma.user.count(),
    prisma.course.count(),
    prisma.enrollment.count(),
    prisma.quizResult.count(),
    prisma.contactMessage.count(),
    prisma.lessonProgress.count(),
    prisma.contactMessage.count()
  ]);

  const topCourses = await prisma.course.findMany({
    include: { enrollments: true },
    take: 8
  });
  topCourses.sort((a, b) => b.enrollments.length - a.enrollments.length);
  const maxEnrolled = Math.max(1, ...topCourses.map((c) => c.enrollments.length));

  const recentSignups = await prisma.user.findMany({
    orderBy: { createdAt: "desc" },
    take: 8,
    include: { enrollments: true }
  });

  const catalog = await prisma.course.findMany({ include: { enrollments: true } });
  const paidCents = catalog.reduce(
    (s, c) => s + (c.priceCents > 0 ? c.priceCents * c.enrollments.length : 0),
    0
  );

  const stats = [
    { l: "Registered users", n: String(users) },
    { l: "Courses in catalog", n: String(courses) },
    { l: "Total enrollments", n: String(enrollments) },
    { l: "Paid enrollment value", n: etb(paidCents) },
    { l: "Quiz attempts", n: String(quizResults) },
    { l: "Lessons completed", n: String(lessonProgress) }
  ];

  return (
    <>
      <div className="grid-3" style={{ marginBottom: 22 }}>
        {stats.map((s) => (
          <div className="stat" key={s.l}>
            <div className="l">{s.l}</div>
            <div className="n">{s.n}</div>
          </div>
        ))}
      </div>

      <div className="grid-2">
        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-head">
            <h2>Enrollments by course</h2>
            <Link href="/admin/courses">Manage catalog</Link>
          </div>
          <div className="panel-body">
            {topCourses.length === 0 ? (
              <div className="empty">No courses yet.</div>
            ) : (
              topCourses.map((c) => (
                <div className="bar-row" key={c.id}>
                  <span className="bar-label" title={c.title}>{c.title}</span>
                  <div className="bar-track">
                    <div
                      className="bar-fill"
                      style={{ width: Math.max(3, Math.round((c.enrollments.length / maxEnrolled) * 100)) + "%" }}
                    ></div>
                  </div>
                  <span className="bar-value">{c.enrollments.length}</span>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-head">
            <h2>Newest members</h2>
            <Link href="/admin/messages">Inbox ({unreadMessages})</Link>
          </div>
          <div className="table-scroll">
            <table className="ac-table">
              <thead>
                <tr><th>Name</th><th>Joined</th><th className="num">Courses</th></tr>
              </thead>
              <tbody>
                {recentSignups.map((u) => (
                  <tr key={u.id}>
                    <td>{u.name}{u.role === "admin" && <span className="chip neutral" style={{ marginLeft: 8 }}>admin</span>}</td>
                    <td className="sub">{u.createdAt.toISOString().slice(0, 10)}</td>
                    <td className="num">{u.enrollments.length}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </>
  );
}
