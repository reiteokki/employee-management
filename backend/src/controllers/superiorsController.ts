import { Request, Response } from "express";
import pool from "../db";

export async function getSuperiors(req: Request, res: Response) {
  try {
    const [rows] = await pool.query("SELECT * FROM data_superior");
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" });
  }
}
