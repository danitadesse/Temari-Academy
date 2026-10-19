#!/usr/bin/env bash
# ==============================================================
# Temari Academy - full project setup script (v1)
# Fictional Ethiopian online learning platform. Full student
# portal with accounts, progress, quizzes and certificates,
# plus an admin console. Run from the PARENT folder that should
# contain temari-academy/, or inside an empty folder.
# ==============================================================
set -e
mkdir -p temari-academy
cd temari-academy
mkdir -p "$(dirname ".env.example")"
cat > ".env.example" <<'TA_EOF'
# SQLite database file
DATABASE_URL="file:./dev.db"
TA_EOF
echo "wrote .env.example"
mkdir -p "$(dirname ".gitignore")"
cat > ".gitignore" <<'TA_EOF'
node_modules
.next
out
dev.db
dev.db-journal
.env
.env.local
*.tsbuildinfo
next-env.d.ts
TA_EOF
echo "wrote .gitignore"
mkdir -p "$(dirname "app/about/page.tsx")"
cat > "app/about/page.tsx" <<'TA_EOF'
import type { Metadata } from "next";
import Link from "next/link";
import { COMPANY, TEAM } from "../../lib/content";

export const metadata: Metadata = {
  title: "About - Temari Academy",
  description: "The team behind Temari Academy, Ethiopia's fictional home of practical learning."
};

