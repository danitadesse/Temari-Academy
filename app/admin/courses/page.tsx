import { prisma } from "../../../lib/prisma";
import CourseEditor from "./CourseEditor";

export default async function AdminCoursesPage() {
  const courses = await prisma.course.findMany({
    orderBy: { createdAt: "desc" },
    include: { lessons: true, enrollments: true }
  });

  return (
    <CourseEditor
      courses={courses.map((c) => ({
        id: c.id,
        slug: c.slug,
        title: c.title,
        subtitle: c.subtitle,
        category: c.category,
        level: c.level,
        priceBirr: Math.floor(c.priceCents / 100),
        hours: c.hours,
        published: c.published,
        lessonCount: c.lessons.length,
        enrollmentCount: c.enrollments.length
      }))}
    />
  );
}
