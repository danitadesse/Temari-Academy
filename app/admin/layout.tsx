import { redirect } from "next/navigation";
import { getAuth } from "../../lib/auth";
import AdminNav from "../../components/AdminNav";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const user = await getAuth();
  if (!user) redirect("/login?next=/admin");
  if (user.role !== "admin") redirect("/dashboard");

  return (
    <>
      <AdminNav unread={0} />
      <div className="wrap section">
        <div className="page-head">
          <div>
            <h1><span className="grad-text">Admin</span> console</h1>
            <p className="sub">Signed in as {user.name} ({user.email}).</p>
          </div>
        </div>
        {children}
      </div>
    </>
  );
}