export default function AboutPage() {
  return (
    <div className="wrap section">
      <div className="page-head">
        <div>
          <h1>About {COMPANY.name}</h1>
          <p className="sub">
            Temari means student. We are a small team in {COMPANY.city} convinced
            that the gap between Ethiopian classrooms and Ethiopian job posts is a
            curriculum problem, not a talent problem. So we built the curriculum.
          </p>
        </div>
        <Link className="btn" href="/courses">See the courses</Link>
      </div>

      <div className="grid-3">
        {TEAM.map((m) => (
          <div className="card" key={m.name}>
            <div className="num-badge">{m.initials}</div>
            <h3>{m.name}</h3>
            <p className="sub">{m.role}</p>
            <p>{m.bio}</p>
          </div>
        ))}
      </div>

      <div className="panel" style={{ marginTop: 18 }}>
        <div className="panel-head"><h2>How a track works</h2></div>
        <div className="panel-body">
          <div className="grid-4">
            <div className="card" style={{ boxShadow: "none" }}>
              <div className="num-badge">01</div>
              <h3>Enroll</h3>
              <p>Create a free account and start any free course immediately. Paid tracks unlock with one payment.</p>
            </div>
            <div className="card" style={{ boxShadow: "none" }}>
              <div className="num-badge">02</div>
              <h3>Learn</h3>
              <p>Work through lessons at your pace. Progress is saved per lesson, so a 15-minute commute counts.</p>
            </div>
            <div className="card" style={{ boxShadow: "none" }}>
              <div className="num-badge">03</div>
              <h3>Prove it</h3>
              <p>Pass the final quiz and finish every lesson to unlock your certificate with a verifiable code.</p>
            </div>
            <div className="card" style={{ boxShadow: "none" }}>
              <div className="num-badge">04</div>
              <h3>Ship it</h3>
              <p>Graduates leave with a project built, reviewed and ready to show in an interview.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
TA_EOF
echo "wrote app/about/page.tsx"
mkdir -p "$(dirname "app/admin/courses/CourseEditor.tsx")"
cat > "app/admin/courses/CourseEditor.tsx" <<'TA_EOF'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { LEVELS, CATEGORIES, LEVEL_LABELS } from "../../../lib/clientConstants";

type CourseRow = {
  id: number;
  slug: string;
  title: string;
  subtitle: string;
  category: string;
  level: string;
  priceBirr: number;
  hours: number;
  published: boolean;
  lessonCount: number;
  enrollmentCount: number;
};

type Draft = {
  title: string;
  slug: string;
  subtitle: string;
  category: string;
  level: string;
  price: string; // free text, normalized on blur (lesson from Kaffa v5)
  hours: string;
};

const emptyDraft: Draft = {
  title: "",
  slug: "",
  subtitle: "",
  category: CATEGORIES[0],
  level: LEVELS[0],
  price: "0",
  hours: "6"
};

export default function CourseEditor({ courses }: { courses: CourseRow[] }) {
  const router = useRouter();
  const [draft, setDraft] = useState<Draft>(emptyDraft);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");
  const [rowErrors, setRowErrors] = useState<Record<number, string>>({});

  function set<K extends keyof Draft>(key: K, value: string) {
    setDraft((d) => ({ ...d, [key]: value }));
  }

  // Keep the slug in sync while the user has not typed one manually.
  function onTitle(title: string) {
    setDraft((d) => {
      const autoSlug =
        !d.slug || d.slug === slugify(d.title)
          ? slugify(title)
          : d.slug;
      return { ...d, title, slug: autoSlug };
    });
  }

  function slugify(s: string): string {
    return s.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
  }

  function normalizeNumber(key: "price" | "hours") {
    setDraft((d) => {
      const n = Math.max(0, Math.floor(Number(d[key]) || 0));
      return { ...d, [key]: String(n) };
    });
  }

  async function call(action: string, payload: Record<string, unknown>, rowId?: number) {
    setBusy(true);
    setError("");
    setNotice("");
    setRowErrors({});
    try {
      const res = await fetch("/api/admin/courses", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action, ...payload })
      });
      const body = await res.json();
      if (!res.ok) {
        if (rowId) setRowErrors({ [rowId]: body.error || "Action failed." });
        else setError(body.error || "Action failed.");
      } else {
        setNotice(body.message || "Saved.");
        setDraft(emptyDraft);
        router.refresh();
      }
    } catch {
      setError("Could not reach the server. Is the dev server running?");
    } finally {
      setBusy(false);
    }
  }

  async function createCourse(e: React.FormEvent) {
    e.preventDefault();
    if (!draft.title.trim()) { setError("Title is required."); return; }
    if (!draft.slug) { setError("Slug is required."); return; }
    await call("create", {
      title: draft.title.trim(),
      slug: draft.slug,
      subtitle: draft.subtitle.trim(),
      category: draft.category,
      level: draft.level,
      priceBirr: Math.max(0, Math.floor(Number(draft.price) || 0)),
      hours: Math.max(0, Math.floor(Number(draft.hours) || 0))
    });
  }

  return (
    <>
      {notice && <div className="notice ok">{notice}</div>}
      {error && <div className="notice bad">{error}</div>}

      <div className="panel">
        <div className="panel-head"><h2>Create a course</h2></div>
        <div className="panel-body">
          <form className="form-stack" onSubmit={createCourse}>
            <div className="grid-2" style={{ gap: 14 }}>
              <div>
                <label htmlFor="ce-title">Title</label>
                <input id="ce-title" value={draft.title} onChange={(e) => onTitle(e.target.value)} maxLength={120} />
              </div>
              <div>
                <label htmlFor="ce-slug">Slug (URL)</label>
                <input id="ce-slug" className="mono" value={draft.slug} onChange={(e) => set("slug", slugify(e.target.value))} maxLength={80} />
              </div>
            </div>
            <div>
              <label htmlFor="ce-sub">Subtitle</label>
              <input id="ce-sub" className="wide-field" value={draft.subtitle} onChange={(e) => set("subtitle", e.target.value)} maxLength={200} />
            </div>
            <div className="grid-2" style={{ gap: 14 }}>
              <div>
                <label htmlFor="ce-cat">Category</label>
                <select id="ce-cat" value={draft.category} onChange={(e) => set("category", e.target.value)}>
                  {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div>
                <label htmlFor="ce-level">Level</label>
                <select id="ce-level" value={draft.level} onChange={(e) => set("level", e.target.value)}>
                  {LEVELS.map((l) => <option key={l} value={l}>{LEVEL_LABELS[l]}</option>)}
                </select>
              </div>
            </div>
            <div className="grid-2" style={{ gap: 14 }}>
              <div>
                <label htmlFor="ce-price">Price (ETB, 0 = free)</label>
                <input id="ce-price" className="mono" inputMode="numeric" value={draft.price} onChange={(e) => set("price", e.target.value.replace(/[^0-9]/g, ""))} onBlur={() => normalizeNumber("price")} />
              </div>
              <div>
                <label htmlFor="ce-hours">Hours of material</label>
                <input id="ce-hours" className="mono" inputMode="numeric" value={draft.hours} onChange={(e) => set("hours", e.target.value.replace(/[^0-9]/g, ""))} onBlur={() => normalizeNumber("hours")} />
              </div>
            </div>
            <div>
              <button className="btn" type="submit" disabled={busy}>
                {busy ? "Saving..." : "Create course"}
              </button>
              <span className="sub" style={{ marginLeft: 10 }}>
                New courses get no lessons or quiz until an instructor adds them - they stay draft-quality until then.
              </span>
            </div>
          </form>
        </div>
      </div>

      <div className="panel" style={{ marginBottom: 0 }}>
        <div className="panel-head"><h2>Catalog ({courses.length})</h2></div>
        <div className="table-scroll">
          <table className="ac-table">
            <thead>
              <tr>
                <th>Course</th>
                <th>Category</th>
                <th>Level</th>
                <th className="num">Price</th>
                <th className="num">Lessons</th>
                <th className="num">Enrolled</th>
                <th>Status</th>
                <th className="num">Actions</th>
              </tr>
            </thead>
            <tbody>
              {courses.map((c) => (
                <tr key={c.id}>
                  <td>
                    <strong>{c.title}</strong>
                    <div className="sub mono" style={{ fontSize: 12 }}>{c.slug}</div>
                    {rowErrors[c.id] && <div className="error-text">{rowErrors[c.id]}</div>}
                  </td>
                  <td>{c.category}</td>
                  <td>{LEVEL_LABELS[c.level] || c.level}</td>
                  <td className="num">{c.priceBirr === 0 ? "Free" : "ETB " + c.priceBirr.toLocaleString("en-US")}</td>
                  <td className="num">{c.lessonCount}</td>
                  <td className="num">{c.enrollmentCount}</td>
                  <td>
                    <span className={"chip " + (c.published ? "ok" : "warn")}>
                      {c.published ? "Published" : "Hidden"}
                    </span>
                  </td>
                  <td className="num">
                    <div style={{ display: "flex", gap: 6, justifyContent: "flex-end", flexWrap: "wrap" }}>
                      <button
                        className="btn ghost sm"
                        type="button"
                        disabled={busy}
                        onClick={() => call("toggle", { id: c.id })}
                      >
                        {c.published ? "Hide" : "Publish"}
                      </button>
                      <button
                        className="btn ghost sm"
                        type="button"
                        disabled={busy}
                        onClick={() => {
                          if (confirm("Delete \"" + c.title + "\"? This cannot be undone.")) {
                            call("delete", { id: c.id }, c.id);
                          }
                        }}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
TA_EOF
echo "wrote app/admin/courses/CourseEditor.tsx"
mkdir -p "$(dirname "app/admin/courses/page.tsx")"
cat > "app/admin/courses/page.tsx" <<'TA_EOF'
import { prisma } from "../../../lib/prisma";
import CourseEditor from "./CourseEditor";

export default async function AdminCoursesPage() {
  const courses = await prisma.course.findMany({
    orderBy: { createdAt: "desc" },
    include: { lessons: true, enrollments: true }
  });

  return (
    <CourseEditor
      courses={courses.map((c) => ({
        id: c.id,
        slug: c.slug,
        title: c.title,
        subtitle: c.subtitle,
        category: c.category,
        level: c.level,
        priceBirr: Math.floor(c.priceCents / 100),
        hours: c.hours,
        published: c.published,
        lessonCount: c.lessons.length,
        enrollmentCount: c.enrollments.length
      }))}
    />
  );
}
TA_EOF
echo "wrote app/admin/courses/page.tsx"
mkdir -p "$(dirname "app/admin/layout.tsx")"
cat > "app/admin/layout.tsx" <<'TA_EOF'
import { redirect } from "next/navigation";
import Link from "next/link";
import { getAuth } from "../../lib/auth";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const user = await getAuth();
  if (!user) redirect("/login?next=/admin");
  if (user.role !== "admin") redirect("/dashboard");

  return (
    <div className="wrap section">
      <div className="page-head">
        <div>
          <h1><span className="grad-text">Admin</span> console</h1>
          <p className="sub">Signed in as {user.name} ({user.email}).</p>
        </div>
        <div style={{ display: "flex", gap: 10 }}>
          <Link className="btn ghost sm" href="/admin">Overview</Link>
          <Link className="btn ghost sm" href="/admin/courses">Courses</Link>
          <Link className="btn ghost sm" href="/admin/students">Students</Link>
          <Link className="btn ghost sm" href="/admin/messages">Messages</Link>
        </div>
      </div>
      {children}
    </div>
  );
}
TA_EOF
echo "wrote app/admin/layout.tsx"
mkdir -p "$(dirname "app/admin/messages/MessageActions.tsx")"
cat > "app/admin/messages/MessageActions.tsx" <<'TA_EOF'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

type Msg = {
  id: number;
  name: string;
  email: string;
  topic: string;
  body: string;
  createdAt: string;
};

export default function MessageActions({ messages }: { messages: Msg[] }) {
  const router = useRouter();
  const [q, setQ] = useState("");
  const [busy, setBusy] = useState<number | null>(null);
  const [error, setError] = useState("");

  const filtered = messages.filter((m) =>
    !q ||
    m.name.toLowerCase().includes(q.toLowerCase()) ||
    m.email.toLowerCase().includes(q.toLowerCase()) ||
    m.body.toLowerCase().includes(q.toLowerCase())
  );

  async function remove(id: number) {
    if (!confirm("Delete this message?")) return;
    setBusy(id);
    setError("");
    try {
      const res = await fetch("/api/admin/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "delete", id })
      });
      const body = await res.json();
      if (!res.ok) {
        setError(body.error || "Delete failed.");
      } else {
        router.refresh();
      }
    } catch {
      setError("Could not reach the server.");
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="panel" style={{ marginBottom: 0 }}>
      <div className="panel-head">
        <h2>Inbox ({messages.length})</h2>
        <input
          className="mono"
          style={{ maxWidth: 260 }}
          placeholder="Search name, email or text"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>
      {error && <div className="notice bad" style={{ margin: "14px 18px 0" }}>{error}</div>}
      {filtered.length === 0 ? (
        <div className="empty">No messages{q ? " match your search" : " yet"}.</div>
      ) : (
        filtered.map((m) => (
          <div key={m.id} style={{ padding: "14px 18px", borderBottom: "1px solid var(--hairline)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>
              <div>
                <strong>{m.name}</strong> <span className="sub mono" style={{ fontSize: 12.5 }}>{m.email}</span>
              </div>
              <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
                <span className="chip neutral">{m.topic}</span>
                <span className="sub">{m.createdAt}</span>
                <button className="btn ghost sm" type="button" disabled={busy === m.id} onClick={() => remove(m.id)}>
                  {busy === m.id ? "..." : "Delete"}
                </button>
              </div>
            </div>
            <p style={{ marginTop: 8, marginBottom: 0, fontSize: 14 }}>{m.body}</p>
          </div>
        ))
      )}
    </div>
  );
}
TA_EOF
echo "wrote app/admin/messages/MessageActions.tsx"
mkdir -p "$(dirname "app/admin/messages/page.tsx")"
cat > "app/admin/messages/page.tsx" <<'TA_EOF'
import MessageActions from "./MessageActions";
import { prisma } from "../../../lib/prisma";

export default async function AdminMessagesPage() {
  const messages = await prisma.contactMessage.findMany({
    orderBy: { createdAt: "desc" },
    take: 100
  });

  return (
    <MessageActions
      messages={messages.map((m) => ({
        id: m.id,
        name: m.name,
        email: m.email,
        topic: m.topic,
        body: m.body,
        createdAt: m.createdAt.toISOString().slice(0, 10)
      }))}
    />
  );
}
TA_EOF
echo "wrote app/admin/messages/page.tsx"
mkdir -p "$(dirname "app/admin/page.tsx")"
cat > "app/admin/page.tsx" <<'TA_EOF'
import Link from "next/link";
import { prisma } from "../../lib/prisma";
import { etb } from "../../lib/clientConstants";

export default async function AdminOverviewPage() {
  const [users, courses, enrollments, quizResults, messages, lessonProgress] = await Promise.all([
    prisma.user.count(),
    prisma.course.count(),
    prisma.enrollment.count(),
    prisma.quizResult.count(),
    prisma.contactMessage.count(),
    prisma.lessonProgress.count()
  ]);

  const topCourses = await prisma.course.findMany({
    include: { enrollments: true },
    orderBy: { enrollments: { _count: "desc" } },
    take: 5
  });

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
      <div className="grid-3" style={{ marginBottom: 18 }}>
        {stats.map((s) => (
          <div className="stat" key={s.l}>
            <div className="l">{s.l}</div>
            <div className="n">{s.n}</div>
          </div>
        ))}
      </div>

      <div className="grid-2">
        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-head"><h2>Most popular courses</h2></div>
          <div className="table-scroll">
            <table className="ac-table">
              <thead>
                <tr><th>Course</th><th className="num">Enrolled</th></tr>
              </thead>
              <tbody>
                {topCourses.map((c) => (
                  <tr key={c.id}>
                    <td><Link href={"/courses/" + c.slug}>{c.title}</Link></td>
                    <td className="num">{c.enrollments.length}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-head"><h2>Newest members</h2><span className="chip neutral">{messages} unread messages</span></div>
          <div className="table-scroll">
            <table className="ac-table">
              <thead>
                <tr><th>Name</th><th>Joined</th><th className="num">Courses</th></tr>
              </thead>
              <tbody>
                {recentSignups.map((u) => (
                  <tr key={u.id}>
                    <td>{u.name}{u.role === "admin" ? " (admin)" : ""}</td>
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
TA_EOF
echo "wrote app/admin/page.tsx"
mkdir -p "$(dirname "app/admin/students/page.tsx")"
cat > "app/admin/students/page.tsx" <<'TA_EOF'
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
TA_EOF
echo "wrote app/admin/students/page.tsx"
mkdir -p "$(dirname "app/api/admin/courses/route.ts")"
cat > "app/api/admin/courses/route.ts" <<'TA_EOF'
import { NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import { getAuth } from "../../../../lib/auth";
import { LEVELS, CATEGORIES } from "../../../../lib/clientConstants";

export async function POST(req: Request) {
  const user = await getAuth();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Admin access required." }, { status: 403 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  const action = String(body.action || "");

  if (action === "create") {
    const title = String(body.title || "").trim();
    const slug = String(body.slug || "").trim();
    const subtitle = String(body.subtitle || "").trim();
    const category = String(body.category || "");
    const level = String(body.level || "");
    const priceBirr = Math.max(0, Math.floor(Number(body.priceBirr) || 0));
    const hours = Math.max(0, Math.floor(Number(body.hours) || 0));

    if (!title || title.length > 120) {
      return NextResponse.json({ error: "Title is required (max 120 characters)." }, { status: 400 });
    }
    if (!/^[a-z0-9-]+$/.test(slug) || slug.length > 80) {
      return NextResponse.json({ error: "Slug must be lowercase letters, digits and dashes." }, { status: 400 });
    }
    if (!CATEGORIES.includes(category as (typeof CATEGORIES)[number])) {
      return NextResponse.json({ error: "Invalid category." }, { status: 400 });
    }
    if (!LEVELS.includes(level as (typeof LEVELS)[number])) {
      return NextResponse.json({ error: "Invalid level." }, { status: 400 });
    }

    try {
      const dup = await prisma.course.findUnique({ where: { slug } });
      if (dup) {
        return NextResponse.json({ error: "A course with this slug already exists." }, { status: 409 });
      }
      await prisma.course.create({
        data: {
          title, slug, subtitle, category, level,
          description: subtitle || "Course description coming soon.",
          priceCents: priceBirr * 100,
          hours,
          published: true,
          quizJson: "[]"
        }
      });
      return NextResponse.json({ ok: true, message: "Course created and published." });
    } catch {
      return NextResponse.json(
        { error: "Could not create the course. If this is a fresh install, run: npx prisma db push" },
        { status: 500 }
      );
    }
  }

  const id = Number(body.id);
  if (!Number.isInteger(id) || id <= 0) {
    return NextResponse.json({ error: "Invalid course id." }, { status: 400 });
  }
  const course = await prisma.course.findUnique({
    where: { id },
    include: { enrollments: true }
  });
  if (!course) {
    return NextResponse.json({ error: "Course not found." }, { status: 404 });
  }

  if (action === "toggle") {
    try {
      await prisma.course.update({ where: { id }, data: { published: !course.published } });
      return NextResponse.json({
        ok: true,
        message: course.published ? "Course hidden from the catalog." : "Course published."
      });
    } catch {
      return NextResponse.json({ error: "Could not update the course." }, { status: 500 });
    }
  }

  if (action === "delete") {
    if (course.enrollments.length > 0) {
      return NextResponse.json(
        { error: "Cannot delete: " + course.enrollments.length + " student(s) are enrolled. Hide it instead." },
        { status: 409 }
      );
    }
    try {
      await prisma.course.delete({ where: { id } });
      return NextResponse.json({ ok: true, message: "Course deleted." });
    } catch {
      return NextResponse.json({ error: "Could not delete the course." }, { status: 500 });
    }
  }

  return NextResponse.json({ error: "Unknown action." }, { status: 400 });
}
TA_EOF
echo "wrote app/api/admin/courses/route.ts"
mkdir -p "$(dirname "app/api/admin/messages/route.ts")"
cat > "app/api/admin/messages/route.ts" <<'TA_EOF'
import { NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import { getAuth } from "../../../../lib/auth";

export async function POST(req: Request) {
  const user = await getAuth();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Admin access required." }, { status: 403 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  if (String(body.action || "") !== "delete") {
    return NextResponse.json({ error: "Unknown action." }, { status: 400 });
  }

  const id = Number(body.id);
  if (!Number.isInteger(id) || id <= 0) {
    return NextResponse.json({ error: "Invalid message id." }, { status: 400 });
  }

  try {
    await prisma.contactMessage.delete({ where: { id } });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "Could not delete the message." }, { status: 500 });
  }
}
TA_EOF
echo "wrote app/api/admin/messages/route.ts"
mkdir -p "$(dirname "app/api/auth/login/route.ts")"
cat > "app/api/auth/login/route.ts" <<'TA_EOF'
import { NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import { verifyPassword, createSessionToken, sessionCookieName, sessionMaxAge } from "../../../../lib/auth";

// Login rate limit: 5 attempts per 15 minutes per email+IP.
const WINDOW_MS = 15 * 60 * 1000;
const MAX_ATTEMPTS = 5;
const attempts = new Map<string, number[]>();

function limited(key: string): boolean {
  const now = Date.now();
  const recent = (attempts.get(key) || []).filter((t) => now - t < WINDOW_MS);
  if (recent.length >= MAX_ATTEMPTS) {
    attempts.set(key, recent);
    return true;
  }
  recent.push(now);
  attempts.set(key, recent);
  return false;
}

export async function POST(req: Request) {
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  const email = String(body.email || "").trim().toLowerCase();
  const password = String(body.password || "");
  const next = String(body.next || "/dashboard");
  const safeNext = next.startsWith("/") && !next.startsWith("//") ? next : "/dashboard";

  if (!email || !password) {
    return NextResponse.json({ error: "Email and password are required." }, { status: 400 });
  }

  const ip = req.headers.get("x-forwarded-for")?.split(",")[0].trim() || "local";
  if (limited(ip + ":" + email)) {
    return NextResponse.json(
      { error: "Too many sign-in attempts. Please wait a few minutes." },
      { status: 429 }
    );
  }

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !verifyPassword(password, user.passwordHash)) {
    return NextResponse.json({ error: "Incorrect email or password." }, { status: 401 });
  }

  const res = NextResponse.json({ ok: true, next: user.role === "admin" ? "/admin" : safeNext });
  res.cookies.set(sessionCookieName, createSessionToken(user.id), {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
    maxAge: sessionMaxAge
  });
  return res;
}
TA_EOF
echo "wrote app/api/auth/login/route.ts"
mkdir -p "$(dirname "app/api/auth/logout/route.ts")"
cat > "app/api/auth/logout/route.ts" <<'TA_EOF'
import { NextResponse } from "next/server";
import { sessionCookieName } from "../../../../lib/auth";

// Handles both fetch() calls and the plain <form method="post"> in the
// header, so it always returns a redirect, never JSON.
export async function POST(req: Request) {
  const url = new URL("/login", req.url);
  const res = NextResponse.redirect(url, 303);
  res.cookies.set(sessionCookieName, "", {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
    maxAge: 0
  });
  return res;
}
TA_EOF
echo "wrote app/api/auth/logout/route.ts"
mkdir -p "$(dirname "app/api/auth/signup/route.ts")"
cat > "app/api/auth/signup/route.ts" <<'TA_EOF'
import { NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import { hashPassword, createSessionToken, sessionCookieName, sessionMaxAge } from "../../../../lib/auth";

export async function POST(req: Request) {
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  // Honeypot: silently accept bot signups without creating anything.
  if (typeof body.website === "string" && body.website.length > 0) {
    return NextResponse.json({ ok: true, next: "/dashboard" });
  }

  const name = String(body.name || "").trim();
  const email = String(body.email || "").trim().toLowerCase();
  const password = String(body.password || "");

  if (!name || name.length > 120) {
    return NextResponse.json({ error: "Enter your name (max 120 characters)." }, { status: 400 });
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 200) {
    return NextResponse.json({ error: "Enter a valid email address." }, { status: 400 });
  }
  if (password.length < 8) {
    return NextResponse.json({ error: "Password must be at least 8 characters." }, { status: 400 });
  }

  try {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return NextResponse.json({ error: "An account with this email already exists. Try signing in." }, { status: 409 });
    }
    const user = await prisma.user.create({
      data: { name, email, passwordHash: hashPassword(password), role: "student" }
    });
    const res = NextResponse.json({ ok: true, next: "/dashboard" });
    res.cookies.set(sessionCookieName, createSessionToken(user.id), {
      httpOnly: true,
      sameSite: "lax",
      path: "/",
      maxAge: sessionMaxAge
    });
    return res;
  } catch {
    return NextResponse.json(
      { error: "Could not create your account. If this is a fresh install, run: npx prisma db push && npm run db:seed" },
      { status: 500 }
    );
  }
}
TA_EOF
echo "wrote app/api/auth/signup/route.ts"
mkdir -p "$(dirname "app/api/contact/route.ts")"
cat > "app/api/contact/route.ts" <<'TA_EOF'
import { NextResponse } from "next/server";
import { prisma } from "../../../lib/prisma";
import { getAuth } from "../../../lib/auth";
import { TOPICS } from "../../../lib/clientConstants";

// Lightweight in-memory rate limiter: 5 submissions per 15 minutes per IP.
const WINDOW_MS = 15 * 60 * 1000;
const MAX_PER_WINDOW = 5;
const hits = new Map<string, number[]>();

function limited(ip: string): boolean {
  const now = Date.now();
  const recent = (hits.get(ip) || []).filter((t) => now - t < WINDOW_MS);
  if (recent.length >= MAX_PER_WINDOW) {
    hits.set(ip, recent);
    return true;
  }
  recent.push(now);
  hits.set(ip, recent);
  return false;
}

export async function POST(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0].trim() || "local";
  if (limited(ip)) {
    return NextResponse.json(
      { error: "Too many messages from this address. Please try again in a few minutes." },
      { status: 429 }
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  // Honeypot: real users never fill this. Pretend success, store nothing.
  if (typeof body.website === "string" && body.website.length > 0) {
    return NextResponse.json({ ok: true });
  }

  const name = String(body.name || "").trim();
  const email = String(body.email || "").trim();
  const topic = String(body.topic || "").trim();
  const text = String(body.body || "").trim();

  if (!name || name.length > 120) {
    return NextResponse.json({ error: "Name is required (max 120 characters)." }, { status: 400 });
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 200) {
    return NextResponse.json({ error: "Enter a valid email address." }, { status: 400 });
  }
  if (!TOPICS.includes(topic as (typeof TOPICS)[number])) {
    return NextResponse.json({ error: "Select a valid topic." }, { status: 400 });
  }
  if (!text || text.length > 4000) {
    return NextResponse.json({ error: "Message is required (max 4000 characters)." }, { status: 400 });
  }

  const user = await getAuth();

  try {
    await prisma.contactMessage.create({
      data: { name, email, topic, body: text, userId: user?.id ?? null }
    });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json(
      { error: "Could not save your message. If this is a fresh install, run: npx prisma db push" },
      { status: 500 }
    );
  }
}
TA_EOF
echo "wrote app/api/contact/route.ts"
mkdir -p "$(dirname "app/api/enroll/route.ts")"
cat > "app/api/enroll/route.ts" <<'TA_EOF'
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
TA_EOF
echo "wrote app/api/enroll/route.ts"
mkdir -p "$(dirname "app/api/progress/route.ts")"
cat > "app/api/progress/route.ts" <<'TA_EOF'
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
TA_EOF
echo "wrote app/api/progress/route.ts"
mkdir -p "$(dirname "app/api/quiz/route.ts")"
cat > "app/api/quiz/route.ts" <<'TA_EOF'
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
TA_EOF
echo "wrote app/api/quiz/route.ts"
mkdir -p "$(dirname "app/contact/ContactForm.tsx")"
cat > "app/contact/ContactForm.tsx" <<'TA_EOF'
"use client";

import { useState } from "react";
import { TOPICS } from "../../lib/clientConstants";

export default function ContactForm({
  signedIn,
  defaultName,
  defaultEmail
}: {
  signedIn: boolean;
  defaultName: string;
  defaultEmail: string;
}) {
  const [form, setForm] = useState({
    name: defaultName,
    email: defaultEmail,
    topic: TOPICS[0],
    body: "",
    website: "" // honeypot
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [ok, setOk] = useState("");

  function set<K extends keyof typeof form>(key: K, value: string) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setOk("");
    if (form.website) return; // honeypot: silently drop bots
    if (!form.name.trim() || !form.email.trim() || !form.body.trim()) {
      setError("Name, email and message are required.");
      return;
    }
    setBusy(true);
    try {
      const res = await fetch("/api/contact", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form)
      });
      const body = await res.json();
      if (!res.ok) {
        setError(body.error || "Something went wrong. Please try again.");
      } else {
        setOk("Message sent. We will reply within one business day.");
        setForm({ name: defaultName, email: defaultEmail, topic: TOPICS[0], body: "", website: "" });
      }
    } catch {
      setError("Could not reach the server. Is the dev server running?");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="panel" style={{ marginBottom: 0 }}>
      <div className="panel-head"><h2>Send a message</h2></div>
      <div className="panel-body">
        {ok && <div className="notice ok">{ok}</div>}
        {error && <div className="notice bad">{error}</div>}
        <form className="form-stack" onSubmit={submit} autoComplete="off">
          <div>
            <label htmlFor="cf-name">Name</label>
            <input id="cf-name" value={form.name} onChange={(e) => set("name", e.target.value)} maxLength={120} />
          </div>
          <div>
            <label htmlFor="cf-email">Email</label>
            <input id="cf-email" className="mono" value={form.email} onChange={(e) => set("email", e.target.value)} maxLength={200} />
          </div>
          <div>
            <label htmlFor="cf-topic">Topic</label>
            <select id="cf-topic" value={form.topic} onChange={(e) => set("topic", e.target.value)}>
              {TOPICS.map((t) => (
                <option key={t} value={t}>{t}</option>
              ))}
            </select>
          </div>
          <div>
            <label htmlFor="cf-body">Message</label>
            <textarea
              id="cf-body"
              className="wide-field"
              value={form.body}
              onChange={(e) => set("body", e.target.value)}
              maxLength={4000}
              placeholder={signedIn ? "Signed in as " + defaultEmail : "How can we help?"}
            />
          </div>
          <div style={{ position: "absolute", left: -9999, top: -9999 }}>
            <label htmlFor="cf-website">Website</label>
            <input id="cf-website" tabIndex={-1} autoComplete="off" value={form.website} onChange={(e) => set("website", e.target.value)} />
          </div>
          <div>
            <button className="btn" type="submit" disabled={busy}>
              {busy ? "Sending..." : "Send message"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
TA_EOF
echo "wrote app/contact/ContactForm.tsx"
mkdir -p "$(dirname "app/contact/page.tsx")"
cat > "app/contact/page.tsx" <<'TA_EOF'
import type { Metadata } from "next";
import ContactForm from "./ContactForm";
import { COMPANY } from "../../lib/content";
import { getAuth } from "../../lib/auth";

export const metadata: Metadata = {
  title: "Contact - Temari Academy",
  description: "Questions about courses, teaching or partnerships at Temari Academy."
};

export default async function ContactPage() {
  const user = await getAuth();
  return (
    <div className="wrap section">
      <div className="page-head">
        <div>
          <h1>Contact</h1>
          <p className="sub">We answer within one business day.</p>
        </div>
      </div>
      <div className="grid-2">
        <ContactForm
          signedIn={!!user}
          defaultName={user?.name ?? ""}
          defaultEmail={user?.email ?? ""}
        />
        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-head"><h2>Other ways to reach us</h2></div>
          <div className="panel-body">
            <p className="sub">General questions</p>
            <p className="mono">{COMPANY.email}</p>
            <p className="sub" style={{ marginTop: 14 }}>Phone (office hours, EAT)</p>
            <p className="mono">{COMPANY.phone}</p>
            <p className="sub" style={{ marginTop: 14 }}>Office</p>
            <p>{COMPANY.city}</p>
            <p className="sub" style={{ marginTop: 14 }}>
              Want to teach with us? Mention your field and a link to your work -
              we review every instructor application ourselves.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
TA_EOF
echo "wrote app/contact/page.tsx"
mkdir -p "$(dirname "app/courses/[slug]/page.tsx")"
cat > "app/courses/[slug]/page.tsx" <<'TA_EOF'
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
        <div className="panel" style={{ minWidth: 280, marginBottom: 0 }}>
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
TA_EOF
echo "wrote app/courses/[slug]/page.tsx"
mkdir -p "$(dirname "app/courses/page.tsx")"
cat > "app/courses/page.tsx" <<'TA_EOF'
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
TA_EOF
echo "wrote app/courses/page.tsx"
mkdir -p "$(dirname "app/dashboard/[slug]/LearnClient.tsx")"
cat > "app/dashboard/[slug]/LearnClient.tsx" <<'TA_EOF'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { pct, QUIZ_PASS_FRACTION } from "../../../lib/clientConstants";

type Lesson = { id: number; idx: number; title: string; minutes: number; done: boolean };
type Question = { q: string; options: string[] };

export default function LearnClient({
  slug,
  courseTitle,
  lessons,
  questions,
  bestQuizScore,
  quizTotal,
  enrollmentId
}: {
  slug: string;
  courseTitle: string;
  lessons: Lesson[];
  questions: Question[];
  bestQuizScore: number | null;
  quizTotal: number;
  enrollmentId: number;
}) {
  const router = useRouter();
  const firstUndone = lessons.find((l) => !l.done) ?? lessons[0];
  const [current, setCurrent] = useState<number>(firstUndone ? firstUndone.id : 0);
  const [state, setState] = useState<Lesson[]>(lessons);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  // quiz state
  const [picks, setPicks] = useState<Record<number, number>>({});
  const [result, setResult] = useState<{ score: number; total: number; passed: boolean; correct: boolean[] } | null>(null);
  const [quizBusy, setQuizBusy] = useState(false);
  const [quizError, setQuizError] = useState("");
  const [savedBest, setSavedBest] = useState<number | null>(bestQuizScore);

  const lesson = state.find((l) => l.id === current) || state[0];
  const doneCount = state.filter((l) => l.done).length;
  const percent = pct(doneCount, state.length);
  const allDone = doneCount === state.length && state.length > 0;
  const quizPassed = savedBest !== null && quizTotal > 0 && savedBest / quizTotal >= QUIZ_PASS_FRACTION;
  const certified = allDone && quizPassed;

  async function markComplete() {
    if (!lesson || lesson.done) return;
    setBusy(true);
    setError("");
    try {
      const res = await fetch("/api/progress", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ lessonId: lesson.id })
      });
      const body = await res.json();
      if (!res.ok) {
        setError(body.error || "Could not save progress.");
      } else {
        setState((prev) => prev.map((l) => (l.id === lesson.id ? { ...l, done: true } : l)));
        const idx = state.findIndex((l) => l.id === lesson.id);
        const next = state[idx + 1];
        if (next) setCurrent(next.id);
        router.refresh();
      }
    } catch {
      setError("Could not reach the server. Is the dev server running?");
    } finally {
      setBusy(false);
    }
  }

  async function submitQuiz() {
    if (Object.keys(picks).length < questions.length) {
      setQuizError("Answer every question first.");
      return;
    }
    setQuizBusy(true);
    setQuizError("");
    try {
      const res = await fetch("/api/quiz", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug, answers: questions.map((_, i) => picks[i]) })
      });
      const body = await res.json();
      if (!res.ok) {
        setQuizError(body.error || "Could not grade the quiz.");
      } else {
        setResult(body);
        if (savedBest === null || body.score > savedBest) setSavedBest(body.score);
        router.refresh();
      }
    } catch {
      setQuizError("Could not reach the server. Is the dev server running?");
    } finally {
      setQuizBusy(false);
    }
  }

  return (
    <div className="grid-2" style={{ gridTemplateColumns: "1fr 2fr" }}>
      {/* Lesson list */}
      <div className="panel" style={{ marginBottom: 0 }}>
        <div className="panel-head">
          <h2>Lessons</h2>
          <span className="chip neutral">{percent}%</span>
        </div>
        <div style={{ padding: "0 18px" }}>
          <div className="meter"><div style={{ width: percent + "%" }}></div></div>
        </div>
        <ul className="lesson-list" style={{ marginTop: 10 }}>
          {state.map((l) => (
            <li key={l.id}>
              <button
                type="button"
                className={"lesson-item" + (l.id === current ? " current" : "")}
                onClick={() => { setCurrent(l.id); setResult(null); setPicks({}); }}
              >
                <span className="l-title">
                  {l.done ? (
                    <span className="done-mark">+</span>
                  ) : (
                    <span className="l-idx">{String(l.idx).padStart(2, "0")}</span>
                  )}
                  {l.title}
                </span>
                <span className="l-min">{l.minutes} min</span>
              </button>
            </li>
          ))}
        </ul>
      </div>

      {/* Player */}
      <div>
        {lesson ? (
          <div className="player-card" style={{ marginBottom: 18 }}>
            <span className="chip neutral">Lesson {String(lesson.idx).padStart(2, "0")}</span>
            <h3>{lesson.title}</h3>
            <p className="sub">
              In this fictional demo the video player is replaced by this panel -
              in the real product the lesson video, transcript and exercise files
              would load here.
            </p>
            <p className="sub" style={{ marginBottom: 0 }}>{lesson.minutes} minutes</p>
            {lesson.done ? (
              <div className="notice ok" style={{ marginTop: 12, marginBottom: 0 }}>
                Completed. Nice work.
              </div>
            ) : (
              <div style={{ marginTop: 12 }}>
                <button className="btn" type="button" disabled={busy} onClick={markComplete}>
                  {busy ? "Saving..." : "Mark lesson complete"}
                </button>
                {error && <p className="error-text">{error}</p>}
              </div>
            )}
          </div>
        ) : (
          <div className="panel"><div className="empty">This course has no lessons yet.</div></div>
        )}

        {/* Certificate */}
        {certified && (
          <div className="cert" style={{ marginBottom: 18 }}>
            <span className="chip ok">Certificate earned</span>
            <h2 style={{ marginTop: 10 }}>{courseTitle}</h2>
            <p className="sub">All lessons complete, final quiz passed.</p>
            <div className="cert-code">TA-{String(enrollmentId).padStart(6, "0")}-{slug.toUpperCase()}</div>
            <p className="sub" style={{ marginTop: 8, marginBottom: 0, fontSize: 12 }}>
              Show this code on your CV or portfolio - it is fictional, but the habit is real.
            </p>
          </div>
        )}

        {/* Quiz */}
        {questions.length > 0 && (
          <div className="panel" style={{ marginBottom: 0 }}>
            <div className="panel-head">
              <h2>Final quiz</h2>
              {savedBest !== null && quizTotal > 0 && (
                <span className={"chip " + (quizPassed ? "ok" : "warn")}>
                  Best: {savedBest}/{quizTotal}
                </span>
              )}
            </div>
            <div className="panel-body">
              <p className="sub">
                Pass with at least {Math.ceil(QUIZ_PASS_FRACTION * 100)}% and finish all
                lessons to earn your certificate. Graded on the server; your best score counts.
              </p>
              {questions.map((question, qi) => (
                <div key={qi} style={{ marginBottom: 14 }}>
                  <div style={{ fontSize: 14, marginBottom: 6 }}>
                    <strong>{qi + 1}.</strong> {question.q}
                  </div>
                  {question.options.map((opt, oi) => {
                    let cls = "quiz-opt";
                    if (result) {
                      // after grading: show the student's pick as right/wrong
                      if (oi === picks[qi]) cls += result.correct[qi] ? " right" : " wrong";
                    } else if (picks[qi] === oi) {
                      cls += " picked";
                    }
                    return (
                      <button
                        key={oi}
                        type="button"
                        className={cls}
                        disabled={!!result}
                        onClick={() => setPicks({ ...picks, [qi]: oi })}
                      >
                        {opt}
                      </button>
                    );
                  })}
                </div>
              ))}
              {!result ? (
                <>
                  <button className="btn" type="button" disabled={quizBusy} onClick={submitQuiz}>
                    {quizBusy ? "Grading..." : "Submit answers"}
                  </button>
                  {quizError && <p className="error-text">{quizError}</p>}
                </>
              ) : (
                <div className={"notice " + (result.passed ? "ok" : "warn")}>
                  Scored {result.score} of {result.total} -{" "}
                  {result.passed
                    ? "passed. Finish all lessons to unlock your certificate."
                    : "not passed yet. Review the lessons above and try again."}
                  {" "}
                  <button
                    className="btn ghost sm"
                    type="button"
                    style={{ marginLeft: 8 }}
                    onClick={() => { setResult(null); setPicks({}); }}
                  >
                    Retake
                  </button>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
TA_EOF
echo "wrote app/dashboard/[slug]/LearnClient.tsx"
mkdir -p "$(dirname "app/dashboard/[slug]/page.tsx")"
cat > "app/dashboard/[slug]/page.tsx" <<'TA_EOF'
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
TA_EOF
echo "wrote app/dashboard/[slug]/page.tsx"
mkdir -p "$(dirname "app/dashboard/page.tsx")"
cat > "app/dashboard/page.tsx" <<'TA_EOF'
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
TA_EOF
echo "wrote app/dashboard/page.tsx"
mkdir -p "$(dirname "app/globals.css")"
cat > "app/globals.css" <<'TA_EOF'
/* ============================================================
   Temari Academy - bold modern design system
   Dark violet-black base (default) + light theme via
   html[data-theme="light"]. Vivid violet/pink accents.
   ============================================================ */

:root {
  --bg: #0a0713;
  --panel: #130d22;
  --panel-2: #0e0919;
  --ink: #f1edfa;
  --muted: #a396c4;
  --hairline: #241a3e;
  --accent: #8b5cf6;
  --accent-bright: #a78bfa;
  --accent-soft: rgba(139, 92, 246, 0.14);
  --vivid: #ec4899;
  --vivid-soft: rgba(236, 72, 153, 0.13);
  --grad: linear-gradient(93deg, #8b5cf6, #ec4899);
  --ok: #34d399;
  --ok-soft: rgba(52, 211, 153, 0.12);
  --bad: #f87171;
  --bad-soft: rgba(248, 113, 113, 0.12);
  --warn: #fbbf24;
  --warn-soft: rgba(251, 191, 36, 0.12);
  --header-bg: rgba(10, 7, 19, 0.92);
  --grid-line: rgba(139, 92, 246, 0.07);
  --shadow: 0 1px 2px rgba(0, 0, 0, 0.5), 0 8px 24px rgba(0, 0, 0, 0.4);
}

html[data-theme="light"] {
  --bg: #faf8ff;
  --panel: #ffffff;
  --panel-2: #f1edf9;
  --ink: #160f28;
  --muted: #5e5478;
  --hairline: #e2dbf0;
  --accent: #7c3aed;
  --accent-bright: #6d28d9;
  --accent-soft: rgba(124, 58, 237, 0.10);
  --vivid: #db2777;
  --vivid-soft: rgba(219, 39, 119, 0.10);
  --grad: linear-gradient(93deg, #7c3aed, #db2777);
  --ok: #059669;
  --ok-soft: rgba(5, 150, 105, 0.12);
  --bad: #dc2626;
  --bad-soft: rgba(220, 38, 38, 0.12);
  --warn: #b45309;
  --warn-soft: rgba(180, 83, 9, 0.12);
  --header-bg: rgba(250, 248, 255, 0.92);
  --grid-line: rgba(124, 58, 237, 0.06);
  --shadow: 0 1px 2px rgba(22, 15, 40, 0.08), 0 8px 24px rgba(22, 15, 40, 0.10);
}

* { box-sizing: border-box; }

html, body {
  margin: 0;
  padding: 0;
  background: var(--bg);
  color: var(--ink);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  font-size: 15.5px;
  line-height: 1.55;
  transition: background 0.25s, color 0.25s;
}

/* Sticky footer */
body { display: flex; flex-direction: column; min-height: 100vh; }
main { flex: 1 0 auto; width: 100%; }
.site-footer { flex-shrink: 0; }

.mono, input.mono, textarea.mono, .num {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, "Liberation Mono", monospace;
}

a { color: var(--accent-bright); text-decoration: none; }
a:hover { text-decoration: underline; }
h1, h2, h3, h4 { line-height: 1.22; margin: 0 0 10px; letter-spacing: -0.01em; }
h1 { font-size: 34px; }
h2 { font-size: 21px; }
p { margin: 0 0 14px; }
label { display: block; font-size: 13px; color: var(--muted); margin-bottom: 5px; font-weight: 600; }
input, select, textarea {
  width: 100%;
  background: var(--panel-2);
  border: 1px solid var(--hairline);
  color: var(--ink);
  border-radius: 9px;
  padding: 9px 12px;
  font-size: 14px;
  font-family: inherit;
  transition: border-color 0.15s, box-shadow 0.15s;
}
input:focus, select:focus, textarea:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-soft);
}
textarea { min-height: 120px; resize: vertical; }

/* Full-width container */
.wrap {
  width: 100%;
  max-width: none;
  margin: 0 auto;
  padding: 0 44px;
}
@media (max-width: 1100px) { .wrap { padding: 0 32px; } }
@media (max-width: 700px) { .wrap { padding: 0 18px; } }

.section { padding: 52px 0; }
.sub { color: var(--muted); font-size: 14px; }
.grad-text {
  background: var(--grad);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

/* Header */
.site-header {
  display: flex;
  align-items: center;
  gap: 18px;
  padding: 14px 0;
  border-bottom: 1px solid var(--hairline);
  background: var(--header-bg);
  position: sticky;
  top: 0;
  z-index: 50;
  backdrop-filter: blur(8px);
}
.site-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-weight: 800;
  font-size: 17px;
  color: var(--ink);
}
.site-brand:hover { text-decoration: none; }
.main-nav { display: flex; gap: 18px; margin-left: auto; flex-wrap: wrap; align-items: center; }
.main-nav a { color: var(--muted); font-size: 14px; padding: 4px 2px; }
.main-nav a:hover { color: var(--ink); text-decoration: none; }
.main-nav a.active { color: var(--accent-bright); }
.header-cta { margin-left: 4px; display: flex; gap: 10px; align-items: center; }

/* Theme toggle */
.theme-toggle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: 9px;
  border: 1px solid var(--hairline);
  background: var(--panel-2);
  color: var(--muted);
  cursor: pointer;
  transition: border-color 0.15s, color 0.15s, background 0.15s;
}
.theme-toggle:hover {
  border-color: var(--accent);
  color: var(--accent-bright);
  background: var(--accent-soft);
}

/* Buttons */
.btn {
  display: inline-block;
  border: 0;
  background: var(--grad);
  color: #ffffff;
  font-size: 14.5px;
  font-weight: 600;
  border-radius: 9px;
  padding: 10px 18px;
  cursor: pointer;
  text-decoration: none !important;
  text-align: center;
  transition: filter 0.15s, transform 0.1s;
}
.btn:hover { filter: brightness(1.12); }
.btn:active { transform: translateY(1px); }
.btn:disabled { opacity: 0.5; cursor: not-allowed; }
.btn.ghost {
  background: transparent;
  color: var(--ink);
  border: 1px solid var(--hairline);
}
.btn.ghost:hover { border-color: var(--accent); color: var(--accent-bright); background: var(--accent-soft); }
.btn.sm { padding: 6px 12px; font-size: 12.5px; border-radius: 7px; }
.btn.wide { width: 100%; }

/* Chips, notices */
.chip {
  display: inline-block;
  font-size: 11.5px;
  font-weight: 700;
  border-radius: 999px;
  padding: 3px 10px;
  letter-spacing: 0.02em;
}
.chip.ok { background: var(--ok-soft); color: var(--ok); }
.chip.bad { background: var(--bad-soft); color: var(--bad); }
.chip.warn { background: var(--warn-soft); color: var(--warn); }
.chip.neutral { background: var(--accent-soft); color: var(--accent-bright); }
.chip.vivid { background: var(--vivid-soft); color: var(--vivid); }

.notice { border-radius: 10px; padding: 11px 14px; font-size: 13.5px; margin: 0 0 14px; }
.notice.ok { background: var(--ok-soft); color: var(--ok); }
.notice.bad { background: var(--bad-soft); color: var(--bad); }
.notice.warn { background: var(--warn-soft); color: var(--warn); }
.error-text { color: var(--bad); font-size: 13.5px; margin: 6px 0 0; }

/* Panels and grids */
.panel {
  background: var(--panel);
  border: 1px solid var(--hairline);
  border-radius: 14px;
  box-shadow: var(--shadow);
  margin-bottom: 18px;
  overflow: hidden;
  transition: background 0.25s, border-color 0.25s;
}
.panel-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 12px;
  padding: 14px 18px;
  border-bottom: 1px solid var(--hairline);
  flex-wrap: wrap;
}
.panel-head h2 { font-size: 16.5px; margin: 0; }
.panel-body { padding: 18px; }
.panel-body > :last-child { margin-bottom: 0; }
.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
.grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; }
.grid-4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 18px; }
@media (max-width: 980px) { .grid-2, .grid-3, .grid-4 { grid-template-columns: 1fr; } }

/* Hero: animated grid + gradient glow */
.hero {
  position: relative;
  overflow: hidden;
  padding: 84px 0 64px;
  background:
    radial-gradient(1000px 420px at 80% -20%, var(--accent-soft), transparent),
    radial-gradient(700px 340px at 5% 110%, var(--vivid-soft), transparent);
  border-bottom: 1px solid var(--hairline);
}
.hero::before {
  content: "";
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(var(--grid-line) 1px, transparent 1px),
    linear-gradient(90deg, var(--grid-line) 1px, transparent 1px);
  background-size: 44px 44px;
  mask-image: radial-gradient(75% 100% at 50% 0%, #000 30%, transparent 100%);
  -webkit-mask-image: radial-gradient(75% 100% at 50% 0%, #000 30%, transparent 100%);
  pointer-events: none;
}
.hero .wrap { position: relative; }
.hero h1 { font-size: 46px; max-width: 820px; }
.hero .sub { font-size: 17px; max-width: 640px; }
.hero-actions { display: flex; gap: 12px; margin-top: 26px; flex-wrap: wrap; }
.hero-kicker {
  display: inline-block;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 12.5px;
  color: var(--accent-bright);
  background: var(--accent-soft);
  border: 1px solid rgba(139, 92, 246, 0.35);
  border-radius: 999px;
  padding: 5px 13px;
  margin-bottom: 18px;
}
.hero-kicker::after { content: "_"; animation: blink 1.1s steps(1) infinite; }
@keyframes blink { 50% { opacity: 0; } }

/* Cards */
.card {
  background: var(--panel);
  border: 1px solid var(--hairline);
  border-radius: 14px;
  padding: 20px;
  box-shadow: var(--shadow);
  transition: transform 0.18s, border-color 0.18s, background 0.25s;
}
.card:hover { transform: translateY(-3px); border-color: var(--accent); }
.card h3 { font-size: 16px; margin-bottom: 6px; }
.card p { font-size: 13.5px; color: var(--muted); margin-bottom: 0; }
.card .num-badge {
  display: inline-flex;
  width: 32px;
  height: 32px;
  align-items: center;
  justify-content: center;
  border-radius: 9px;
  background: var(--grad);
  color: #ffffff;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-weight: 700;
  font-size: 13px;
  margin-bottom: 12px;
}

/* Course cards */
.course-card { display: flex; flex-direction: column; gap: 8px; }
.course-card .course-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 10px;
}
.course-card h3 { margin: 0; }
.course-card .price {
  font-weight: 800;
  font-size: 15px;
  color: var(--accent-bright);
  white-space: nowrap;
}
.course-card .price.free { color: var(--ok); }
.course-meta { display: flex; gap: 8px; flex-wrap: wrap; }
.course-card .go { margin-top: 6px; font-weight: 600; }

/* Stats */
.stat {
  background: var(--panel);
  border: 1px solid var(--hairline);
  border-radius: 14px;
  padding: 16px 18px;
  box-shadow: var(--shadow);
  transition: background 0.25s;
}
.stat .l { font-size: 11.5px; color: var(--muted); text-transform: uppercase; letter-spacing: 0.07em; }
.stat .n { font-size: 26px; font-weight: 800; margin-top: 4px; background: var(--grad); -webkit-background-clip: text; background-clip: text; color: transparent; }

/* Page head */
.page-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 14px;
  margin-bottom: 22px;
  flex-wrap: wrap;
}

/* Tables */
.table-scroll { overflow-x: auto; }
.ac-table { width: 100%; border-collapse: collapse; font-size: 14px; }
.ac-table th {
  text-align: left;
  font-size: 11.5px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--muted);
  padding: 10px 12px;
  border-bottom: 1px solid var(--hairline);
}
.ac-table td { padding: 10px 12px; border-bottom: 1px solid var(--hairline); vertical-align: top; }
.ac-table tr:last-child td { border-bottom: 0; }
.ac-table .num { text-align: right; white-space: nowrap; }
.empty { padding: 26px 14px; text-align: center; color: var(--muted); font-size: 14px; }

/* Forms */
.form-stack > div { margin-bottom: 14px; }
.form-stack input, .form-stack select, .form-stack textarea { max-width: 520px; }
.form-stack .wide-field { max-width: none; }

/* Progress / meter */
.meter { height: 8px; background: var(--panel-2); border: 1px solid var(--hairline); border-radius: 6px; overflow: hidden; margin: 8px 0 4px; }
.meter > div { height: 100%; border-radius: 6px; background: var(--grad); transition: width 0.25s; }

/* Learn page */
.lesson-list { list-style: none; margin: 0; padding: 0; }
.lesson-list li { border-bottom: 1px solid var(--hairline); }
.lesson-list li:last-child { border-bottom: 0; }
.lesson-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
  width: 100%;
  background: none;
  border: 0;
  color: var(--ink);
  font-size: 14px;
  font-family: inherit;
  padding: 11px 18px;
  cursor: pointer;
  text-align: left;
  transition: background 0.15s;
}
.lesson-item:hover { background: var(--accent-soft); }
.lesson-item.current { background: var(--accent-soft); box-shadow: inset 3px 0 0 var(--accent); }
.lesson-item .l-title { display: flex; gap: 10px; align-items: baseline; }
.lesson-item .l-idx { color: var(--muted); font-family: ui-monospace, monospace; font-size: 12px; }
.lesson-item .l-min { color: var(--muted); font-size: 12px; white-space: nowrap; }
.lesson-item .done-mark { color: var(--ok); font-weight: 700; }
.player-card {
  border: 1px solid var(--hairline);
  border-radius: 12px;
  background: var(--panel-2);
  padding: 28px 22px;
  min-height: 220px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.player-card h3 { font-size: 19px; margin-bottom: 4px; }

/* Quiz */
.quiz-opt {
  display: block;
  width: 100%;
  text-align: left;
  background: var(--panel-2);
  border: 1px solid var(--hairline);
  border-radius: 9px;
  color: var(--ink);
  font-size: 14px;
  font-family: inherit;
  padding: 10px 13px;
  margin-bottom: 8px;
  cursor: pointer;
  transition: border-color 0.15s, background 0.15s;
}
.quiz-opt:hover { border-color: var(--accent); }
.quiz-opt.picked { border-color: var(--accent); background: var(--accent-soft); }
.quiz-opt.right { border-color: var(--ok); background: var(--ok-soft); }
.quiz-opt.wrong { border-color: var(--bad); background: var(--bad-soft); }

/* Certificate */
.cert {
  border: 2px solid var(--accent);
  border-radius: 14px;
  padding: 26px;
  text-align: center;
  background:
    radial-gradient(500px 160px at 50% -40%, var(--accent-soft), transparent),
    var(--panel);
}
.cert .cert-code {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 13px;
  color: var(--muted);
  letter-spacing: 0.08em;
}

/* Footer */
.site-footer {
  border-top: 1px solid var(--hairline);
  padding: 30px 0;
  font-size: 13.5px;
  color: var(--muted);
}
.footer-row { display: flex; justify-content: space-between; gap: 20px; flex-wrap: wrap; }

@media (prefers-reduced-motion: reduce) {
  .hero-kicker::after { animation: none; }
  .card:hover { transform: none; }
}

/* Learn page stacks on narrow screens */
@media (max-width: 980px) {
  .grid-2[style*="1fr 2fr"] { grid-template-columns: 1fr !important; }
}
TA_EOF
echo "wrote app/globals.css"
mkdir -p "$(dirname "app/layout.tsx")"
cat > "app/layout.tsx" <<'TA_EOF'
import type { Metadata } from "next";
import "./globals.css";
import SiteHeader from "../components/SiteHeader";
import SiteFooter from "../components/SiteFooter";
import { getAuth } from "../lib/auth";

export const metadata: Metadata = {
  title: "Temari Academy - Learn skills that get you hired in Ethiopia",
  description:
    "Technology, business, design and language courses taught by Ethiopian professionals. Portfolio-first learning in Amharic or English."
};

// Runs before first paint so a saved light theme never flashes dark.
const themeInit = `(function(){try{var t=localStorage.getItem("temari-theme");if(t==="light"){document.documentElement.setAttribute("data-theme","light");}}catch(e){}})();`;

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const user = await getAuth();
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInit }} />
      </head>
      <body>
        <SiteHeader
          signedIn={!!user}
          userName={user?.name ?? ""}
          isAdmin={user?.role === "admin"}
        />
        <main>{children}</main>
        <SiteFooter />
      </body>
    </html>
  );
}
TA_EOF
echo "wrote app/layout.tsx"
mkdir -p "$(dirname "app/login/LoginForm.tsx")"
cat > "app/login/LoginForm.tsx" <<'TA_EOF'
"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";

export default function LoginForm() {
  const router = useRouter();
  const search = useSearchParams();
  const next = search.get("next") || "/dashboard";
  const expired = search.get("expired") === "1";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setBusy(true);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password, next })
      });
      const body = await res.json();
      if (!res.ok) {
        setError(body.error || "Sign in failed. Please try again.");
      } else {
        router.push(body.next || "/dashboard");
        router.refresh();
      }
    } catch {
      setError("Could not reach the server. Is the dev server running?");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="panel">
      <div className="panel-body">
        {expired && (
          <div className="notice warn">Your session expired. Please sign in again.</div>
        )}
        {error && <div className="notice bad">{error}</div>}
        <form className="form-stack" onSubmit={submit} style={{ maxWidth: 440 }}>
          <div>
            <label htmlFor="lf-email">Email</label>
            <input id="lf-email" className="mono" type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="username" />
          </div>
          <div>
            <label htmlFor="lf-pass">Password</label>
            <input id="lf-pass" type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
          </div>
          <div>
            <button className="btn" type="submit" disabled={busy}>
              {busy ? "Signing in..." : "Sign in"}
            </button>
          </div>
        </form>
        <p className="sub" style={{ marginBottom: 0 }}>
          New here? <Link href="/signup">Create a free account</Link>.
        </p>
      </div>
    </div>
  );
}
TA_EOF
echo "wrote app/login/LoginForm.tsx"
mkdir -p "$(dirname "app/login/page.tsx")"
cat > "app/login/page.tsx" <<'TA_EOF'
import type { Metadata } from "next";
import { Suspense } from "react";
import LoginForm from "./LoginForm";

export const metadata: Metadata = {
  title: "Sign in - Temari Academy"
};

export default function LoginPage() {
  return (
    <div className="wrap section" style={{ maxWidth: 640 }}>
      <div className="page-head">
        <div>
          <h1>Sign in</h1>
          <p className="sub">Welcome back. Your progress is waiting where you left it.</p>
        </div>
      </div>
      <Suspense>
        <LoginForm />
      </Suspense>
    </div>
  );
}
TA_EOF
echo "wrote app/login/page.tsx"
mkdir -p "$(dirname "app/page.tsx")"
cat > "app/page.tsx" <<'TA_EOF'
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
TA_EOF
echo "wrote app/page.tsx"
mkdir -p "$(dirname "app/signup/page.tsx")"
cat > "app/signup/page.tsx" <<'TA_EOF'
import type { Metadata } from "next";
import Link from "next/link";
import SignupForm from "./SignupForm";

export const metadata: Metadata = {
  title: "Join free - Temari Academy"
};

export default function SignupPage() {
  return (
    <div className="wrap section" style={{ maxWidth: 640 }}>
      <div className="page-head">
        <div>
          <h1>Create your account</h1>
          <p className="sub">Free forever for free courses. No card needed.</p>
        </div>
      </div>
      <SignupForm />
      <p className="sub">
        Already have an account? <Link href="/login">Sign in</Link>.
      </p>
    </div>
  );
}
TA_EOF
echo "wrote app/signup/page.tsx"
mkdir -p "$(dirname "app/signup/SignupForm.tsx")"
cat > "app/signup/SignupForm.tsx" <<'TA_EOF'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function SignupForm() {
  const router = useRouter();
  const [form, setForm] = useState({ name: "", email: "", password: "", confirm: "", website: "" });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  function set<K extends keyof typeof form>(key: K, value: string) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    if (form.website) return; // honeypot
    if (!form.name.trim()) { setError("Enter your name."); return; }
    if (form.password.length < 8) { setError("Password must be at least 8 characters."); return; }
    if (form.password !== form.confirm) { setError("Passwords do not match."); return; }
    setBusy(true);
    try {
      const res = await fetch("/api/auth/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form)
      });
      const body = await res.json();
      if (!res.ok) {
        setError(body.error || "Signup failed. Please try again.");
      } else {
        router.push("/dashboard");
        router.refresh();
      }
    } catch {
      setError("Could not reach the server. Is the dev server running?");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="panel">
      <div className="panel-body">
        {error && <div className="notice bad">{error}</div>}
        <form className="form-stack" onSubmit={submit} autoComplete="off" style={{ maxWidth: 440 }}>
          <div>
            <label htmlFor="sf-name">Full name</label>
            <input id="sf-name" value={form.name} onChange={(e) => set("name", e.target.value)} maxLength={120} autoComplete="name" />
          </div>
          <div>
            <label htmlFor="sf-email">Email</label>
            <input id="sf-email" className="mono" type="email" value={form.email} onChange={(e) => set("email", e.target.value)} maxLength={200} autoComplete="email" />
          </div>
          <div>
            <label htmlFor="sf-pass">Password (min 8 characters)</label>
            <input id="sf-pass" type="password" value={form.password} onChange={(e) => set("password", e.target.value)} autoComplete="new-password" />
          </div>
          <div>
            <label htmlFor="sf-confirm">Confirm password</label>
            <input id="sf-confirm" type="password" value={form.confirm} onChange={(e) => set("confirm", e.target.value)} autoComplete="new-password" />
          </div>
          <div style={{ position: "absolute", left: -9999, top: -9999 }}>
            <label htmlFor="sf-website">Website</label>
            <input id="sf-website" tabIndex={-1} autoComplete="off" value={form.website} onChange={(e) => set("website", e.target.value)} />
          </div>
          <div>
            <button className="btn" type="submit" disabled={busy}>
              {busy ? "Creating account..." : "Create free account"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
TA_EOF
echo "wrote app/signup/SignupForm.tsx"
mkdir -p "$(dirname "components/AnimatedStats.tsx")"
cat > "components/AnimatedStats.tsx" <<'TA_EOF'
"use client";

import { useEffect, useRef, useState } from "react";

type Stat = { l: string; n: string };

function parseStat(n: string): { value: number; suffix: string } | null {
  const m = n.match(/^([0-9.]+)(.*)$/);
  if (!m) return null;
  return { value: parseFloat(m[1]), suffix: m[2] };
}

function AnimatedNumber({ n }: { n: string }) {
  const parsed = parseStat(n);
  const [display, setDisplay] = useState(parsed ? "0" + parsed.suffix : n);
  const raf = useRef<number | null>(null);

  useEffect(() => {
    if (!parsed) return;
    const start = performance.now();
    const duration = 1100;
    const step = (now: number) => {
      const t = Math.min(1, (now - start) / duration);
      const eased = 1 - Math.pow(1 - t, 3);
      setDisplay(String(Math.round(parsed.value * eased)) + parsed.suffix);
      if (t < 1) raf.current = requestAnimationFrame(step);
    };
    raf.current = requestAnimationFrame(step);
    return () => {
      if (raf.current) cancelAnimationFrame(raf.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [n]);

  return <div className="n">{display}</div>;
}

export default function AnimatedStats({ stats }: { stats: Stat[] }) {
  return (
    <div className="grid-4">
      {stats.map((s) => (
        <div className="stat" key={s.l}>
          <div className="l">{s.l}</div>
          <AnimatedNumber n={s.n} />
        </div>
      ))}
    </div>
  );
}
TA_EOF
echo "wrote components/AnimatedStats.tsx"
mkdir -p "$(dirname "components/EnrollButton.tsx")"
cat > "components/EnrollButton.tsx" <<'TA_EOF'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function EnrollButton({
  slug,
  signedIn,
  priceFree
}: {
  slug: string;
  signedIn: boolean;
  priceFree: boolean;
}) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function enroll() {
    if (!signedIn) {
      router.push("/login?next=/courses/" + slug);
      return;
    }
    setBusy(true);
    setError("");
    try {
      const res = await fetch("/api/enroll", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug })
      });
      const body = await res.json();
      if (!res.ok) {
        setError(body.error || "Enrollment failed. Please try again.");
      } else {
        router.push("/dashboard/" + slug);
        router.refresh();
      }
    } catch {
      setError("Could not reach the server. Is the dev server running?");
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <button className="btn wide" type="button" disabled={busy} onClick={enroll}>
        {busy ? "Enrolling..." : priceFree ? "Enroll free" : "Enroll now"}
      </button>
      {error && <p className="error-text">{error}</p>}
    </>
  );
}
TA_EOF
echo "wrote components/EnrollButton.tsx"
mkdir -p "$(dirname "components/SiteFooter.tsx")"
cat > "components/SiteFooter.tsx" <<'TA_EOF'
import Link from "next/link";
import { COMPANY } from "../lib/content";

export default function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="wrap footer-row">
        <div>
          <strong>{COMPANY.name}</strong> - {COMPANY.tagline}.<br />
          {COMPANY.city} | {COMPANY.email} | {COMPANY.phone}
        </div>
        <div>
          <Link href="/courses">Courses</Link> |{" "}
          <Link href="/about">About</Link> |{" "}
          <Link href="/contact">Contact</Link>
          <div className="sub" style={{ marginTop: 6, marginBottom: 0 }}>
            Fictional academy created for a portfolio project. Not a real school.
          </div>
        </div>
      </div>
    </footer>
  );
}
TA_EOF
echo "wrote components/SiteFooter.tsx"
mkdir -p "$(dirname "components/SiteHeader.tsx")"
cat > "components/SiteHeader.tsx" <<'TA_EOF'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import ThemeToggle from "./ThemeToggle";

// Brand mark: a stylized open book with a rising bolt, inline SVG.
function BrandMark() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" aria-hidden="true">
      <defs>
        <linearGradient id="tagrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#8b5cf6" />
          <stop offset="1" stopColor="#ec4899" />
        </linearGradient>
      </defs>
      <path
        d="M12 4c-2-1.6-4.6-2-8-2v14c3.4 0 6 .4 8 2 2-1.6 4.6-2 8-2V2c-3.4 0-6 .4-8 2z"
        fill="none"
        stroke="url(#tagrad)"
        strokeWidth="2"
        strokeLinejoin="round"
      />
      <path d="M8 9h5M8 12h5M8 15h3" stroke="url(#tagrad)" strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  );
}

export default function SiteHeader({
  signedIn,
  userName,
  isAdmin
}: {
  signedIn: boolean;
  userName: string;
  isAdmin: boolean;
}) {
  const path = usePathname();
  const on = (href: string) =>
    path === href || (href !== "/" && path.startsWith(href + "/")) ? " active" : "";

  return (
    <header className="site-header">
      <div className="wrap" style={{ display: "flex", alignItems: "center", gap: 18 }}>
        <Link href="/" className="site-brand">
          <BrandMark />
          <span><span className="grad-text">Temari</span> Academy</span>
        </Link>
        <nav className="main-nav">
          <Link href="/courses" className={on("/courses")}>Courses</Link>
          <Link href="/about" className={on("/about")}>About</Link>
          <Link href="/contact" className={on("/contact")}>Contact</Link>
          {signedIn && (
            <Link href="/dashboard" className={on("/dashboard")}>My learning</Link>
          )}
          {isAdmin && (
            <Link href="/admin" className={on("/admin")}>Admin</Link>
          )}
        </nav>
        <span className="header-cta">
          {signedIn ? (
            <span style={{ display: "inline-flex", gap: 10, alignItems: "center" }}>
              <span className="sub" style={{ margin: 0 }}>Hi, {userName.split(" ")[0]}</span>
              <form action="/api/auth/logout" method="post">
                <button className="btn ghost sm" type="submit">Sign out</button>
              </form>
            </span>
          ) : (
            <>
              <Link href="/login" className="btn ghost sm">Sign in</Link>
              <Link href="/signup" className="btn sm">Join free</Link>
            </>
          )}
          <ThemeToggle />
        </span>
      </div>
    </header>
  );
}
TA_EOF
echo "wrote components/SiteHeader.tsx"
mkdir -p "$(dirname "components/ThemeToggle.tsx")"
cat > "components/ThemeToggle.tsx" <<'TA_EOF'
"use client";

import { useEffect, useState } from "react";

export default function ThemeToggle() {
  const [theme, setTheme] = useState<"dark" | "light">("dark");
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    const current = document.documentElement.getAttribute("data-theme") === "light" ? "light" : "dark";
    setTheme(current);
  }, []);

  function toggle() {
    const next = theme === "dark" ? "light" : "dark";
    setTheme(next);
    if (next === "light") {
      document.documentElement.setAttribute("data-theme", "light");
    } else {
      document.documentElement.removeAttribute("data-theme");
    }
    try {
      localStorage.setItem("temari-theme", next);
    } catch {
      // private mode: toggle still works for this session
    }
  }

  if (!mounted) {
    return <button className="theme-toggle" type="button" aria-label="Toggle theme" />;
  }

  return (
    <button
      className="theme-toggle"
      type="button"
      onClick={toggle}
      title={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}
      aria-label={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}
    >
      {theme === "dark" ? (
        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
          <circle cx="12" cy="12" r="4.5" />
          <path d="M12 2v2.5M12 19.5V22M2 12h2.5M19.5 12H22M4.6 4.6l1.8 1.8M17.6 17.6l1.8 1.8M19.4 4.6l-1.8 1.8M6.4 17.6l-1.8 1.8" />
        </svg>
      ) : (
        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
          <path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5z" />
        </svg>
      )}
    </button>
  );
}
TA_EOF
echo "wrote components/ThemeToggle.tsx"
mkdir -p "$(dirname "lib/auth.ts")"
cat > "lib/auth.ts" <<'TA_EOF'
// Server-only auth utilities. Client components must NEVER import this file
// (it uses node:crypto and prisma). Client-safe values live in
// lib/clientConstants.ts.

