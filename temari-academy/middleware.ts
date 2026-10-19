import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Never let the browser cache authenticated pages, so the back button
// after logout never shows a stale dashboard.
export function middleware(req: NextRequest) {
  const res = NextResponse.next();
  const path = req.nextUrl.pathname;
  if (path === "/dashboard" || path.startsWith("/dashboard/") || path === "/admin" || path.startsWith("/admin/")) {
    res.headers.set("Cache-Control", "no-store, must-revalidate");
  }
  return res;
}

export const config = {
  matcher: ["/dashboard/:path*", "/admin/:path*"]
};
