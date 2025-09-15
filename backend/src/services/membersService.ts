import { RowDataPacket } from "mysql2";
import pool from "../db";
import { Member } from "../types/member";
import bcrypt from "bcryptjs";

export const createMember = async (member: Member) => {
  const defaultPassword = await bcrypt.hash("password", 10);

  const sql = `
    INSERT INTO data_member 
    (m_branch_id, m_rep_id, m_name, m_current_position, m_manager_id, password)
    VALUES (?, ?, ?, ?, ?, ?)
  `;

  const values = [
    member.m_branch_id,
    member.m_rep_id,
    member.m_name,
    member.m_current_position,
    member.m_manager_id,
    defaultPassword,
  ];

  const [result] = await pool.query(sql, values);
  return result;
};

export const getHierarchyService = async (): Promise<RowDataPacket[]> => {
  const [rows] = await pool.query<RowDataPacket[]>(`
    SELECT 
      m.m_rep_id as m_mst_id,
      g.m_rep_id AS mm_mst_gepd,
      g.m_name   AS NamaGEPD,
      e.m_rep_id AS m_mst_epd,
      e.m_name   AS NamaEPD,
      m.m_branch_id,
      m.m_name
    FROM data_member m
    JOIN data_superior e 
      ON m.m_manager_id = e.m_rep_id
    JOIN data_superior g 
      ON e.m_manager_id = g.m_rep_id
    WHERE m.deleted_at IS NULL
      AND e.deleted_at IS NULL
      AND g.deleted_at IS NULL
    ORDER BY g.m_name, e.m_name, m.m_name
  `);

  return rows;
};

export const getMemberByIdService = async (
  id: string
): Promise<RowDataPacket[]> => {
  const [rows] = await pool.query<RowDataPacket[]>(
    `SELECT *
FROM (
    SELECT m_branch_id, m_rep_id, m_name, m_current_position, m_manager_id, password, 'superior' AS role
    FROM data_superior
    WHERE deleted_at IS NULL OR deleted_at IS NULL -- if you have soft delete later

    UNION ALL

    SELECT m_branch_id, m_rep_id, m_name, m_current_position, m_manager_id, password, 'member' AS role
    FROM data_member
    WHERE deleted_at IS NULL OR deleted_at IS NULL
) AS all_users
WHERE m_rep_id = ?`,
    [id]
  );
  return rows;
};

export const patchMemberService = async (id: string, fields: any) => {
  const keys = Object.keys(fields);
  if (keys.length === 0) return null;

  const setClause = keys.map((key) => `${key} = ?`).join(", ");
  const values = Object.values(fields);

  const [result] = await pool.query(
    `UPDATE data_member SET ${setClause} WHERE m_rep_id = ?`,
    [...values, id]
  );
  return result;
};

export const softDeleteMemberService = async (id: string) => {
  const [result] = await pool.query(
    `UPDATE data_member SET deleted_at = NOW() WHERE m_rep_id = ?`,
    [id]
  );
  return result;
};

export const hardDeleteMemberService = async (id: string) => {
  const [result] = await pool.query(
    `DELETE FROM data_member WHERE m_rep_id = ?`,
    [id]
  );
  return result;
};
