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
