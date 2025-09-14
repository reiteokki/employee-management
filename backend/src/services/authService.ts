import pool from "../db";
import { RowDataPacket } from "mysql2";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "supersecretkey";
const REFRESH_SECRET = process.env.REFRESH_SECRET || "refreshsupersecret";

export const loginService = async (m_rep_id: string, password: string) => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT m_rep_id, password, m_name, m_current_position AS role
    FROM data_member
    WHERE m_rep_id = ? AND deleted_at IS NULL
    UNION
    SELECT m_rep_id, password, m_name, m_current_position AS role
    FROM data_superior
    WHERE m_rep_id = ?
    `,
    [m_rep_id, m_rep_id]
  );

  if (!rows || rows.length === 0) return null;

  const user = rows[0];

  const validPassword = await bcrypt.compare(password, user.password);
  if (!validPassword) return null;

  const payload = {
    m_rep_id: user.m_rep_id,
    name: user.m_name,
    role: user.role,
  };

  const token = jwt.sign(payload, JWT_SECRET, { expiresIn: "15m" });
  const refreshToken = jwt.sign(payload, REFRESH_SECRET, { expiresIn: "7d" });

  return { token, refreshToken, user: payload };
};
