FROM node:20-alpine

RUN apk add --no-cache git python3 make g++ tini

WORKDIR /app

# Clone le starter officiel Medusa v2
RUN git clone --depth 1 https://github.com/medusajs/medusa-starter-default.git .

# Install des dépendances
RUN npm install

# Build server + admin panel (medusa build compile le code ET build l'admin UI)
RUN npx medusa build

EXPOSE 9000
ENV NODE_ENV=production
ENV PORT=9000

# Lancer depuis le serveur compilé (admin est à .medusa/server/public/admin/)
WORKDIR /app/.medusa/server

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["npm", "start"]
