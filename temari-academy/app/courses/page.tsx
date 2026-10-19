import type { Metadata } from "next";
import Link from "next/link";
import { prisma } from "../../lib/prisma";
import { etb, LEVEL_LABELS, CATEGORIES } from "../../lib/clientConstants";

export const metadata: Metadata = {
  title: "Courses - Temari Academy",
  description: "Technology, business, design and language courses taught by Ethiopian professionals."
};

export const dynamic = "force-dynamic";

export default async function CoursesPage({
  searchParams
}: {
  searchParams: { q?: string; cat?: string };
}) {
  const q = (searchParams.q || "").trim();
  const cat = (searchParams.cat || "").trim();

  const where: Record<string, unknown> = { published: true };
  if (q) {
    where.OR = [
      { title: { contains: q } },
      { subtitle: { contains: q } },
      { category: { contains: q } }
    ];
  }
  if (cat) where.category = cat;

  const courses = await prisma.course.findMany({
    where,
    orderBy: [{ category: "asc" }, { createdAt: "desc" }],
    include: { lessons: true }
  });

  const qs = (extra: Record<string, string>) => {
    const params = new URLSearchParams();
    const merged = { q, cat, ...extra };
    for (const [k, v] of Object.entries(merged)) {
      if (v) params.set(k, v);
    }
    const s = params.toString();
    return s ? "/courses?" + s : "/courses";
  };

  return (
    <div className="wrap section">
      <div className="page-head">
        <div>
          <h1>Courses</h1>
          <p className="sub">{courses.length} course{courses.length === 1 ? "" : "s"}{q ? " matching \"" + q + "\"" : ""}{cat ? " in " + cat : ""}.</p>
        </div>
      </div>

      <div className="panel" style={{ marginBottom: 22 }}>
        <div className="panel-body" style={{ display: "flex", gap: 12, flexWrap: "wrap", alignItems: "center" }}>
          <form action="/courses" method="get" style={{ display: "flex", gap: 10, flex: "1 1 320px" }}>
            <input name="q" defaultValue={q} placeholder="Search by title, subtitle or category" />
            {cat && <input type="hidden" name="cat" value={cat} />}
            <button className="btn" type="submit">Search</button>
          </form>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            <Link className={"btn sm " + (cat ? "ghost" : "")} href={qs({ cat: "" })}>All</Link>
            {CATEGORIES.map((c) => (
              <Link key={c} className={"btn sm " + (cat === c ? "" : "ghost")} href={qs({ cat: c })}>
                {c}
              </Link>
            ))}
          </div>
        </div>
      </div>

      {courses.length === 0 ? (
        <div className="panel"><div className="empty">No courses match. Try a different search or category.</div></div>
      ) : (
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
      )}
    </div>
  );
}
