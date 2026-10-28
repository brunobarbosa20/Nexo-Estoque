# Graph Report - Clone Controle de Estoque MariaDB  (2026-10-28)

## Corpus Check
- 18 files · ~81,460 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 4 file(s) not represented in the graph (top: .example 1, (none) 1, .csv 1)

## Summary
- 129 nodes · 155 edges · 14 communities (11 shown, 3 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d9fbeceb`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

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
- AGENTS.md — Instruções do projeto para agentes de IA
- 4. Graphify — Análise e navegação do código
- CLAUDE.md

## God Nodes (most connected - your core abstractions)
1. `compilerOptions` - 16 edges
2. `api()` - 15 edges
3. `App()` - 11 edges
4. `DialogForm()` - 8 edges
5. `AGENTS.md — Instruções do projeto para agentes de IA` - 8 edges
6. `4. Graphify — Análise e navegação do código` - 8 edges
7. `scripts` - 4 edges
8. `formatInt()` - 4 edges
9. `parseInt10()` - 4 edges
10. `Auth()` - 4 edges

## Surprising Connections (you probably didn't know these)
- `logout()` --calls--> `api()`  [EXTRACTED]
  src/App.tsx → src/supabase-api.ts
- `GitHub Pages publication` --references--> `GitHub Pages deployment workflow`  [EXTRACTED]
  README.md → .github/workflows/deploy.yml
- `submit()` --calls--> `api()`  [EXTRACTED]
  src/App.tsx → src/supabase-api.ts
- `App()` --calls--> `api()`  [EXTRACTED]
  src/App.tsx → src/supabase-api.ts
- `ProductDetails()` --calls--> `api()`  [EXTRACTED]
  src/App.tsx → src/supabase-api.ts

## Import Cycles
- None detected.

## Communities (14 total, 3 thin omitted)

### Community 0 - "Project Metadata"
Cohesion: 0.09
Nodes (20): devDependencies, @types/react, @types/react-dom, typescript, name, private, scripts, build (+12 more)

### Community 1 - "React User Interface"
Cohesion: 0.13
Nodes (21): App(), logout(), DialogForm(), submit(), formatInt(), formatMoney(), Ingredient, Modal() (+13 more)

### Community 2 - "TypeScript Configuration"
Cohesion: 0.11
Nodes (17): compilerOptions, allowImportingTsExtensions, isolatedModules, jsx, lib, module, moduleResolution, noEmit (+9 more)

### Community 3 - "Supabase Application Logic"
Cohesion: 0.24
Nodes (13): Auth(), submit(), anonKey, api(), authEmail(), bodyOf(), data(), fail() (+5 more)

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

### Community 11 - "AGENTS.md — Instruções do projeto para agentes de IA"
Cohesion: 0.18
Nodes (10): 1. Visão geral do projeto, 2. Configuração em um computador novo, 3. Supabase, 5.1. Antes de modificar, 5.2. Durante as modificações, 5.3. Após as modificações, 5. Desenvolvimento e alterações no código, 6. Git e checkpoints (+2 more)

### Community 12 - "4. Graphify — Análise e navegação do código"
Cohesion: 0.25
Nodes (8): 4.1. Regra obrigatória de consulta, 4.2. Identificação de funções e relacionamentos, 4.3. Navegação pela documentação, 4.4. Leitura e validação do código-fonte, 4.5. Atualização do grafo, 4.6. Git e arquivos do Graphify, 4.7. Instalação do Graphify, 4. Graphify — Análise e navegação do código

## Knowledge Gaps
- **15 isolated node(s):** `@types/react`, `@types/react-dom`, `typescript`, `GitHub Pages deployment job`, `Supabase build variables` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 81 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `react` connect `Project Metadata` to `React User Interface`?**
  _High betweenness centrality (0.080) - this node is a cross-community bridge._
- **What connects `@types/react`, `@types/react-dom`, `typescript` to the rest of the system?**
  _15 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Project Metadata` be split into smaller, more focused modules?**
  _Cohesion score 0.09486166007905138 - nodes in this community are weakly interconnected._
- **Why does `dependencies` connect `Runtime Dependencies` to `Project Metadata`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Should `React User Interface` be split into smaller, more focused modules?**
  _Cohesion score 0.12666666666666668 - nodes in this community are weakly interconnected._
- **Why does `@supabase/supabase-js` connect `Project Metadata` to `Supabase Application Logic`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **Should `TypeScript Configuration` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._