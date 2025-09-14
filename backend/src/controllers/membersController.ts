import { Request, Response } from "express";
import pool from "../db";
import { Member } from "../types/member";
import {
  createMember,
  getHierarchyService,
  getMemberByIdService,
  hardDeleteMemberService,
  patchMemberService,
  softDeleteMemberService,
} from "../services/membersService";
import { AuthenticatedRequest } from "../middlewares/authMiddleware";

export async function getMembers(req: Request, res: Response) {
  try {
    const [rows] = await pool.query("SELECT * FROM data_member");
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Database error" });
  }
}

export const addMember = async (req: Request, res: Response) => {
  try {
    const member: Member = req.body;

    if (
      !member.m_branch_id ||
      !member.m_rep_id ||
      !member.m_name ||
      !member.m_current_position ||
      !member.m_manager_id
    ) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const result = await createMember(member);
    res.status(201).json({ message: "Member created", result });
  } catch (err) {
    console.error("Error creating member:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getMembersHierarchy = async (req: Request, res: Response) => {
  try {
    const result = await getHierarchyService();
    res.json(result);
  } catch (err) {
    console.error("Error fetching hierarchy:", err);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getMemberById = async (req: Request, res: Response) => {
  try {
    const rows = await getMemberByIdService(req.params.id);
    if (!rows || (Array.isArray(rows) && rows.length === 0)) {
      return res.status(404).json({ message: "Member not found" });
    }
    res.json(rows[0]);
  } catch (err) {
    console.error("Get member error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

export const patchMember = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;

    if (req.user.role !== "GEPD" && req.user.m_rep_id !== id) {
      return res.status(403).json({ message: "Forbidden: insufficient role" });
    }

    const result = await patchMemberService(id, req.body);
    if (!result) {
      return res.status(400).json({ message: "No fields provided" });
    }

    res.json({ message: "Member updated", result });
  } catch (err) {
    console.error("Patch update error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

export const softDeleteMember = async (
  req: AuthenticatedRequest,
  res: Response
) => {
  try {
    if (req.user.role !== "GEPD") {
      return res
        .status(403)
        .json({ message: "Forbidden: only GEPD can delete" });
    }

    const result = await softDeleteMemberService(req.params.id);
    res.json({ message: "Member soft-deleted", result });
  } catch (err) {
    console.error("Soft delete error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

export const hardDeleteMember = async (
  req: AuthenticatedRequest,
  res: Response
) => {
  try {
    if (req.user.role !== "GEPD") {
      return res
        .status(403)
        .json({ message: "Forbidden: only GEPD can delete" });
    }

    const result = await hardDeleteMemberService(req.params.id);
    res.json({ message: "Member deleted", result });
  } catch (err) {
    console.error("Delete error:", err);
    res.status(500).json({ message: "Server error" });
  }
};
