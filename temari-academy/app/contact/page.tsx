import type { Metadata } from "next";
import ContactForm from "./ContactForm";
import { COMPANY } from "../../lib/content";
import { getAuth } from "../../lib/auth";

export const metadata: Metadata = {
  title: "Contact - Temari Academy",
  description: "Questions about courses, teaching or partnerships at Temari Academy."
};

export default async function ContactPage() {
  const user = await getAuth();
  return (
    <div className="wrap section">
      <div className="page-head">
        <div>
          <h1>Contact</h1>
          <p className="sub">We answer within one business day.</p>
        </div>
      </div>
      <div className="grid-2">
        <ContactForm
          signedIn={!!user}
          defaultName={user?.name ?? ""}
          defaultEmail={user?.email ?? ""}
        />
        <div className="panel" style={{ marginBottom: 0 }}>
          <div className="panel-head"><h2>Other ways to reach us</h2></div>
          <div className="panel-body">
            <p className="sub">General questions</p>
            <p className="mono">{COMPANY.email}</p>
            <p className="sub" style={{ marginTop: 14 }}>Phone (office hours, EAT)</p>
            <p className="mono">{COMPANY.phone}</p>
            <p className="sub" style={{ marginTop: 14 }}>Office</p>
            <p>{COMPANY.city}</p>
            <p className="sub" style={{ marginTop: 14 }}>
              Want to teach with us? Mention your field and a link to your work -
              we review every instructor application ourselves.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
