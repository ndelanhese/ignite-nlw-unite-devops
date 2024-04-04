FROM node:20.12.0 AS base

RUN npm i -g pnpm

FROM base AS deps

WORKDIR /usr/src/app

COPY package.json pnpm-lock.yaml ./

RUN pnpm i

FROM base AS build

WORKDIR /usr/src/app

COPY . .
COPY --from=deps /usr/src/app/node_modules ./node_modules

RUN pnpm build && pnpm prune --prod

FROM node:20.12.0-alpine3.19 AS deploy

WORKDIR /usr/src/app

RUN npm i -g pnpm && pnpm i prisma

COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/prisma ./prisma

RUN pnpm prisma generate

EXPOSE 3333

CMD [ "pnpm", "start" ]