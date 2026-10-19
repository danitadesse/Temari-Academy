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
