import { Elysia } from "elysia";

export const healthcheckRoutes = new Elysia({ prefix: "/api/healthcheck" })
  .get("/", () => ({ status: "ok", timestamp: new Date().toISOString() }));
