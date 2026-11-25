host: technetium.itsarraj.xyz — 185.139.7.99
package: SPECIAL 4545P [2 vCPU, 4 GB RAM, 100 GB disk]

### Goal
Repeatable way to build + run Novu locally to test Gupshup WhatsApp (ideally without fighting Node/pnpm/tooling issues).

Docker compose (prebuilt images + infra) or hybrid (docker for infra + pnpm for services). Both below.

---

## Option A (recommended): Run everything with Docker Compose

### 1) Install Docker + Compose
On Arch:

```bash
sudo pacman -Syu --noconfirm docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker prod
newgrp docker
docker version
docker compose version
```

### 2) Go to the repo and pick a compose file
```bash
cd ~/novu-modified
ls docker
```

Most Novu repos include something like `docker/community/docker-compose.yml` or `docker/local/docker-compose.yml`.

If you have `docker/community/docker-compose.yml`:

```bash
cp docker/community/.env.example docker/community/.env 2>/dev/null || true
docker compose --env-file docker/community/.env -f docker/community/docker-compose.yml up -d
docker ps
```

If you only have `docker/local/docker-compose.yml` (infra only), then use Option B instead.

### 3) Verify services
- API usually on **3000**
- WS on **3002**
- Dashboard often on **4200**

Check logs:

```bash
docker compose -f docker/community/docker-compose.yml logs -f --tail=200
```

---

## Option B (hybrid): Docker for infra + pnpm/NX for services

### 1) Install system deps
```bash
sudo pacman -Syu --noconfirm git base-devel python docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker prod
newgrp docker
```

### 2) Install Node 22 + pnpm
On Arch, simplest:

```bash
sudo pacman -S --noconfirm nodejs-lts-jod npm
node -v   # should be v22.x
npm -v
corepack enable
corepack prepare pnpm@10.16.1 --activate
pnpm -v
```

(Your local Novu setup wanted Node `>=22 <23`. Using Node 22 avoids a lot of native-module pain.)

### 3) Install deps
```bash
cd ~/novu-modified
pnpm install
```

### 4) Start infra (mongo/redis/etc.)
```bash
cp docker/.env.example docker/.env
docker compose --env-file docker/.env -f docker/local/docker-compose.yml up -d
docker ps
```

### 5) Build workspace packages (important)
```bash
pnpm build:packages
```

### 6) Start services
In separate SSH tmux panes (recommended):

```bash
pnpm start:api:dev
pnpm start:ws
pnpm start:worker
pnpm start:dashboard
```

---

## Fast “is Gupshup WhatsApp provider OK?” check (no full stack)
If you only want to validate your provider code quickly:

```bash
cd ~/novu-modified
pnpm install
pnpm -F @novu/providers test -- --run src/lib/sms/gupshup-whatsapp/gupshup-whatsapp.provider.spec.ts
```

That confirms the request payload built by `GupshupWhatsappProvider` matches expectations.

---

## VPS constraints (do this to avoid random crashes)
4 GB RAM is workable but builds can still OOM. Do at least one:

- add swap (recommended)
- use tmux so processes survive disconnects
- avoid running all services at once unless needed

Quick swap example (2 GB swapfile):

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
free -h
```

---

## Tell me one thing so I can give the exact command set
In `~/novu-modified`, what do you have?

```bash
ls docker/community docker/local 2>/dev/null
```

- If `docker/community/docker-compose.yml` exists → **Option A** is best.
- If only `docker/local/docker-compose.yml` exists → use **Option B**.
