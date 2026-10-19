// Shared marketing content for Temari Academy. Server-safe (no crypto,
// no prisma) so any component can import it.

export const COMPANY = {
  name: "Temari Academy",
  tagline: "Learn what employers actually hire for",
  city: "Addis Ababa, Ethiopia",
  email: "hello@temari.academy",
  phone: "+251 91 200 7700"
};

export const STATS = [
  { l: "Students enrolled", n: "8500+" },
  { l: "Courses taught in Amharic or English", n: "40+" },
  { l: "Completion rate", n: "72%" },
  { l: "Graduates hired or promoted", n: "310+" }
];

export const TESTIMONIALS = [
  {
    name: "Hanna G.",
    role: "Junior developer, Dashen Bank",
    quote:
      "I finished the web development track unemployed. Four months later I passed a technical interview. The final projects are what got me the job."
  },
  {
    name: "Abenezer T.",
    role: "Operations lead, a logistics firm",
    quote:
      "The Excel and data courses are taught with Ethiopian business examples, not Silicon Valley ones. I rebuilt our whole monthly reporting pack."
  },
  {
    name: "Sara M.",
    role: "Freelance designer",
    quote:
      "I started the design track for free while working a retail job. The portfolio review at the end was worth more than the certificate."
  }
];

export const WHY = [
  {
    title: "Built for the Ethiopian market",
    body:
      "Examples use local businesses, local data and the tools companies here actually run on - not generic US case studies."
  },
  {
    title: "Instructors who practice",
    body:
      "Every course is taught by someone doing the work professionally in the Ethiopian market right now, not a career video presenter."
  },
  {
    title: "Portfolio-first learning",
    body:
      "Each track ends with a real project reviewed by the instructor, so you finish with proof of skill, not just a certificate."
  },
  {
    title: "Learn in your language",
    body:
      "Courses are taught in Amharic, English or both, with captions, so nothing gets lost between the lesson and the exam."
  }
];

export const TEAM = [
  {
    name: "Liya Bekele",
    role: "Founder and CEO",
    bio: "Former curriculum lead at a national university. Started Temari because the best students she taught never got jobs without connections.",
    initials: "LB"
  },
  {
    name: "Samuel Wolde",
    role: "Head of Technology Tracks",
    bio: "Full-stack engineer by day, instructor by night. Has mentored 30 developers into their first jobs.",
    initials: "SW"
  },
  {
    name: "Bethlehem Alemu",
    role: "Head of Business Tracks",
    bio: "MBA, ex-bank analyst. Builds courses around the spreadsheets and reports Ethiopian offices really use.",
    initials: "BA"
  }
];
