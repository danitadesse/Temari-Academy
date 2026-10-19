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
