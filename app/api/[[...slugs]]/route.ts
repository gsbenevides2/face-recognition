import { Elysia } from "elysia";
import { openapi } from "@elysiajs/openapi";
import { app } from "@/src/index";
import { getProjectInfo } from "@/app/utils/getProjectInfo";

const api = new Elysia({ prefix: "/api" })
  .use(
    openapi({
      documentation: {
        info: getProjectInfo(),
      },
    }),
  )
  .use(app);

export type App = typeof api;

export const GET = api.fetch;
export const POST = api.fetch;
export const PUT = api.fetch;
export const DELETE = api.fetch;
export const PATCH = api.fetch;
