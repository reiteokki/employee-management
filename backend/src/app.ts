import express, { Application, Request, Response } from "express";
import dotenv from "dotenv";
import authRoutes from "./routes/auth";
import membersRoutes from "./routes/members";
import superiorsRoutes from "./routes/superiors";
import cors from "cors";

dotenv.config();

const app: Application = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/members", membersRoutes);
app.use("/api/superiors", superiorsRoutes);

app.get("/", (req: Request, res: Response) => {
  res.send("Backend is running");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
