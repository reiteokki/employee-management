import { Router } from "express";
import { getSuperiors } from "../controllers/superiorsController";

const router = Router();

router.get("/", getSuperiors);

export default router;
