// Temari Academy seed. Plain ESM JavaScript so it runs with plain
// "node prisma/seed.mjs" - no extra dependencies.
// Password hashing mirrors lib/auth.ts: scryptSync(password, salt, 64).

import { PrismaClient } from "@prisma/client";
import { randomBytes, scryptSync } from "node:crypto";

const prisma = new PrismaClient();

function hashPassword(password) {
  const salt = randomBytes(16).toString("hex");
  const hash = scryptSync(password, salt, 64).toString("hex");
  return salt + ":" + hash;
}

const COURSES = [
  {
    slug: "modern-web-development",
    title: "Modern Web Development",
    subtitle: "HTML, CSS, JavaScript and React, from zero to portfolio",
    description:
      "The full track that took our graduates from zero to hired. Start with the web platform fundamentals, work through real JavaScript, then build and deploy two portfolio projects with React: a business landing page and a small dashboard consuming a real API. Every project is reviewed against a checklist used by Ethiopian tech recruiters.",
    category: "Technology",
    level: "beginner",
    priceCents: 0,
    hours: 32,
    lessons: [
      ["How the web actually works", 14],
      ["HTML that means something", 22],
      ["CSS layout without fear: flex and grid", 28],
      ["JavaScript fundamentals, part 1", 26],
      ["JavaScript fundamentals, part 2", 24],
      ["Working with APIs and JSON", 20],
      ["React components and state", 30],
      ["Portfolio project: build and deploy", 35]
    ],
    quiz: [
      { q: "Which HTTP status code means 'not found'?", options: ["200", "301", "404", "500"], answer: 2 },
      { q: "In CSS, which property controls the space BETWEEN elements in a flex row?", options: ["padding", "margin", "gap", "space"], answer: 2 },
      { q: "What does JSON.parse do?", options: ["Converts a string into an object", "Converts an object into a string", "Validates JSON syntax only", "Sends a request"], answer: 0 },
      { q: "In React, state that changes should trigger a re-render. Which hook holds it?", options: ["useMemo", "useState", "useRef", "useId"], answer: 1 },
      { q: "Which tag gives a page its visible title in the browser tab?", options: ["<meta>", "<h1>", "<title>", "<header>"], answer: 2 }
    ]
  },
  {
    slug: "data-analysis-excel",
    title: "Data Analysis with Excel",
    subtitle: "From monthly reports to decisions your manager actually uses",
    description:
      "Built for the spreadsheets Ethiopian offices really run on. Master lookups, pivot tables and charts with local business data, then automate the monthly reporting pack you already hate. The final project is a full KPI dashboard for a fictional logistics company.",
    category: "Data",
    level: "beginner",
    priceCents: 150000,
    hours: 18,
    lessons: [
      ["Cell references and the magic of absolute refs", 15],
      ["VLOOKUP, XLOOKUP and why they differ", 22],
      ["Cleaning messy data properly", 25],
      ["Pivot tables for real reporting", 28],
      ["Charts that do not lie", 18],
      ["Project: a KPI dashboard from raw exports", 35]
    ],
    quiz: [
      { q: "Which reference stays fixed when copied down a column?", options: ["A1", "$A$1", "A$1 only", "A1$"], answer: 1 },
      { q: "A pivot table primarily does what?", options: ["Formats cells by color", "Summarizes and groups data", "Protects a sheet", "Merges workbooks"], answer: 1 },
      { q: "TRIM() in Excel removes what?", options: ["Duplicates", "Extra spaces around text", "Empty rows", "Formulas"], answer: 1 },
      { q: "Which chart is best for a trend over 12 months?", options: ["Pie", "Line", "Radar", "Scatter"], answer: 1 }
    ]
  },
  {
    slug: "digital-marketing-ethiopia",
    title: "Digital Marketing for the Ethiopian Market",
    subtitle: "Social, search and content that works with local audiences",
    description:
      "Marketing taught for businesses that sell in Addis, not Silicon Valley. Build a content calendar, run a real campaign budget in birr, learn the analytics that matter, and understand how customers actually discover and trust brands here. Final project: a 30-day campaign plan for a real or fictional local business.",
    category: "Business",
    level: "intermediate",
    priceCents: 200000,
    hours: 16,
    lessons: [
      ["Who is your customer, really?", 18],
      ["The Ethiopian digital landscape", 22],
      ["Content that earns attention", 26],
      ["Paid campaigns on a birr budget", 24],
      ["Analytics without vanity metrics", 20],
      ["Project: a 30-day campaign plan", 30]
    ],
    quiz: [
      { q: "What does CTR measure?", options: ["Cost per transaction", "Clicks divided by impressions", "Customer retention", "Conversion timing"], answer: 1 },
      { q: "A 'vanity metric' is best described as what?", options: ["A number that looks good but drives no decision", "Any number from social media", "Revenue", "Bounce rate"], answer: 0 },
      { q: "Organic reach means traffic that comes from what?", options: ["Paid ads", "Unpaid search and shares", "Email lists only", "Print media"], answer: 1 }
    ]
  },
  {
    slug: "graphic-design-foundations",
    title: "Graphic Design Foundations",
    subtitle: "Layout, color and type for brands people trust",
    description:
      "Design fundamentals with critique, not just tools. Learn composition, typography and color theory, then apply them in Figma to real briefs: a business card, a flyer, and a full brand mini-identity for a fictional Ethiopian coffee brand. Every assignment gets written instructor feedback.",
    category: "Design",
    level: "beginner",
    priceCents: 0,
    hours: 20,
    lessons: [
      ["What design actually is", 16],
      ["Composition and the grid", 24],
      ["Typography: choosing and pairing type", 28],
      ["Color theory for brands", 22],
      ["Designing in Figma, efficiently", 26],
      ["Project: a brand mini-identity", 34]
    ],
    quiz: [
      { q: "Kerning adjusts the space between what?", options: ["Lines of text", "Individual letter pairs", "Paragraphs", "Columns"], answer: 1 },
      { q: "Which pairing is generally easiest to read for body text?", options: ["Decorative serif at 10px", "Clean sans-serif at 14-16px", "All caps everywhere", "Handwriting font"], answer: 1 },
      { q: "A 'grid' in layout design primarily provides what?", options: ["Color harmony", "Consistent alignment and rhythm", "Faster exports", "Better kerning"], answer: 1 }
    ]
  },
  {
    slug: "amharic-for-the-diaspora",
    title: "Amharic for the Diaspora",
    subtitle: "Speak, read and write the language of home",
    description:
      "For Ethiopians abroad who grew up understanding but never studying Amharic. Rebuild the foundation: the fidal alphabet, everyday conversation, reading practice with real texts, and writing that survives a WhatsApp message to family. Taught with patience and zero judgment.",
    category: "Language",
    level: "beginner",
    priceCents: 90000,
    hours: 24,
    lessons: [
      ["Welcome home: sounds and greetings", 20],
      ["The fidal alphabet, part 1", 30],
      ["The fidal alphabet, part 2", 28],
      ["Everyday conversation for real life", 26],
      ["Reading practice with real texts", 24],
      ["Writing: from text messages to letters", 22]
    ],
    quiz: [
      { q: "How many base characters does the main fidel alphabet traditionally list?", options: ["26", "33", "44", "52"], answer: 1 },
      { q: "Which is the standard way to say hello in Amharic?", options: ["Ciao", "Selam", "Salam alaikum only", "Merci"], answer: 1 },
      { q: "Amharic script reads in which direction?", options: ["Right to left", "Left to right", "Top to bottom", "Either"], answer: 1 }
    ]
  },
  {
    slug: "advanced-typescript-apis",
    title: "Advanced TypeScript and API Design",
    subtitle: "Types, patterns and REST APIs that scale",
    description:
      "For working developers who want senior-level confidence. Deep TypeScript: generics, narrowing, utility types and the patterns that make refactors safe. Then API design: validation, error contracts, pagination and auth, taught through building a real service end to end.",
    category: "Technology",
    level: "advanced",
    priceCents: 250000,
    hours: 22,
    lessons: [
      ["Type system fundamentals revisited", 24],
      ["Generics without the headache", 30],
      ["Narrowing and type guards", 26],
      ["Designing error contracts", 22],
      ["Validation at the boundary", 24],
      ["Project: an API end to end", 36]
    ],
    quiz: [
      { q: "What does the TypeScript 'unknown' type enforce before use?", options: ["Nothing, like any", "Type checking or narrowing before use", "Null checks only", "Runtime validation"], answer: 1 },
      { q: "A REST API should return which status for a successful creation?", options: ["200", "201", "204", "302"], answer: 1 },
      { q: "'Partial<T>' does what?", options: ["Removes required keys", "Makes all properties optional", "Freezes the type", "Converts to strings"], answer: 1 },
      { q: "Which is the safest default for validating external API input?", options: ["Trust it", "Validate at the boundary", "Cast to any", "Disable strict mode"], answer: 1 }
    ]
  }
];

