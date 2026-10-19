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
