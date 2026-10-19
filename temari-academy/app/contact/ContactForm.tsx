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