async function main() {
  const count = await prisma.user.count();
  if (count > 0) {
    console.log("Database already seeded (users exist). Skipping.");
    return;
  }

  await prisma.user.create({
    data: {
      name: "Academy Admin",
      email: "admin@temari.academy",
      passwordHash: hashPassword("admin-pass-2026"),
      role: "admin"
    }
  });

  const demo = [
    { name: "Daniel Tadesse", email: "daniel@temari.academy", pass: "demo-pass-2026" },
    { name: "Meron Solomon", email: "meron@temari.academy", pass: "demo-pass-2026" },
    { name: "Kalkidan Bekele", email: "kalkidan@temari.academy", pass: "demo-pass-2026" }
  ];
  const students = [];
  for (const d of demo) {
    students.push(
      await prisma.user.create({
        data: { name: d.name, email: d.email, passwordHash: hashPassword(d.pass), role: "student" }
      })
    );
  }

  for (const c of COURSES) {
    const course = await prisma.course.create({
      data: {
        slug: c.slug,
        title: c.title,
        subtitle: c.subtitle,
        description: c.description,
        category: c.category,
        level: c.level,
        priceCents: c.priceCents,
        hours: c.hours,
        published: true,
        quizJson: JSON.stringify(c.quiz)
      }
    });
    for (let i = 0; i < c.lessons.length; i++) {
      await prisma.lesson.create({
        data: {
          courseId: course.id,
          idx: i + 1,
          title: c.lessons[i][0],
          minutes: c.lessons[i][1]
        }
      });
    }
  }

  // Give the demo students some progress so the dashboard is not empty.
  const daniel = students[0];
  const meron = students[1];
  const webCourse = await prisma.course.findUnique({ where: { slug: "modern-web-development" }, include: { lessons: true } });
  const excel = await prisma.course.findUnique({ where: { slug: "data-analysis-excel" }, include: { lessons: true } });

  await prisma.enrollment.create({ data: { userId: daniel.id, courseId: webCourse.id } });
  await prisma.enrollment.create({ data: { userId: meron.id, courseId: webCourse.id } });
  await prisma.enrollment.create({ data: { userId: meron.id, courseId: excel.id } });

  const webLessons = webCourse.lessons.slice(0, 5);
  for (const l of webLessons) {
    await prisma.lessonProgress.create({ data: { userId: daniel.id, lessonId: l.id } });
  }
  for (const l of webCourse.lessons) {
    await prisma.lessonProgress.create({ data: { userId: meron.id, lessonId: l.id } });
  }
  const webQuiz = c_quizLength(webCourse.slug);
  await prisma.quizResult.create({
    data: { userId: meron.id, courseId: webCourse.id, score: Math.ceil(webQuiz * 0.8), total: webQuiz, passed: true }
  });

  console.log("Seeded: 1 admin, 3 demo students, 6 courses with lessons and quizzes.");
}

function c_quizLength(slug) {
  const c = COURSES.find((x) => x.slug === slug);
  return c ? c.quiz.length : 0;
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
