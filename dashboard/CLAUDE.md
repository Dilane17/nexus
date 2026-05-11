# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Next.js 16 admin dashboard for **NEXUS P2P Lending** (Bénin). Serves two roles: `admin` (full access) and `imf_staff` (KYC + Loans only). Calls a NestJS backend at `http://localhost:3000/api/v1`.

## Commands

```bash
npm run dev      # Start dev server (port 3000, or 3001 if backend is on 3000)
npm run build    # Production build — also runs TypeScript check
npm run lint     # ESLint (must be clean before committing)
npx tsc --noEmit # Standalone TypeScript check
```

No test runner is configured yet.

## Stack

| Concern | Library |
|---------|---------|
| Framework | Next.js 16, App Router, React 19 |
| Styling | Tailwind CSS **v4** (CSS-based config, no `tailwind.config.ts`) |
| Forms | `react-hook-form` + `zod` + `@hookform/resolvers` |
| HTTP | `axios` (instance at `lib/api.ts`) |
| State | `zustand` v5 with `persist` middleware |
| Icons | `lucide-react` |

## Architecture

### Auth flow
`app/login/page.tsx` → `POST /auth/login` → JWT decoded client-side via `lib/auth.ts:decodeJwt()` (base64 split, no library) → role extracted from payload → stored in `store/authStore.ts` (Zustand + localStorage key `nexus-auth`).

`lib/api.ts` reads `localStorage['nexus-auth'].state.accessToken` on every request via an Axios request interceptor. A 401 response interceptor clears storage and redirects to `/login`.

### Route protection
`components/layout/ProtectedRoute.tsx` is a client component that reads the Zustand store. It redirects to `/login` if no token, and to `/dashboard` if the user's role isn't in `allowedRoles`. Every protected page wraps its content in `<ProtectedRoute allowedRoles={[...]}>`.

`app/dashboard/layout.tsx` wraps all dashboard routes in `ProtectedRoute` (no `allowedRoles` — just requires login), then renders `<Sidebar>` + `<Header>` + children.

### Tailwind v4 custom colours
Colours are defined in `app/globals.css` under `@theme inline`. Use hex literals directly in `className` (e.g. `bg-[#1A3A5C]`) — the CSS variables (`--color-navy` etc.) are available for inline `style` props but Tailwind v4 utility classes from `@theme` are not yet reliably tree-shaken in this setup.

### UI primitives
`components/ui/Table.tsx` uses a flat `Column` interface (not generic) — render functions receive `Record<string, unknown>` and cast internally with `row as unknown as MyType`. Use `data={items as unknown as Record<string, unknown>[]}` at call sites.

### Environment
Single variable: `NEXT_PUBLIC_API_URL` in `.env.local`. Falls back to `http://localhost:3000/api/v1`.

## Key constraints

- `startTransition()` is required when calling `setState` synchronously at the top level of a `useEffect` (Next.js 16 ESLint rule `react-hooks/set-state-in-effect`).
- External image URLs (KYC docs) require `{/* eslint-disable-next-line @next/next/no-img-element */}` above `<img>` tags because domains are dynamic.
- Scoring engine weights are stored as `0–1` floats in the API; the UI shows `0–100%` — divide/multiply by 100 on read/write.
