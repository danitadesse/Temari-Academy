import type { Metadata } from "next";
import { Suspense } from "react";
import LoginForm from "./LoginForm";

export const metadata: Metadata = {
  title: "Sign in - Temari Academy"
};

export default function LoginPage() {
  return (
    <div className="wrap section" style={{ maxWidth: 640 }}>
      <div className="page-head">
        <div>
          <h1>Sign in</h1>
          <p className="sub">Welcome back. Your progress is waiting where you left it.</p>
        </div>
      </div>
      <Suspense>
        <LoginForm />
      </Suspense>
    </div>
  );
}
