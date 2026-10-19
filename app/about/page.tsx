import type { Metadata } from "next";
import Link from "next/link";
import { COMPANY, TEAM } from "../../lib/content";

export const metadata: Metadata = {
  title: "About - Temari Academy",
  description: "The team behind Temari Academy, Ethiopia's fictional home of practical learning."
};

export default function AboutPage() {
  return (
    <div className="wrap section">
      <div className="page-head">
        <div>
          <h1>About {COMPANY.name}</h1>
          <p className="sub">
            Temari means student. We are a small team in {COMPANY.city} convinced
            that the gap between Ethiopian classrooms and Ethiopian job posts is a
            curriculum problem, not a talent problem. So we built the curriculum.
          </p>
        </div>
        <Link className="btn" href="/courses">See the courses</Link>
      </div>

      <div className="grid-3">
        {TEAM.map((m) => (
          <div className="card" key={m.name}>
            <div className="num-badge">{m.initials}</div>
            <h3>{m.name}</h3>
            <p className="sub">{m.role}</p>
            <p>{m.bio}</p>
          </div>
        ))}
      </div>

      <div className="panel" style={{ marginTop: 18 }}>
        <div className="panel-head"><h2>How a track works</h2></div>
        <div className="panel-body">
          <div className="grid-4">
            <div className="card" style={{ boxShadow: "none" }}>
              <div className="num-badge">01</div>
              <h3>Enroll</h3>
              <p>Create a free account and start any free course immediately. Paid tracks unlock with one payment.</p>
            </div>
            <div className="card" style={{ boxShadow: "none" }}>
              <div className="num-badge">02</div>
              <h3>Learn</h3>
              <p>Work through lessons at your pace. Progress is saved per lesson, so a 15-minute commute counts.</p>
            </div>
            <div className="card" style={{ boxShadow: "none" }}>
              <div className="num-badge">03</div>
              <h3>Prove it</h3>
              <p>Pass the final quiz and finish every lesson to unlock your certificate with a verifiable code.</p>
            </div>
            <div className="card" style={{ boxShadow: "none" }}>
              <div className="num-badge">04</div>
              <h3>Ship it</h3>
              <p>Graduates leave with a project built, reviewed and ready to show in an interview.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