import { createHmac, randomBytes, scryptSync, timingSafeEqual } from "crypto";
import { cookies } from "next/headers";
import { prisma } from "./prisma";

const SECRET = process.env.SESSION_SECRET || "temari-dev-secret-change-me";
const COOKIE_NAME = "temari_session";
const SESSION_HOURS = 8;

export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString("hex");
  const hash = scryptSync(password, salt, 64).toString("hex");
  return salt + ":" + hash;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [salt, hash] = stored.split(":");
  if (!salt || !hash) return false;
  const candidate = scryptSync(password, salt, 64);
  const expected = Buffer.from(hash, "hex");
  if (candidate.length !== expected.length) return false;
  return timingSafeEqual(candidate, expected);
}

function sign(payload: string): string {
  return createHmac("sha256", SECRET).update(payload).digest("hex");
}

export function createSessionToken(userId: number): string {
  const exp = Date.now() + SESSION_HOURS * 3600 * 1000;
  const payload = userId + "." + exp;
  return payload + "." + sign(payload);
}

export function parseSessionToken(token: string | undefined): number | null {
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const [id, exp, sig] = parts;
  const payload = id + "." + exp;
  const expected = sign(payload);
  if (
    sig.length !== expected.length ||
    !timingSafeEqual(Buffer.from(sig), Buffer.from(expected))
  ) {
    return null;
  }
  if (Number(exp) < Date.now()) return null;
  const userId = Number(id);
  return Number.isInteger(userId) && userId > 0 ? userId : null;
}

