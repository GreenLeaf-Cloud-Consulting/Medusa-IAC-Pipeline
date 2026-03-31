FROM node:20-alpine AS deps

RUN apk add --no-cache git
WORKDIR /app

RUN git clone --depth 1 https://github.com/medusajs/nextjs-starter-medusa.git .
RUN npm install --legacy-peer-deps

# ---- Build ----
FROM node:20-alpine AS builder

WORKDIR /app
COPY --from=deps /app ./

ARG NEXT_PUBLIC_MEDUSA_BACKEND_URL=http://localhost:9000
ARG MEDUSA_BACKEND_URL=http://localhost:9000
ARG NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_placeholder
ENV NEXT_PUBLIC_MEDUSA_BACKEND_URL=$NEXT_PUBLIC_MEDUSA_BACKEND_URL
ENV MEDUSA_BACKEND_URL=$MEDUSA_BACKEND_URL
ENV NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=$NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY
ENV NEXT_TELEMETRY_DISABLED=1

# Patch generateStaticParams to return [] so build doesn't call the backend
RUN node -e "\
const fs=require('fs');\
const out=require('child_process').execSync('find . -name page.tsx',{encoding:'utf8'});\
out.trim().split('\n').filter(Boolean).forEach(f=>{\
  try{\
    let c=fs.readFileSync(f,'utf8');\
    if(!c.includes('generateStaticParams'))return;\
    const idx=c.indexOf('export async function generateStaticParams');\
    if(idx===-1)return;\
    const ob=c.indexOf('{',idx);\
    if(ob===-1)return;\
    let depth=1,i=ob+1;\
    while(i<c.length&&depth>0){if(c[i]==='{')depth++;else if(c[i]==='}')depth--;i++;}\
    c=c.slice(0,idx)+'export async function generateStaticParams(){return []}'+c.slice(i);\
    fs.writeFileSync(f,c);\
    console.log('Patched:',f);\
  }catch(e){console.log('Skip:',f,e.message);}\
});"

# Enable standalone output + expose MEDUSA_BACKEND_URL via next.config env (available in Edge Runtime)
RUN node -e "\
const fs=require('fs');\
const files=['next.config.js','next.config.mjs','next.config.ts'];\
files.forEach(f=>{\
  if(!fs.existsSync(f))return;\
  let c=fs.readFileSync(f,'utf8');\
  if(!c.includes('standalone'))c=c.replace('reactStrictMode: true','reactStrictMode: true, output: \"standalone\"');\
  if(!c.includes('MEDUSA_BACKEND_URL'))c=c.replace('reactStrictMode: true','reactStrictMode: true, env: { MEDUSA_BACKEND_URL: process.env.MEDUSA_BACKEND_URL || \"http://localhost:9000\" }');\
  fs.writeFileSync(f,c);\
  console.log('Patched config:',f);\
});"

RUN npm run build --legacy-peer-deps

# ---- Image finale ----
FROM node:20-alpine

RUN apk add --no-cache tini

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8000
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 8000

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]
