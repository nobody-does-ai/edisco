"use client";
import React, { useEffect } from "react";
import Chat from "./chat";
import useConversationStore from "@/stores/useConversationStore";
import { Item, processMessages } from "@/lib/assistant";

const saveMessages = async (messages: { role: string; content: any; metadata?: any }[]) => {
  try {
    await fetch("/api/conversation", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ messages }),
    });
  } catch (error) {
    console.error("Error saving to postgres:", error);
  }
};

export default function Assistant() {
  const {
    chatMessages,
    conversationItems,
    addConversationItem,
    addChatMessage,
    setChatMessages,
    setConversationItems,
    setAssistantLoading,
  } = useConversationStore();

  // Hydrate conversation from postgres on mount
  useEffect(() => {
    const loadConversation = async () => {
      try {
        const res = await fetch("/api/conversation");
        const { messages } = await res.json();
        if (messages && messages.length > 0) {
          const chatItems: Item[] = messages.map((m: any) => ({
            type: "message",
            role: m.role,
            content: Array.isArray(m.content) ? m.content : [{ type: m.role === "user" ? "input_text" : "output_text", text: m.content }],
          }));
          const convItems = messages.map((m: any) => ({
            role: m.role,
            content: Array.isArray(m.content) ? m.content : m.content,
          }));
          setChatMessages(chatItems);
          setConversationItems(convItems);
        }
      } catch (error) {
        console.error("Error loading conversation:", error);
      }
    };
    loadConversation();
  }, [setChatMessages, setConversationItems]);

  const handleSendMessage = async (message: string) => {
    if (!message.trim()) return;

    const userItem: Item = {
      type: "message",
      role: "user",
      content: [{ type: "input_text", text: message.trim() }],
    };
    const userMessage: any = {
      role: "user",
      content: message.trim(),
    };

    try {
      setAssistantLoading(true);
      addConversationItem(userMessage);
      addChatMessage(userItem);

      // Save user message to postgres
      await saveMessages([{ role: "user", content: message.trim() }]);

      await processMessages();
    } catch (error) {
      console.error("Error processing message:", error);
      const errText = `Message error: ${error instanceof Error ? error.message : String(error)}`;
      saveMessages([{ role: "system", content: errText, metadata: { type: "error" } }]);
    }
  };

  const handleApprovalResponse = async (
    approve: boolean,
    id: string
  ) => {
    const approvalItem = {
      type: "mcp_approval_response",
      approve,
      approval_request_id: id,
    } as any;
    try {
      addConversationItem(approvalItem);
      await processMessages();
    } catch (error) {
      console.error("Error sending approval response:", error);
    }
  };

  return (
    <div className="h-full p-4 w-full bg-white">
      <Chat
        items={chatMessages}
        onSendMessage={handleSendMessage}
        onApprovalResponse={handleApprovalResponse}
      />
    </div>
  );
}
