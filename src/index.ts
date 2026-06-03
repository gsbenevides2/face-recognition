import { Elysia } from "elysia";
import { healthcheckRoutes } from "./routes/healthcheck";

export const app = new Elysia()
  .use(healthcheckRoutes)
  .get("/", () => ({ message: "Face Recognition API" }));

export type App = typeof app;
