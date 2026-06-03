import { Elysia } from "elysia";
import { cors } from "@elysiajs/cors";
import { swagger } from "@elysiajs/openapi";
import { healthcheckRoutes } from "./routes/healthcheck";

export const app = new Elysia()
  .use(cors())
  .use(swagger({
    documentation: {
      info: { title: "Face Recognition API", version: "1.0.0" },
    },
  }))
  .use(healthcheckRoutes)
  .get("/", () => ({ message: "Face Recognition API" }));

export type App = typeof app;
