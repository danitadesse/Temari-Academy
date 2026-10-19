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
