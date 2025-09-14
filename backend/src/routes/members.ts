import { Router } from "express";
import {
  addMember,
  getMemberById,
  getMembers,
  getMembersHierarchy,
  hardDeleteMember,
  patchMember,
  softDeleteMember,
} from "../controllers/membersController";
import { verifyToken } from "../middlewares/authMiddleware";

const router = Router();

router.post("/", verifyToken, addMember);
router.get("/hierarchy", verifyToken, getMembersHierarchy);
router.get("/", verifyToken, getMembers);
router.get("/:id", verifyToken, getMemberById);
router.patch("/:id", verifyToken, patchMember);
router.patch("/:id/soft-delete", verifyToken, softDeleteMember);
router.delete("/:id", verifyToken, hardDeleteMember);

export default router;
