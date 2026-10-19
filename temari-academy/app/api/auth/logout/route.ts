import { NextResponse } from "next/server";
import { sessionCookieName } from "../../../../lib/auth";

// Handles both fetch() calls and the plain <form method="post"> in the
// header, so it always returns a redirect, never JSON.
export async function POST(req: Request) {
  const url = new URL("/login", req.url);
  const res = NextResponse.redirect(url, 303);
  res.cookies.set(sessionCookieName, "", {
    httpOnly: true,
    sameSite: "lax",
    path: "/",
    maxAge: 0
  });
  return res;
}