export type SessionUser = {
  id: number;
  name: string;
  email: string;
  role: string;
};

export async function getAuth(): Promise<SessionUser | null> {
  const store = cookies();
  const userId = parseSessionToken(store.get(COOKIE_NAME)?.value);
  if (userId === null) return null;
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, name: true, email: true, role: true }
  });
  return user ?? null;
}

export const sessionCookieName = COOKIE_NAME;
export const sessionMaxAge = SESSION_HOURS * 3600; // seconds, for cookie options
TA_EOF
echo "wrote lib/auth.ts"
mkdir -p "$(dirname "lib/clientConstants.ts")"
cat > "lib/clientConstants.ts" <<'TA_EOF'
// Client-safe constants and pure helpers. No crypto, no prisma here -
// safe to import from client components.

export const LEVELS = ["beginner", "intermediate", "advanced"] as const;

export const CATEGORIES = [
  "Technology",
  "Business",
  "Design",
  "Language",
  "Data"
] as const;

export const LEVEL_LABELS: Record<string, string> = {
  beginner: "Beginner",
  intermediate: "Intermediate",
  advanced: "Advanced"
};

export const TOPICS = [
  "Question about a course",
  "Teaching with us",
  "Partnership",
  "Something else"
] as const;

// ETB formatter: prices are integer cents everywhere.
export function etb(cents: number): string {
  const birr = Math.floor(cents / 100);
  return "ETB " + birr.toLocaleString("en-US");
}

