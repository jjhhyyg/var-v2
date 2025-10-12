# VAR Molten Pool Video Analysis System

[简体中文](README.zh.md) | English

> Intelligent welding pool video analysis system based on deep learning

## 📋 Project Overview

This is a complete video analysis platform for detecting and analyzing anomalous events in VAR (Vacuum Arc Remelting) molten pool videos.

### Tech Stack

- **Frontend**: Nuxt 4 + Vue 3 + TypeScript
- **Backend**: Spring Boot 3 + PostgreSQL + Redis
- **AI Engine**: Flask + PyTorch + YOLO11
- **Message Queue**: RabbitMQ

### Core Features

- Video upload and management (supports up to 2GB)
- Asynchronous task processing based on RabbitMQ
- YOLO11 object detection + BoT-SORT tracking
- Automatic detection of anomalous events like electrode adhesion and glow
- Generate annotated result videos
- Real-time progress tracking

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
# Clone the main repository and initialize all submodules
git clone --recurse-submodules https://github.com/jjhhyyg/var-v2.git
cd var-v2

# Or clone the main repository first, then initialize submodules
git clone https://github.com/jjhhyyg/var-v2.git
cd var-v2
git submodule update --init --recursive
```

### 2. Development Environment Quick Start

#### Step 1: Configure Environment Variables

```bash
# Linux/macOS
./scripts/use-env.sh dev

# Windows PowerShell
.\scripts\use-env.ps1 dev

# Windows CMD
scripts\use-env.cmd dev
```

> For first-time use, please modify the configuration in `env/*/.env.development` based on `env/*/.env.example`

#### Step 2: Start Infrastructure (PostgreSQL, Redis, RabbitMQ)

```bash
docker-compose -f docker-compose.dev.yml up -d
```

#### Step 3: Start Services

**Backend Service**

```bash
cd backend
./mvnw spring-boot:run
# Service runs at http://localhost:8080
```

**Frontend Application**

```bash
cd frontend
pnpm install
pnpm dev
# Service runs at http://localhost:3000
```

**AI Processing Module**

```bash
cd ai-processor
pip install -r requirements.txt
python app.py
# Service runs at http://localhost:5000
```

### 3. Production Deployment (Docker)

#### Step 1: Configure Production Environment Variables

```bash
# Linux/macOS
./scripts/use-env.sh prod

# Windows PowerShell
.\scripts\use-env.ps1 prod

# Windows CMD
scripts\use-env.cmd prod
```

> ⚠️ For production environment, be sure to modify sensitive information in `env/*/.env.production` (database passwords, JWT secrets, etc.)

#### Step 2: Prepare AI Model Weight Files

Ensure YOLO model weight file is placed in the correct location:

```bash
# Ensure weight file exists
ls ai-processor/weights/best.pt
```

#### Step 3: One-Click Deployment with Docker Compose

```bash
# Build and start all services (including PostgreSQL, Redis, RabbitMQ, Backend, Frontend, AI-Processor)
# Use docker-compose.prod.cpu.yml if no GPU available
docker-compose -f docker-compose.prod.yml up -d --build

# View service status
docker-compose -f docker-compose.prod.yml ps

# View service logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop all services
docker-compose -f docker-compose.prod.yml down
```

After deployment, service access addresses:

- Frontend: http://localhost:8848
- Backend API: http://localhost:8080
- AI Processing Module: http://localhost:5000
- RabbitMQ Management Interface: http://localhost:15672

---

## 📚 More Documentation

- **Detailed Configuration Guide**: See [`env/README.md`](env/README.md)
- **Git Submodule Management**: See README in each subproject
  - [backend/](backend/)
  - [frontend/](frontend/)
  - [ai-processor/](ai-processor/)

---

## 📄 License

This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0) - see the [LICENSE](LICENSE) file for details.

**Important:** Any modified version of this software used over a network must make the source code available to users.

---

**Last Updated**: 2025-10-13
