// Server-only auth utilities. Client components must NEVER import this file
// (it uses node:crypto and prisma). Client-safe values live in
// lib/clientConstants.ts.

import { createHmac, randomBytes, scryptSync, timingSafeEqual } from "crypto";
import { cookies } from "next/headers";
import { prisma } from "./prisma";

const SECRET = process.env.SESSION_SECRET || "temari-dev-secret-change-me";
const COOKIE_NAME = "temari_session";
const SESSION_HOURS = 8;

export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString("hex");
  const hash = scryptSync(password, salt, 64).toString("hex");
  return salt + ":" + hash;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [salt, hash] = stored.split(":");
  if (!salt || !hash) return false;
  const candidate = scryptSync(password, salt, 64);
  const expected = Buffer.from(hash, "hex");
  if (candidate.length !== expected.length) return false;
  return timingSafeEqual(candidate, expected);
}

function sign(payload: string): string {
  return createHmac("sha256", SECRET).update(payload).digest("hex");
}

export function createSessionToken(userId: number): string {
  const exp = Date.now() + SESSION_HOURS * 3600 * 1000;
  const payload = userId + "." + exp;
  return payload + "." + sign(payload);
}

export function parseSessionToken(token: string | undefined): number | null {
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const [id, exp, sig] = parts;
  const payload = id + "." + exp;
  const expected = sign(payload);
  if (
    sig.length !== expected.length ||
    !timingSafeEqual(Buffer.from(sig), Buffer.from(expected))
  ) {
    return null;
  }
  if (Number(exp) < Date.now()) return null;
  const userId = Number(id);
  return Number.isInteger(userId) && userId > 0 ? userId : null;
}

export type SessionUser = {
  id: number;
  name: string;
  email: string;
  role: string;
};

export async function getAuth(): Promise<SessionUser | null> {
  const store = cookies();
  const userId = parseSessionToken(store.get(COOKIE_NAME)?.value);
  if (userId === null) return null;
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, name: true, email: true, role: true }
  });
  return user ?? null;
}

export const sessionCookieName = COOKIE_NAME;
export const sessionMaxAge = SESSION_HOURS * 3600; // seconds, for cookie options
