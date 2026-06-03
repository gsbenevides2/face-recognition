import { Elysia } from "elysia";
import { swagger } from "@elysiajs/openapi";
import { healthcheckRoutes } from "@/src/routes/healthcheck";

const app = new Elysia()
  .use(swagger({
    documentation: {
      info: { title: "Face Recognition API", version: "1.0.0" },
    },
  }))
  .use(healthcheckRoutes)
  .get("/", () => ({ message: "Face Recognition API" }));

export const GET = app.handle;
export const POST = app.handle;
export const PUT = app.handle;
export const DELETE = app.handle;
export const PATCH = app.handle;
