import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "../../../lib/prisma";
import { getAuth } from "../../../lib/auth";
import { etb, LEVEL_LABELS } from "../../../lib/clientConstants";
import EnrollButton from "../../../components/EnrollButton";

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const course = await prisma.course.findUnique({ where: { slug: params.slug } });
  return { title: course ? course.title + " - Temari Academy" : "Course - Temari Academy" };
}

export default async function CourseDetailPage({ params }: { params: { slug: string } }) {
  const course = await prisma.course.findUnique({
    where: { slug: params.slug },
    include: { lessons: { orderBy: { idx: "asc" } } }
  });
  if (!course || !course.published) notFound();

  const user = await getAuth();
  const enrolled = user
    ? !!(await prisma.enrollment.findUnique({
        where: { userId_courseId: { userId: user.id, courseId: course.id } }
      }))
    : false;

  const totalMinutes = course.lessons.reduce((s, l) => s + l.minutes, 0);

  return (
    <div className="wrap section">
      <div className="page-head">
        <div>
          <span className="chip neutral">{course.category}</span>{" "}
          <span className="chip vivid">{LEVEL_LABELS[course.level] || course.level}</span>
          <h1 style={{ marginTop: 10 }}>{course.title}</h1>
          <p className="sub">{course.subtitle}</p>
        </div>
        <div className="panel" style={{ minWidth: 280, marginBottom: 0, position: "sticky", top: 84, alignSelf: "start" }}>
          <div className="panel-body">
            <div style={{ fontSize: 26, fontWeight: 800 }} className="grad-text">
              {course.priceCents === 0 ? "Free" : etb(course.priceCents)}
            </div>
            <p className="sub" style={{ marginBottom: 12 }}>
              {course.lessons.length} lessons - about {course.hours} hours of material
              ({totalMinutes} minutes of video and exercises).
            </p>
            {enrolled ? (
              <Link className="btn wide" href={"/dashboard/" + course.slug}>Continue learning</Link>
            ) : (
              <EnrollButton slug={course.slug} signedIn={!!user} priceFree={course.priceCents === 0} />
            )}
            <p className="sub" style={{ marginTop: 12, marginBottom: 0, fontSize: 12.5 }}>
              Lifetime access. Certificate on completion.
            </p>
          </div>
        </div>
      </div>

      <div className="grid-2">
        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-head"><h2>What this course covers</h2></div>
          <div className="panel-body"><p>{course.description}</p></div>
        </div>
        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-head"><h2>Lessons</h2></div>
          <ul className="lesson-list">
            {course.lessons.map((l) => (
              <li key={l.id}>
                <div className="lesson-item" style={{ cursor: "default" }}>
                  <span className="l-title">
                    <span className="l-idx">{String(l.idx).padStart(2, "0")}</span>
                    {l.title}
                  </span>
                  <span className="l-min">{l.minutes} min</span>
                </div>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}