// 0..1 progress fraction to a percent label.
export function pct(done: number, total: number): number {
  if (total <= 0) return 0;
  return Math.round((done / total) * 100);
}

export const QUIZ_PASS_FRACTION = 0.7;
TA_EOF
echo "wrote lib/clientConstants.ts"
mkdir -p "$(dirname "lib/content.ts")"
cat > "lib/content.ts" <<'TA_EOF'
// Shared marketing content for Temari Academy. Server-safe (no crypto,
// no prisma) so any component can import it.

export const COMPANY = {
  name: "Temari Academy",
  tagline: "Learn what employers actually hire for",
  city: "Addis Ababa, Ethiopia",
  email: "hello@temari.academy",
  phone: "+251 91 200 7700"
};

export const STATS = [
  { l: "Students enrolled", n: "8500+" },
  { l: "Courses taught in Amharic or English", n: "40+" },
  { l: "Completion rate", n: "72%" },
  { l: "Graduates hired or promoted", n: "310+" }
];

export const TESTIMONIALS = [
  {
    name: "Hanna G.",
    role: "Junior developer, Dashen Bank",
    quote:
      "I finished the web development track unemployed. Four months later I passed a technical interview. The final projects are what got me the job."
  },
  {
    name: "Abenezer T.",
    role: "Operations lead, a logistics firm",
    quote:
      "The Excel and data courses are taught with Ethiopian business examples, not Silicon Valley ones. I rebuilt our whole monthly reporting pack."
  },
  {
    name: "Sara M.",
    role: "Freelance designer",
    quote:
      "I started the design track for free while working a retail job. The portfolio review at the end was worth more than the certificate."
  }
];

