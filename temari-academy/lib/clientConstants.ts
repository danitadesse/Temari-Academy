// Client-safe constants and pure helpers. No crypto, no prisma here -
// safe to import from client components.

export const LEVELS = ["beginner", "intermediate", "advanced"] as const;

export const CATEGORIES = [
  "Technology",
  "Business",
  "Design",
  "Language",
  "Data"
] as const;

export const LEVEL_LABELS: Record<string, string> = {
  beginner: "Beginner",
  intermediate: "Intermediate",
  advanced: "Advanced"
};

export const TOPICS = [
  "Question about a course",
  "Teaching with us",
  "Partnership",
  "Something else"
] as const;

// ETB formatter: prices are integer cents everywhere.
export function etb(cents: number): string {
  const birr = Math.floor(cents / 100);
  return "ETB " + birr.toLocaleString("en-US");
}

// 0..1 progress fraction to a percent label.
export function pct(done: number, total: number): number {
  if (total <= 0) return 0;
  return Math.round((done / total) * 100);
}

export const QUIZ_PASS_FRACTION = 0.7;
