import type { Metadata } from "next";
import Link from "next/link";
import SignupForm from "./SignupForm";

export const metadata: Metadata = {
  title: "Join free - Temari Academy"
};

export default function SignupPage() {
  return (
    <div className="wrap section" style={{ maxWidth: 640 }}>
      <div className="page-head">
        <div>
          <h1>Create your account</h1>
          <p className="sub">Free forever for free courses. No card needed.</p>
        </div>
      </div>
      <SignupForm />
      <p className="sub">
        Already have an account? <Link href="/login">Sign in</Link>.
      </p>
    </div>
  );
}
