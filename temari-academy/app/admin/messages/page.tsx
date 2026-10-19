import MessageActions from "./MessageActions";
import { prisma } from "../../../lib/prisma";

export default async function AdminMessagesPage() {
  const messages = await prisma.contactMessage.findMany({
    orderBy: { createdAt: "desc" },
    take: 100
  });

  return (
    <MessageActions
      messages={messages.map((m) => ({
        id: m.id,
        name: m.name,
        email: m.email,
        topic: m.topic,
        body: m.body,
        createdAt: m.createdAt.toISOString().slice(0, 10)
      }))}
    />
  );
}
