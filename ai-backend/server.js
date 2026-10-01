import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import Groq from "groq-sdk";

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 3000);

if (!process.env.GROQ_API_KEY) {
  console.error("GROQ_API_KEY is missing from .env");
  process.exit(1);
}

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

app.use(cors());
app.use(express.json());

// test route
app.get("/health", (req, res) => {
  res.json({
    success: true,
    message: "EduPro Groq AI backend is running",
  });
});

// AI chat route
app.post("/api/chat", async (req, res) => {
  try {
    const { messages } = req.body;

    if (!Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Messages are required",
      });
    }

    const cleanMessages = messages
      .filter(
        (message) =>
          message &&
          typeof message.content === "string" &&
          message.content.trim() !== "",
      )
      .slice(-20)
      .map((message) => ({
        role: message.role === "assistant" ? "assistant" : "user",
        content: message.content.trim(),
      }));

    const completion = await groq.chat.completions.create({
      model: "openai/gpt-oss-120b",

      messages: [
        {
          role: "system",
          content: `
You are EduPro AI Tutor.

Help students learn clearly.

Rules:
- Explain in simple language.
- Explain step by step.
- Give examples when useful.
- For programming questions, explain the code.
- For mathematics, show calculation steps.
- Use previous conversation messages for context.
- Keep answers educational and clear.
          `.trim(),
        },
        ...cleanMessages,
      ],

      temperature: 0.5,
      max_completion_tokens: 1200,
    });

    const answer = completion.choices?.[0]?.message?.content?.trim();

    if (!answer) {
      return res.status(500).json({
        success: false,
        message: "AI returned an empty answer",
      });
    }

    res.json({
      success: true,
      answer: answer,
    });
  } catch (error) {
    console.error("GROQ AI ERROR:", error);

    res.status(500).json({
      success: false,
      message: "Could not get AI response",
      error: error?.message,
    });
  }
});

app.listen(port, "0.0.0.0", () => {
  console.log(`EduPro Groq AI backend running on port ${port}`);
});
