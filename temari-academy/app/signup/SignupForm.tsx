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
