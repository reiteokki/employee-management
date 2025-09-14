import { Request, Response } from "express";
import jwt from "jsonwebtoken";
import { loginService } from "../services/authService";

export const login = async (req: Request, res: Response) => {
  try {
    const { m_rep_id, password } = req.body;
    if (!m_rep_id || !password) {
      return res
        .status(400)
        .json({ message: "m_rep_id and password are required" });
    }

    const result = await loginService(m_rep_id, password);
    if (!result) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    res.json(result);
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

const JWT_SECRET = process.env.JWT_SECRET || "supersecretkey";
const REFRESH_SECRET = process.env.REFRESH_SECRET || "refreshsupersecret";

export const refreshToken = (req: Request, res: Response) => {
  const { refreshToken } = req.body;

  if (!refreshToken)
    return res.status(401).json({ message: "Refresh token missing" });

  try {
    const decoded = jwt.verify(refreshToken, REFRESH_SECRET);

    const { m_rep_id, name, role } = decoded as any;
    const newToken = jwt.sign({ m_rep_id, name, role }, JWT_SECRET, {
      expiresIn: "15m",
    });

    res.json({ token: newToken });
  } catch (err) {
    console.error("Refresh token error:", err);
    return res.status(403).json({ message: "Invalid refresh token" });
  }
};
