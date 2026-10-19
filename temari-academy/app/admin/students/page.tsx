import { prisma } from "../../../lib/prisma";
import { pct } from "../../../lib/clientConstants";

export default async function AdminStudentsPage() {
  const students = await prisma.user.findMany({
    where: { role: "student" },
    orderBy: { createdAt: "desc" },
    include: {
      enrollments: {
        include: {
          course: { include: { lessons: { include: { progress: true } } } }
        }
      },
      progress: true,
      quizResults: true
    }
  });

  return (
    <div className="panel" style={{ marginBottom: 0 }}>
      <div className="panel-head">
        <h2>Students ({students.length})</h2>
        <span className="chip neutral">Sorted by newest</span>
      </div>
      <div className="table-scroll">
        <table className="ac-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Joined</th>
              <th className="num">Courses</th>
              <th className="num">Lessons done</th>
              <th className="num">Avg progress</th>
              <th className="num">Quizzes</th>
            </tr>
          </thead>
          <tbody>
            {students.length === 0 ? (
              <tr><td colSpan={7}><div className="empty">No students yet.</div></td></tr>
            ) : (
              students.map((s) => {
                const totalLessons = s.enrollments.reduce(
                  (sum, e) => sum + e.course.lessons.length, 0
                );
                const avg = totalLessons > 0
                  ? pct(s.progress.length, totalLessons)
                  : 0;
                return (
                  <tr key={s.id}>
                    <td><strong>{s.name}</strong></td>
                    <td className="mono sub">{s.email}</td>
                    <td className="sub">{s.createdAt.toISOString().slice(0, 10)}</td>
                    <td className="num">{s.enrollments.length}</td>
                    <td className="num">{s.progress.length}</td>
                    <td className="num">{avg}%</td>
                    <td className="num">{s.quizResults.length}</td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
