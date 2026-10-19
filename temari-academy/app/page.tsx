import Link from "next/link";
import { COMPANY, STATS, TESTIMONIALS, WHY } from "../lib/content";
import { prisma } from "../lib/prisma";
import { etb, LEVEL_LABELS } from "../lib/clientConstants";
import AnimatedStats from "../components/AnimatedStats";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const courses = await prisma.course.findMany({
    where: { published: true },
    orderBy: { createdAt: "desc" },
    take: 6,
    include: { lessons: true }
  });

  return (
    <>
      <section className="hero">
        <div className="wrap">
          <span className="hero-kicker">temari@addis:~$ learn, build, get hired</span>
          <h1>
            <span className="grad-text">Skills that pay</span> - taught by people
            who use them in Addis, not in a studio in California.
          </h1>
          <p className="sub">
            {COMPANY.name} is an Ethiopian learning platform with 40+ courses in
            technology, business, design and language. Every track ends with a real
            project and an instructor review, because employers hire portfolios,
            not certificates.
          </p>
          <div className="hero-actions">
            <Link className="btn" href="/signup">Start learning free</Link>
            <Link className="btn ghost" href="/courses">Browse courses</Link>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <AnimatedStats stats={STATS} />
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <div className="page-head">
            <div>
              <h2>Newest courses</h2>
              <p className="sub">Fresh from instructors, updated for the tools companies use today.</p>
            </div>
            <Link href="/courses">All courses</Link>
          </div>
          <div className="grid-3">
            {courses.map((c) => (
              <Link key={c.id} href={"/courses/" + c.slug} className="card course-card" style={{ textDecoration: "none" }}>
                <div className="course-top">
                  <h3>{c.title}</h3>
                  <span className={"price" + (c.priceCents === 0 ? " free" : "")}>
                    {c.priceCents === 0 ? "Free" : etb(c.priceCents)}
                  </span>
                </div>
                <p>{c.subtitle}</p>
                <div className="course-meta">
                  <span className="chip neutral">{c.category}</span>
                  <span className="chip vivid">{LEVEL_LABELS[c.level] || c.level}</span>
                  <span className="sub">{c.lessons.length} lessons - {c.hours}h</span>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <div className="page-head">
            <h2>Why students finish here</h2>
          </div>
          <div className="grid-4">
            {WHY.map((w, i) => (
              <div className="card" key={w.title}>
                <div className="num-badge">0{i + 1}</div>
                <h3>{w.title}</h3>
                <p>{w.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <div className="page-head">
            <h2>Graduates, in their words</h2>
          </div>
          <div className="grid-3">
            {TESTIMONIALS.map((t) => (
              <div className="card" key={t.name}>
                <p style={{ color: "var(--ink)", fontSize: 14.5 }}>&quot;{t.quote}&quot;</p>
                <p style={{ marginBottom: 0 }}><strong>{t.name}</strong><br /><span className="sub">{t.role}</span></p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <div className="panel">
            <div className="panel-body">
              <h2>Your next job starts with your next skill.</h2>
              <p className="sub">
                Create a free account, enroll in a free course today, and upgrade only
                if the track is worth it to you. No credit card to start.
              </p>
              <Link className="btn" href="/signup">Create free account</Link>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
