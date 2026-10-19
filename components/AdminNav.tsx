"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const LINKS = [
  { href: "/admin", label: "Overview" },
  { href: "/admin/courses", label: "Courses" },
  { href: "/admin/students", label: "Students" },
  { href: "/admin/messages", label: "Messages" }
];

export default function AdminNav({ unread }: { unread: number }) {
  const path = usePathname();
  return (
    <nav className="admin-nav">
      <div className="wrap">
        {LINKS.map((l) => {
          const active = l.href === "/admin" ? path === "/admin" : path.startsWith(l.href);
          return (
            <Link key={l.href} href={l.href} className={"admin-tab" + (active ? " active" : "")}>
              {l.label}
              {l.href === "/admin/messages" && unread > 0 && (
                <span className="chip vivid" style={{ marginLeft: 8 }}>{unread}</span>
              )}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
