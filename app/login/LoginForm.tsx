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