export const WHY = [
  {
    title: "Built for the Ethiopian market",
    body:
      "Examples use local businesses, local data and the tools companies here actually run on - not generic US case studies."
  },
  {
    title: "Instructors who practice",
    body:
      "Every course is taught by someone doing the work professionally in the Ethiopian market right now, not a career video presenter."
  },
  {
    title: "Portfolio-first learning",
    body:
      "Each track ends with a real project reviewed by the instructor, so you finish with proof of skill, not just a certificate."
  },
  {
    title: "Learn in your language",
    body:
      "Courses are taught in Amharic, English or both, with captions, so nothing gets lost between the lesson and the exam."
  }
];

export const TEAM = [
  {
    name: "Liya Bekele",
    role: "Founder and CEO",
    bio: "Former curriculum lead at a national university. Started Temari because the best students she taught never got jobs without connections.",
    initials: "LB"
  },
  {
    name: "Samuel Wolde",
    role: "Head of Technology Tracks",
    bio: "Full-stack engineer by day, instructor by night. Has mentored 30 developers into their first jobs.",
    initials: "SW"
  },
  {
    name: "Bethlehem Alemu",
    role: "Head of Business Tracks",
    bio: "MBA, ex-bank analyst. Builds courses around the spreadsheets and reports Ethiopian offices really use.",
    initials: "BA"
  }
];
TA_EOF
echo "wrote lib/content.ts"
mkdir -p "$(dirname "lib/prisma.ts")"
cat > "lib/prisma.ts" <<'TA_EOF'
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["warn", "error"] : ["error"]
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
TA_EOF
echo "wrote lib/prisma.ts"
mkdir -p "$(dirname "middleware.ts")"
cat > "middleware.ts" <<'TA_EOF'
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Never let the browser cache authenticated pages, so the back button
// after logout never shows a stale dashboard.
export function middleware(req: NextRequest) {
  const res = NextResponse.next();
  const path = req.nextUrl.pathname;
  if (path === "/dashboard" || path.startsWith("/dashboard/") || path === "/admin" || path.startsWith("/admin/")) {
    res.headers.set("Cache-Control", "no-store, must-revalidate");
  }
  return res;
}

