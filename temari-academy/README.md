# Temari Academy

A bold, modern learning platform for a fictional Ethiopian online academy.
Students browse a course catalog, enroll, track per-lesson progress, pass a
final quiz and earn a certificate; admins manage the catalog, students and
messages from a console. "Temari" means student.

Fictional portfolio project by Daniel Tadesse. All people, stats and
testimonials are invented for demonstration.

## Stack

- Next.js 14 (App Router) + TypeScript
- Prisma + SQLite
- No other runtime dependencies

## Quick start

Run from inside the project folder:

    npm install
    cp .env.example .env
    npx prisma db push
    npm run db:seed
    npm run dev

Then open http://localhost:3000

## Demo accounts (created by the seed)

    admin@temari.academy / admin-pass-2026  (admin console)
    daniel@temari.academy  / demo-pass-2026 (mid-progress student)
    meron@temari.academy   / demo-pass-2026 (completed a course + passed quiz)
    kalkidan@temari.academy / demo-pass-2026 (fresh account, no enrollments)

Sign up any time - new accounts are free students and start with an empty
dashboard.

## What is inside

- Public site: home (hero, animated stats, newest courses, testimonials),
  catalog with search + category filter, course detail pages, about, contact.
- Accounts: signup, login, logout. Passwords are scrypt-hashed; sessions are
  HMAC-signed httpOnly cookies (8h). Login is rate limited (5 per 15 min).
- Student portal (/dashboard): enrolled courses with live progress, the
  learn page (/dashboard/[slug]) with lesson list, mark-complete, final quiz
  graded on the server, and a certificate panel with a code once every lesson
  is done and the quiz is passed.
- Admin console (/admin, admin role only): overview stats, catalog management
  (create / publish / hide / delete - delete blocked while students are
  enrolled), students table with progress analytics, contact inbox.
- Contact API: server-side validation, honeypot anti-spam, 5-per-15-minute
  in-memory rate limit, readable errors (including a "run npx prisma db push"
  hint on a fresh install).

## Design notes

- Bold dark-first theme: violet-black base, vivid violet-to-pink gradient
  accents, plus a light mode toggle (persisted in localStorage, no flash on
  load thanks to a pre-paint init script).
- Full-width layout; sticky header and footer.
- Pure CSS + inline SVG throughout; no icon or animation packages.
- Animated hero grid glow, count-up stats, hover lift on cards;
  prefers-reduced-motion disables all animation.

## Security notes

- Quiz answers are never sent to the browser; grading and pass thresholds
  live entirely on the server.
- All state-changing APIs require a valid session; admin APIs require the
  admin role and return plain, readable JSON errors.
- Authenticated pages are served with Cache-Control: no-store so the back
  button after logout never shows a stale dashboard.

## Portfolio context

This is project 5 of 5 fictional businesses:

1. Debre Logistics - freight management platform
2. BirrPay - payments dashboard with 2FA
3. Kaffa Origins - Ethiopian coffee e-commerce
4. Abrot Cyber - cybersecurity consultancy
5. Temari Academy - this project
