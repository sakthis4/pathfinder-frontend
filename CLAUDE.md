# Pathfinder Web — React SPA Frontend

## Project Overview

Pathfinder Web is the React single-page application frontend for the Pathfinder ERP system (S4Carlisle publishing/typesetting). It communicates exclusively with the Pathfinder backend API — no direct database access, no AI services.

**Backend repo:** [github.com/sakthis4/pathfinder-backend](https://github.com/sakthis4/pathfinder-backend) (Express API)

---

## Tech Stack

| Technology | Version | Purpose |
|-----------|---------|---------|
| React | 19 | UI framework |
| Vite | 7 | Build tool + dev server |
| TypeScript | 5.9 | Type safety (strict mode) |
| Tailwind CSS | v4 | Styling |
| Zustand | 5 | Client state management |
| TanStack Query | 5 | Server state / data fetching |
| React Router | 7 | Routing |
| Axios | 1.x | HTTP client |
| Zod | — | Runtime input/form validation (install when needed) |
| Lucide React | — | Icons |

---

## Development

### Ports & URLs

| Service | Port | URL |
|---------|------|-----|
| Frontend (dev) | 5000 | http://localhost:5000 |
| Backend API | 3002 | http://localhost:3002/api/v1 |
| Health Check | 3002 | http://localhost:3002/health |

The Vite dev server proxies `/api/v1/*` and `/health` to the backend automatically (see `vite.config.ts`).

### Commands

```bash
npm run dev          # Start dev server on port 5000
npm run build        # TypeScript check + Vite production build
npm run type-check   # TypeScript validation only
npm run lint         # ESLint (zero errors AND zero warnings required)
npm run preview      # Preview production build locally
```

### Starting Development

```bash
# Terminal 1 — Backend (from pathfinder-backend repo)
cd pathfinder && npm run dev

# Terminal 2 — Frontend (this repo)
npm run dev
```

---

## Project Structure

```
src/
├── components/       # Reusable UI components
│   ├── ui/           # Base components (Button, Input, Modal, etc.)
│   ├── layout/       # Shell, Sidebar, Header, Footer
│   └── shared/       # Cross-module shared components
├── pages/            # Route pages (one per route)
├── services/         # API client functions (axios calls)
├── hooks/            # Custom React hooks (TanStack Query wrappers)
├── stores/           # Zustand stores (auth, ui, etc.)
├── types/            # TypeScript type definitions
├── utils/            # Helper functions
├── lib/              # Configured library instances (axios, queryClient)
└── App.tsx           # Root component with router
```

---

## Key Rules

### Component Size
- **200-300 lines MAX per component** — split larger components immediately
- Extract logic into custom hooks
- Extract sub-sections into child components

### No AI
- **NO AI services in production** — all logic is deterministic and rule-based
- No Gemini, no Claude API, no LLM calls from the frontend

### Code Quality (enforce at write-time)
- **Zero lint errors AND zero warnings** — both enforced before every push
- **NEVER use `any`** — use specific types or `unknown` with narrowing
- **NEVER mutate state** — use spread operator, functional updates
- **ALWAYS provide unique `key`** — use `item.id`, never array index
- **ALWAYS clean up effects** — return cleanup function from `useEffect`
- **ALWAYS include correct dependencies** in `useEffect` / `useMemo` / `useCallback`
- **ALWAYS handle loading, error, and empty states** — never assume data exists
- **ALWAYS invalidate queries** after mutations (`queryClient.invalidateQueries`)
- **Use `===`** — never `==`
- **Use Zod** for form validation — never trust raw user input

### Accessibility
- **ALWAYS add `alt` text** to images
- **ALWAYS use semantic HTML** — `<button>` not `<div onClick>`
- **ALWAYS add `aria-label`** to icon-only buttons
- **ALWAYS associate labels** with form inputs (`htmlFor`)
- **ALWAYS make interactive elements keyboard-accessible**
- **ALWAYS provide accessible error feedback** (`role="alert"`, `aria-invalid`)

### API Communication
- All API calls go through `src/services/` — never call axios directly from components
- Use TanStack Query hooks in `src/hooks/` — never call services directly from components
- Standard response format: `{ success: true, data: {...} }` or `{ success: false, error: { code, message } }`
- Always handle error responses gracefully in the UI

---

## S4Carlisle Branding

```css
/* CSS custom properties (defined in src/index.css) */
--color-s4c-blue: #1B4F8A;
--color-s4c-orange: #E88B2D;
--color-s4c-sidebar: #0F2E54;
```

- Primary color: S4C Blue (`#1B4F8A`)
- Accent color: S4C Orange (`#E88B2D`)
- Sidebar background: Dark navy (`#0F2E54`)

---

## Development Workflow

### For EVERY Code Update (Phase A — run after every change)

```bash
/simplify                    # Code reuse, quality, efficiency (Claude Code skill)
npm run lint                 # ESLint — zero errors + zero warnings
npm run type-check           # TypeScript strict validation
npm test                     # All tests (when test script exists)
```

**EVERY UPDATE** means every time you change code — not just at the end of a feature. Catch issues early.

### Before Push (Phase C — MANDATORY)

```bash
# Step 1: /review-fix (CodeRabbit + Claude review + security review — iterates until clean)
/review-fix

# Step 2: Pre-push checks (automated on git push — 6 checks)
./scripts/pre-push-check.sh
# Runs: lint → type-check → tests → build → security audit → CodeRabbit CLI
# Push is BLOCKED if any check fails.

# Step 3: Push (only after steps 1 and 2 pass)
git push
```

### Pre-Push Checks (6 gates)

| # | Check | Blocks Push? |
|---|-------|-------------|
| 1 | ESLint (zero errors + zero warnings) | Yes |
| 2 | TypeScript type-check | Yes |
| 3 | Tests (if test script exists) | Yes |
| 4 | Build (production build succeeds) | Yes |
| 5 | Security audit (`npm audit --audit-level=critical`) | Yes (critical only) |
| 6 | CodeRabbit CLI review | Yes (on critical/bug/security findings) |

---

## API Response Format

```typescript
// Success
{ success: true, data: { ... } }

// Success with pagination
{ success: true, data: { items: [...], total: 100, page: 1, limit: 20 } }

// Error
{ success: false, error: { code: "ERROR_CODE", message: "Human readable" } }
```

---

## Auth Flow

1. Login via `POST /api/v1/auth/login` returns `accessToken` + `refreshToken`
2. Store tokens in Zustand auth store (persisted to localStorage)
3. Axios interceptor attaches `Authorization: Bearer <accessToken>` to all requests
4. On 401, interceptor attempts token refresh via `POST /api/v1/auth/refresh`
5. If refresh fails, redirect to login

---

## Git Workflow

```bash
git checkout -b feat/module-name       # New feature
git checkout -b fix/bug-description    # Bug fix
git checkout -b chore/description      # Maintenance

# Commit format
type: short description

Co-Authored-By: Claude <noreply@anthropic.com>
# Types: feat, fix, chore, docs, refactor, test
```

---

## Environment Variables

```env
VITE_API_BASE_URL=http://localhost:3002    # Backend API base URL
VITE_BACKEND_URL=http://localhost:3002     # Backend URL (same)
```

For production, these are set at build time or via Docker/nginx config.

---

## CI/CD

### GitHub Secrets (required for staging deploy)

| Secret | Value | Purpose |
|--------|-------|---------|
| `STAGING_SSH_KEY` | SSH private key | Access to staging server |
| `STAGING_HOST` | `10.1.1.70` | Staging server IP |
| `STAGING_USER` | `itsupport` | SSH username |
| `STAGING_DEPLOY_PATH` | `/home/itsupport/pathfinder-frontend` | Frontend path on server |

### Pipeline

| Stage | Trigger | What Runs | Blocks On |
|-------|---------|-----------|-----------|
| **`/simplify`** | Every code update | Code reuse + quality + efficiency review → auto-fix | Findings remain → must fix |
| **`/review-fix`** | Before push | CodeRabbit CLI + Claude review + security review → iterate until clean | Findings remain → must fix |
| **Git pre-push hook** | `git push` | lint, type-check, tests, build, security audit, CodeRabbit CLI (6 checks) | Any failure → push blocked |
| **GitHub Actions CI** | PR to main | lint, type-check, build | Any failure → merge blocked |
| **Deploy Staging** | Merge to main | SSH → Docker build → 4 smoke tests → fail = deploy blocked | Smoke test failure |

- **CodeRabbit**: Runs locally via CLI in pre-push hook (not GitHub App)
- **Claude review + security**: Run via `/review-fix` skill before push (cannot be automated in bash)