export const config = {
  matcher: ["/dashboard/:path*", "/admin/:path*"]
};
TA_EOF
echo "wrote middleware.ts"
mkdir -p "$(dirname "next.config.mjs")"
cat > "next.config.mjs" <<'TA_EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true
};

export default nextConfig;
TA_EOF
echo "wrote next.config.mjs"
mkdir -p "$(dirname "package.json")"
cat > "package.json" <<'TA_EOF'
{
  "name": "temari-academy",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "db:push": "prisma db push",
    "db:seed": "node prisma/seed.mjs"
  },
  "dependencies": {
    "@prisma/client": "^5.22.0",
    "next": "^14.2.5",
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@types/node": "^20.14.0",
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "prisma": "^5.22.0",
    "typescript": "^5.5.4"
  }
}
TA_EOF
echo "wrote package.json"
mkdir -p "$(dirname "prisma/schema.prisma")"
cat > "prisma/schema.prisma" <<'TA_EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model User {
  id           Int       @id @default(autoincrement())
  name         String
  email        String    @unique
  passwordHash String
  role         String    @default("student") // student | admin
  createdAt    DateTime  @default(now())
  enrollments  Enrollment[]
  progress     LessonProgress[]
  quizResults  QuizResult[]
  messages     ContactMessage[]
}

model Course {
  id          Int         @id @default(autoincrement())
  slug        String      @unique
  title       String
  subtitle    String
  description String
  category    String
  level       String      // beginner | intermediate | advanced
  priceCents  Int         @default(0)
  hours       Int         @default(0)
  published   Boolean     @default(true)
  quizJson    String      @default("[]")
  createdAt   DateTime    @default(now())
  lessons     Lesson[]
  enrollments Enrollment[]
  quizResults QuizResult[]
}

model Lesson {
  id        Int     @id @default(autoincrement())
  courseId  Int
  course    Course  @relation(fields: [courseId], references: [id])
  idx       Int
  title     String
  minutes   Int     @default(10)
  progress  LessonProgress[]
}

model Enrollment {
  id        Int      @id @default(autoincrement())
  userId    Int
  user      User     @relation(fields: [userId], references: [id])
  courseId  Int
  course    Course   @relation(fields: [courseId], references: [id])
  createdAt DateTime @default(now())

  @@unique([userId, courseId])
}

model LessonProgress {
  id           Int      @id @default(autoincrement())
  userId       Int
  user         User     @relation(fields: [userId], references: [id])
  lessonId     Int
  lesson       Lesson   @relation(fields: [lessonId], references: [id])
  completedAt  DateTime @default(now())

  @@unique([userId, lessonId])
}

model QuizResult {
  id        Int      @id @default(autoincrement())
  userId    Int
  user      User     @relation(fields: [userId], references: [id])
  courseId  Int
  course    Course   @relation(fields: [courseId], references: [id])
  score     Int
  total     Int
  passed    Boolean
  createdAt DateTime @default(now())
}

model ContactMessage {
  id        Int      @id @default(autoincrement())
  userId    Int?
  user      User?    @relation(fields: [userId], references: [id])
  name      String
  email     String
  topic     String
  body      String
  createdAt DateTime @default(now())

  @@index([createdAt])
}
TA_EOF
echo "wrote prisma/schema.prisma"
mkdir -p "$(dirname "prisma/seed.mjs")"
cat > "prisma/seed.mjs" <<'TA_EOF'
// Temari Academy seed. Plain ESM JavaScript so it runs with plain
// "node prisma/seed.mjs" - no extra dependencies.
// Password hashing mirrors lib/auth.ts: scryptSync(password, salt, 64).

import { PrismaClient } from "@prisma/client";
import { randomBytes, scryptSync } from "node:crypto";

const prisma = new PrismaClient();

function hashPassword(password) {
  const salt = randomBytes(16).toString("hex");
  const hash = scryptSync(password, salt, 64).toString("hex");
  return salt + ":" + hash;
}

