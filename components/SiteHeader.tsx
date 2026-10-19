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
