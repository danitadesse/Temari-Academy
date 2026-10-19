import type { Metadata } from "next";
import "./globals.css";
import SiteHeader from "../components/SiteHeader";
import SiteFooter from "../components/SiteFooter";
import { getAuth } from "../lib/auth";

export const metadata: Metadata = {
  title: "Temari Academy - Learn skills that get you hired in Ethiopia",
  description:
    "Technology, business, design and language courses taught by Ethiopian professionals. Portfolio-first learning in Amharic or English."
};

// Runs before first paint so a saved light theme never flashes dark.
const themeInit = `(function(){try{var t=localStorage.getItem("temari-theme");if(t==="light"){document.documentElement.setAttribute("data-theme","light");}}catch(e){}})();`;

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const user = await getAuth();
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInit }} />
      </head>
      <body>
        <SiteHeader
          signedIn={!!user}
          userName={user?.name ?? ""}
          isAdmin={user?.role === "admin"}
        />
        <main>{children}</main>
        <SiteFooter />
      </body>
    </html>
  );
}