const COURSES = [
  {
    slug: "modern-web-development",
    title: "Modern Web Development",
    subtitle: "HTML, CSS, JavaScript and React, from zero to portfolio",
    description:
      "The full track that took our graduates from zero to hired. Start with the web platform fundamentals, work through real JavaScript, then build and deploy two portfolio projects with React: a business landing page and a small dashboard consuming a real API. Every project is reviewed against a checklist used by Ethiopian tech recruiters.",
    category: "Technology",
    level: "beginner",
    priceCents: 0,
    hours: 32,
    lessons: [
      ["How the web actually works", 14],
      ["HTML that means something", 22],
      ["CSS layout without fear: flex and grid", 28],
      ["JavaScript fundamentals, part 1", 26],
      ["JavaScript fundamentals, part 2", 24],
      ["Working with APIs and JSON", 20],
      ["React components and state", 30],
      ["Portfolio project: build and deploy", 35]
    ],
    quiz: [
      { q: "Which HTTP status code means 'not found'?", options: ["200", "301", "404", "500"], answer: 2 },
      { q: "In CSS, which property controls the space BETWEEN elements in a flex row?", options: ["padding", "margin", "gap", "space"], answer: 2 },
      { q: "What does JSON.parse do?", options: ["Converts a string into an object", "Converts an object into a string", "Validates JSON syntax only", "Sends a request"], answer: 0 },
      { q: "In React, state that changes should trigger a re-render. Which hook holds it?", options: ["useMemo", "useState", "useRef", "useId"], answer: 1 },
      { q: "Which tag gives a page its visible title in the browser tab?", options: ["<meta>", "<h1>", "<title>", "<header>"], answer: 2 }
    ]
  },
  {
    slug: "data-analysis-excel",
    title: "Data Analysis with Excel",
    subtitle: "From monthly reports to decisions your manager actually uses",
    description:
      "Built for the spreadsheets Ethiopian offices really run on. Master lookups, pivot tables and charts with local business data, then automate the monthly reporting pack you already hate. The final project is a full KPI dashboard for a fictional logistics company.",
    category: "Data",
    level: "beginner",
    priceCents: 150000,
    hours: 18,
    lessons: [
      ["Cell references and the magic of absolute refs", 15],
      ["VLOOKUP, XLOOKUP and why they differ", 22],
      ["Cleaning messy data properly", 25],
      ["Pivot tables for real reporting", 28],
      ["Charts that do not lie", 18],
      ["Project: a KPI dashboard from raw exports", 35]
    ],
    quiz: [
      { q: "Which reference stays fixed when copied down a column?", options: ["A1", "$A$1", "A$1 only", "A1$"], answer: 1 },
      { q: "A pivot table primarily does what?", options: ["Formats cells by color", "Summarizes and groups data", "Protects a sheet", "Merges workbooks"], answer: 1 },
      { q: "TRIM() in Excel removes what?", options: ["Duplicates", "Extra spaces around text", "Empty rows", "Formulas"], answer: 1 },
      { q: "Which chart is best for a trend over 12 months?", options: ["Pie", "Line", "Radar", "Scatter"], answer: 1 }
    ]
  },
  {
    slug: "digital-marketing-ethiopia",
    title: "Digital Marketing for the Ethiopian Market",
    subtitle: "Social, search and content that works with local audiences",
    description:
      "Marketing taught for businesses that sell in Addis, not Silicon Valley. Build a content calendar, run a real campaign budget in birr, learn the analytics that matter, and understand how customers actually discover and trust brands here. Final project: a 30-day campaign plan for a real or fictional local business.",
    category: "Business",
    level: "intermediate",
    priceCents: 200000,
    hours: 16,
    lessons: [
      ["Who is your customer, really?", 18],
      ["The Ethiopian digital landscape", 22],
      ["Content that earns attention", 26],
      ["Paid campaigns on a birr budget", 24],
      ["Analytics without vanity metrics", 20],
      ["Project: a 30-day campaign plan", 30]
    ],
    quiz: [
      { q: "What does CTR measure?", options: ["Cost per transaction", "Clicks divided by impressions", "Customer retention", "Conversion timing"], answer: 1 },
      { q: "A 'vanity metric' is best described as what?", options: ["A number that looks good but drives no decision", "Any number from social media", "Revenue", "Bounce rate"], answer: 0 },
      { q: "Organic reach means traffic that comes from what?", options: ["Paid ads", "Unpaid search and shares", "Email lists only", "Print media"], answer: 1 }
    ]
  },
  {
    slug: "graphic-design-foundations",
    title: "Graphic Design Foundations",
    subtitle: "Layout, color and type for brands people trust",
    description:
      "Design fundamentals with critique, not just tools. Learn composition, typography and color theory, then apply them in Figma to real briefs: a business card, a flyer, and a full brand mini-identity for a fictional Ethiopian coffee brand. Every assignment gets written instructor feedback.",
    category: "Design",
    level: "beginner",
    priceCents: 0,
    hours: 20,
    lessons: [
      ["What design actually is", 16],
      ["Composition and the grid", 24],
      ["Typography: choosing and pairing type", 28],
      ["Color theory for brands", 22],
      ["Designing in Figma, efficiently", 26],
      ["Project: a brand mini-identity", 34]
    ],
    quiz: [
      { q: "Kerning adjusts the space between what?", options: ["Lines of text", "Individual letter pairs", "Paragraphs", "Columns"], answer: 1 },
      { q: "Which pairing is generally easiest to read for body text?", options: ["Decorative serif at 10px", "Clean sans-serif at 14-16px", "All caps everywhere", "Handwriting font"], answer: 1 },
      { q: "A 'grid' in layout design primarily provides what?", options: ["Color harmony", "Consistent alignment and rhythm", "Faster exports", "Better kerning"], answer: 1 }
    ]
  },
  {
    slug: "amharic-for-the-diaspora",
    title: "Amharic for the Diaspora",
    subtitle: "Speak, read and write the language of home",
    description:
      "For Ethiopians abroad who grew up understanding but never studying Amharic. Rebuild the foundation: the fidal alphabet, everyday conversation, reading practice with real texts, and writing that survives a WhatsApp message to family. Taught with patience and zero judgment.",
    category: "Language",
    level: "beginner",
    priceCents: 90000,
    hours: 24,
    lessons: [
      ["Welcome home: sounds and greetings", 20],
      ["The fidal alphabet, part 1", 30],
      ["The fidal alphabet, part 2", 28],
      ["Everyday conversation for real life", 26],
      ["Reading practice with real texts", 24],
      ["Writing: from text messages to letters", 22]
    ],
    quiz: [
      { q: "How many base characters does the main fidel alphabet traditionally list?", options: ["26", "33", "44", "52"], answer: 1 },
      { q: "Which is the standard way to say hello in Amharic?", options: ["Ciao", "Selam", "Salam alaikum only", "Merci"], answer: 1 },
      { q: "Amharic script reads in which direction?", options: ["Right to left", "Left to right", "Top to bottom", "Either"], answer: 1 }
    ]
  },
  {
    slug: "advanced-typescript-apis",
    title: "Advanced TypeScript and API Design",
    subtitle: "Types, patterns and REST APIs that scale",
    description:
      "For working developers who want senior-level confidence. Deep TypeScript: generics, narrowing, utility types and the patterns that make refactors safe. Then API design: validation, error contracts, pagination and auth, taught through building a real service end to end.",
    category: "Technology",
    level: "advanced",
    priceCents: 250000,
    hours: 22,
    lessons: [
      ["Type system fundamentals revisited", 24],
      ["Generics without the headache", 30],
      ["Narrowing and type guards", 26],
      ["Designing error contracts", 22],
      ["Validation at the boundary", 24],
      ["Project: an API end to end", 36]
    ],
    quiz: [
      { q: "What does the TypeScript 'unknown' type enforce before use?", options: ["Nothing, like any", "Type checking or narrowing before use", "Null checks only", "Runtime validation"], answer: 1 },
      { q: "A REST API should return which status for a successful creation?", options: ["200", "201", "204", "302"], answer: 1 },
      { q: "'Partial<T>' does what?", options: ["Removes required keys", "Makes all properties optional", "Freezes the type", "Converts to strings"], answer: 1 },
      { q: "Which is the safest default for validating external API input?", options: ["Trust it", "Validate at the boundary", "Cast to any", "Disable strict mode"], answer: 1 }
    ]
  }
];

async function main() {
  const count = await prisma.user.count();
  if (count > 0) {
    console.log("Database already seeded (users exist). Skipping.");
    return;
  }

  await prisma.user.create({
    data: {
      name: "Academy Admin",
      email: "admin@temari.academy",
      passwordHash: hashPassword("admin-pass-2026"),
      role: "admin"
    }
  });

  const demo = [
    { name: "Daniel Tadesse", email: "daniel@temari.academy", pass: "demo-pass-2026" },
    { name: "Meron Solomon", email: "meron@temari.academy", pass: "demo-pass-2026" },
    { name: "Kalkidan Bekele", email: "kalkidan@temari.academy", pass: "demo-pass-2026" }
  ];
  const students = [];
  for (const d of demo) {
    students.push(
      await prisma.user.create({
        data: { name: d.name, email: d.email, passwordHash: hashPassword(d.pass), role: "student" }
      })
    );
  }

  for (const c of COURSES) {
    const course = await prisma.course.create({
      data: {
        slug: c.slug,
        title: c.title,
        subtitle: c.subtitle,
        description: c.description,
        category: c.category,
        level: c.level,
        priceCents: c.priceCents,
        hours: c.hours,
        published: true,
        quizJson: JSON.stringify(c.quiz)
      }
    });
    for (let i = 0; i < c.lessons.length; i++) {
      await prisma.lesson.create({
        data: {
          courseId: course.id,
          idx: i + 1,
          title: c.lessons[i][0],
          minutes: c.lessons[i][1]
        }
      });
    }
  }

  // Give the demo students some progress so the dashboard is not empty.
  const daniel = students[0];
  const meron = students[1];
  const webCourse = await prisma.course.findUnique({ where: { slug: "modern-web-development" }, include: { lessons: true } });
  const excel = await prisma.course.findUnique({ where: { slug: "data-analysis-excel" }, include: { lessons: true } });

  await prisma.enrollment.create({ data: { userId: daniel.id, courseId: webCourse.id } });
  await prisma.enrollment.create({ data: { userId: meron.id, courseId: webCourse.id } });
  await prisma.enrollment.create({ data: { userId: meron.id, courseId: excel.id } });

  const webLessons = webCourse.lessons.slice(0, 5);
  for (const l of webLessons) {
    await prisma.lessonProgress.create({ data: { userId: daniel.id, lessonId: l.id } });
  }
  for (const l of webCourse.lessons) {
    await prisma.lessonProgress.create({ data: { userId: meron.id, lessonId: l.id } });
  }
  const webQuiz = c_quizLength(webCourse.slug);
  await prisma.quizResult.create({
    data: { userId: meron.id, courseId: webCourse.id, score: Math.ceil(webQuiz * 0.8), total: webQuiz, passed: true }
  });

  console.log("Seeded: 1 admin, 3 demo students, 6 courses with lessons and quizzes.");
}

function c_quizLength(slug) {
  const c = COURSES.find((x) => x.slug === slug);
  return c ? c.quiz.length : 0;
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
TA_EOF
echo "wrote prisma/seed.mjs"
mkdir -p "$(dirname "README.md")"
cat > "README.md" <<'TA_EOF'
# Temari Academy

A bold, modern learning platform for a fictional Ethiopian online academy.
Students browse a course catalog, enroll, track per-lesson progress, pass a
final quiz and earn a certificate; admins manage the catalog, students and
messages from a console. "Temari" means student.

Fictional portfolio project by Daniel Tadesse. All people, stats and
testimonials are invented for demonstration.

## Stack

- Next.js 14 (App Router) + TypeScript
- Prisma + SQLite
- No other runtime dependencies

## Quick start

Run from inside the project folder:

    npm install
    cp .env.example .env
    npx prisma db push
    npm run db:seed
    npm run dev

Then open http://localhost:3000

## Demo accounts (created by the seed)

    admin@temari.academy / admin-pass-2026  (admin console)
    daniel@temari.academy  / demo-pass-2026 (mid-progress student)
    meron@temari.academy   / demo-pass-2026 (completed a course + passed quiz)
    kalkidan@temari.academy / demo-pass-2026 (fresh account, no enrollments)

Sign up any time - new accounts are free students and start with an empty
dashboard.

## What is inside

- Public site: home (hero, animated stats, newest courses, testimonials),
  catalog with search + category filter, course detail pages, about, contact.
- Accounts: signup, login, logout. Passwords are scrypt-hashed; sessions are
  HMAC-signed httpOnly cookies (8h). Login is rate limited (5 per 15 min).
- Student portal (/dashboard): enrolled courses with live progress, the
  learn page (/dashboard/[slug]) with lesson list, mark-complete, final quiz
  graded on the server, and a certificate panel with a code once every lesson
  is done and the quiz is passed.
- Admin console (/admin, admin role only): overview stats, catalog management
  (create / publish / hide / delete - delete blocked while students are
  enrolled), students table with progress analytics, contact inbox.
- Contact API: server-side validation, honeypot anti-spam, 5-per-15-minute
  in-memory rate limit, readable errors (including a "run npx prisma db push"
  hint on a fresh install).

## Design notes

- Bold dark-first theme: violet-black base, vivid violet-to-pink gradient
  accents, plus a light mode toggle (persisted in localStorage, no flash on
  load thanks to a pre-paint init script).
- Full-width layout; sticky header and footer.
- Pure CSS + inline SVG throughout; no icon or animation packages.
- Animated hero grid glow, count-up stats, hover lift on cards;
  prefers-reduced-motion disables all animation.

## Security notes

- Quiz answers are never sent to the browser; grading and pass thresholds
  live entirely on the server.
- All state-changing APIs require a valid session; admin APIs require the
  admin role and return plain, readable JSON errors.
- Authenticated pages are served with Cache-Control: no-store so the back
  button after logout never shows a stale dashboard.

## Portfolio context

This is project 5 of 5 fictional businesses:

1. Debre Logistics - freight management platform
2. BirrPay - payments dashboard with 2FA
3. Kaffa Origins - Ethiopian coffee e-commerce
4. Abrot Cyber - cybersecurity consultancy
5. Temari Academy - this project
TA_EOF
echo "wrote README.md"
mkdir -p "$(dirname "tsconfig.json")"
cat > "tsconfig.json" <<'TA_EOF'
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
TA_EOF
echo "wrote tsconfig.json"

echo ""
echo "=============================================="
echo " Temari Academy project created."
echo " Next steps:"
echo "   cd temari-academy"
echo "   npm install"
echo "   cp .env.example .env"
echo "   npx prisma db push"
echo "   npm run db:seed"
echo "   npm run dev"
echo " Then open http://localhost:3000"
echo " Demo accounts (from the seed):"
echo "   admin@temari.academy / admin-pass-2026 (admin)"
echo "   daniel@temari.academy  / demo-pass-2026 (student)"
echo "   meron@temari.academy   / demo-pass-2026 (student)"
echo "   kalkidan@temari.academy / demo-pass-2026 (student)"
echo "=============================================="