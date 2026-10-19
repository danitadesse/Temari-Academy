import { NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";
import { getAuth } from "../../../../lib/auth";
import { LEVELS, CATEGORIES } from "../../../../lib/clientConstants";

export async function POST(req: Request) {
  const user = await getAuth();
  if (!user || user.role !== "admin") {
    return NextResponse.json({ error: "Admin access required." }, { status: 403 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid request body." }, { status: 400 });
  }

  const action = String(body.action || "");

  if (action === "create") {
    const title = String(body.title || "").trim();
    const slug = String(body.slug || "").trim();
    const subtitle = String(body.subtitle || "").trim();
    const category = String(body.category || "");
    const level = String(body.level || "");
    const priceBirr = Math.max(0, Math.floor(Number(body.priceBirr) || 0));
    const hours = Math.max(0, Math.floor(Number(body.hours) || 0));

    if (!title || title.length > 120) {
      return NextResponse.json({ error: "Title is required (max 120 characters)." }, { status: 400 });
    }
    if (!/^[a-z0-9-]+$/.test(slug) || slug.length > 80) {
      return NextResponse.json({ error: "Slug must be lowercase letters, digits and dashes." }, { status: 400 });
    }
    if (!CATEGORIES.includes(category as (typeof CATEGORIES)[number])) {
      return NextResponse.json({ error: "Invalid category." }, { status: 400 });
    }
    if (!LEVELS.includes(level as (typeof LEVELS)[number])) {
      return NextResponse.json({ error: "Invalid level." }, { status: 400 });
    }

    try {
      const dup = await prisma.course.findUnique({ where: { slug } });
      if (dup) {
        return NextResponse.json({ error: "A course with this slug already exists." }, { status: 409 });
      }
      await prisma.course.create({
        data: {
          title, slug, subtitle, category, level,
          description: subtitle || "Course description coming soon.",
          priceCents: priceBirr * 100,
          hours,
          published: true,
          quizJson: "[]"
        }
      });
      return NextResponse.json({ ok: true, message: "Course created and published." });
    } catch {
      return NextResponse.json(
        { error: "Could not create the course. If this is a fresh install, run: npx prisma db push" },
        { status: 500 }
      );
    }
  }

  const id = Number(body.id);
  if (!Number.isInteger(id) || id <= 0) {
    return NextResponse.json({ error: "Invalid course id." }, { status: 400 });
  }
  const course = await prisma.course.findUnique({
    where: { id },
    include: { enrollments: true }
  });
  if (!course) {
    return NextResponse.json({ error: "Course not found." }, { status: 404 });
  }

  if (action === "toggle") {
    try {
      await prisma.course.update({ where: { id }, data: { published: !course.published } });
      return NextResponse.json({
        ok: true,
        message: course.published ? "Course hidden from the catalog." : "Course published."
      });
    } catch {
      return NextResponse.json({ error: "Could not update the course." }, { status: 500 });
    }
  }

  if (action === "delete") {
    if (course.enrollments.length > 0) {
      return NextResponse.json(
        { error: "Cannot delete: " + course.enrollments.length + " student(s) are enrolled. Hide it instead." },
        { status: 409 }
      );
    }
    try {
      await prisma.course.delete({ where: { id } });
      return NextResponse.json({ ok: true, message: "Course deleted." });
    } catch {
      return NextResponse.json({ error: "Could not delete the course." }, { status: 500 });
    }
  }

  return NextResponse.json({ error: "Unknown action." }, { status: 400 });
}
