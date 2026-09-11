# Krent (Nigeria) — Mobile App Documentation

Welcome to the **Krent** documentation hub. **Krent** (*Key + Rent*) is a trust-first mobile rental marketplace and tenancy management platform engineered specifically for the Nigerian residential real estate landscape (Lagos, Abuja, Port Harcourt, Ibadan, etc.).

> *"Keys in hand. Peace of mind. Rent without the wahala."*

---

## 📂 Documentation Directory

| Document | Description |
| **[BRAND_STORY.md](file:///Users/ajibolagenius/Desktop/Krent/BRAND_STORY.md)** | Core brand narrative, mission, vision, origin story (*Key + Rent*), the 4 brand pillars, voice guidelines, slogans, and visual design system. |
| **[TECH_STACK.md](file:///Users/ajibolagenius/Desktop/Krent/TECH_STACK.md)** | End-to-end technology stack blueprint: React Native/Expo SDK 52+, NativeWind v4, Supabase (PostgreSQL/PostGIS), Nigerian API rails (Paystack, Termii, Prembly), security & CI/CD. |
| **[KRENT_SPECIFICATION.md](file:///Users/ajibolagenius/Desktop/Krent/KRENT_SPECIFICATION.md)** | Complete product scope, personas, anti-fraud KYC engine, hyper-local filter matrix, escrow system, and Expo (React Native) technical architecture. |
| **[MARKET_SURVEY_AND_BRANDING.md](file:///Users/ajibolagenius/Desktop/Krent/MARKET_SURVEY_AND_BRANDING.md)** | Nigerian proptech market survey, competitor pros/cons (NPC, PropertyPro, Spleet, SmallSmall, Fibre), white-space analysis, and brand name evaluation. |
| **[DATABASE_SCHEMA.sql](file:///Users/ajibolagenius/Desktop/Krent/DATABASE_SCHEMA.sql)** | Production-ready PostgreSQL + PostGIS database schema tailored for Supabase, including RLS policies, indexing, and spatial query functions. |
| **[PROJECT_ROADMAP.md](file:///Users/ajibolagenius/Desktop/Krent/PROJECT_ROADMAP.md)** | Step-by-step 4-phase implementation plan, third-party Nigerian API integration guide (Paystack, Termii, Prembly/Dojah), and sprint deliverables. |

---

## 🚀 Key Highlights & Differentiators

1. **Anti-Fraud & Trust Infrastructure:**
   - Identity verification for agents and landlords using **NIN**, **BVN**, and **CAC** (via Prembly / Dojah / Smile ID).
   - Standardized, capped agent commissions (5–10% max) to eliminate arbitrary price inflation.
   - Inspection booking with escrow protection to eliminate bogus "mobility fees".

2. **Hyper-Local Quality of Life Attributes:**
   - **Power:** Disco feeder classification (Band A–D), central estate generator schedules, private generator rules.
   - **Water:** Industrial water treatment plant vs raw borehole vs municipal water supply.
   - **Flooding & Drainage:** Rainy season elevation risk ratings and road pavement status.
   - **Security:** Estate access codes, gated perimeter, estate association dues.

3. **Financial Transparency & Tenancy Management:**
   - Total move-in cost breakdown upfront (Rent + Service Charge + Caution Deposit + Legal + Agency).
   - Escrow holding deposits with Paystack/Monnify split disbursements.
   - Rent-Now-Pay-Later (RNPL) monthly installment financing integration.
   - Standardized digital tenancy agreements with in-app e-signatures.

4. **Modern Tech Stack:**
   - **Client:** React Native, Expo (SDK 52+), TypeScript, Expo Router, NativeWind v4 (Tailwind CSS), TanStack React Query, Zustand.
   - **Backend:** Supabase (PostgreSQL + PostGIS, Auth, Storage, Realtime Edge Functions).
