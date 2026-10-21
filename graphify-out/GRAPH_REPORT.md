# Graph Report - Clone Controle de Estoque MariaDB  (2026-10-21)

## Corpus Check
- Corpus is ~10,914 words - fits in a single context window. You may not need a graph.

## Summary
- 99 nodes · 115 edges · 11 communities (9 shown, 2 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Project Metadata
- React User Interface
- TypeScript Configuration
- Supabase Application Logic
- GitHub Pages Deployment
- Runtime Dependencies
- Architecture and Setup Docs
- Graphify Agent Guidance
- HTML Application Shell
- Product Import Templates

## God Nodes (most connected - your core abstractions)
1. `compilerOptions` - 16 edges
2. `api()` - 14 edges
3. `App()` - 9 edges
4. `scripts` - 4 edges
5. `Auth()` - 4 edges
6. `DialogForm()` - 4 edges
7. `fail()` - 4 edges
8. `Supabase inventory application` - 4 edges
9. `react` - 3 edges
10. `Modal()` - 3 edges

## Surprising Connections (you probably didn't know these)
- `submit()` --calls--> `api()`  [EXTRACTED]
  src/App.tsx → src/supabase-api.ts
- `logout()` --calls--> `api()`  [EXTRACTED]
  src/App.tsx → src/supabase-api.ts
- `GitHub Pages publication` --references--> `GitHub Pages deployment workflow`  [EXTRACTED]
  README.md → .github/workflows/deploy.yml
- `Auth()` --calls--> `api()`  [EXTRACTED]
  src/App.tsx → src/supabase-api.ts
- `App()` --calls--> `api()`  [EXTRACTED]
  src/App.tsx → src/supabase-api.ts

## Import Cycles
- None detected.

## Communities (11 total, 2 thin omitted)

### Community 0 - "Project Metadata"
Cohesion: 0.11
Nodes (18): devDependencies, @types/react, @types/react-dom, typescript, name, private, scripts, build (+10 more)

### Community 1 - "React User Interface"
Cohesion: 0.13
Nodes (15): react, react-dom, App(), logout(), Auth(), submit(), Ingredient, Modal() (+7 more)

### Community 2 - "TypeScript Configuration"
Cohesion: 0.11
Nodes (17): compilerOptions, allowImportingTsExtensions, isolatedModules, jsx, lib, module, moduleResolution, noEmit (+9 more)

### Community 3 - "Supabase Application Logic"
Cohesion: 0.24
Nodes (13): DialogForm(), submit(), anonKey, api(), authEmail(), bodyOf(), data(), fail() (+5 more)

### Community 4 - "GitHub Pages Deployment"
Cohesion: 0.33
Nodes (6): GitHub Pages deployment workflow, GitHub Pages artifact, GitHub Pages deployment job, Supabase build variables, Vite production build, GitHub Pages publication

### Community 5 - "Runtime Dependencies"
Cohesion: 0.33
Nodes (6): dependencies, react, react-dom, @supabase/supabase-js, vite, @vitejs/plugin-react

### Community 6 - "Architecture and Setup Docs"
Cohesion: 0.33
Nodes (6): Legacy MariaDB SQL files, Private inventory per user, Row Level Security data protection, Supabase inventory application, Supabase username migration script, Username and password login

### Community 7 - "Graphify Agent Guidance"
Cohesion: 0.50
Nodes (3): Graphify codebase navigation rules, Update the graph after code changes, Use the graph wiki for broad navigation

### Community 8 - "HTML Application Shell"
Cohesion: 0.67
Nodes (3): Application HTML shell, src/main.tsx entry module, React root mount element

## Knowledge Gaps
- **15 isolated node(s):** `@types/react`, `@types/react-dom`, `typescript`, `Supabase build variables`, `GitHub Pages deployment job` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 62 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `react` connect `React User Interface` to `Project Metadata`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **What connects `@types/react`, `@types/react-dom`, `typescript` to the rest of the system?**
  _15 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Project Metadata` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._
- **Why does `@supabase/supabase-js` connect `Project Metadata` to `Supabase Application Logic`?**
  _High betweenness centrality (0.066) - this node is a cross-community bridge._
- **Should `React User Interface` be split into smaller, more focused modules?**
  _Cohesion score 0.13450292397660818 - nodes in this community are weakly interconnected._
- **Why does `dependencies` connect `Runtime Dependencies` to `Project Metadata`?**
  _High betweenness centrality (0.058) - this node is a cross-community bridge._
- **Should `TypeScript Configuration` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._