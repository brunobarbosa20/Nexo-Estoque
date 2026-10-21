# Instruções do projeto para o Codex

## Ao abrir o repositório em um computador novo

Este projeto usa React, TypeScript, Vite e Supabase. A versão publicada no GitHub Pages é estática; o MariaDB/XAMPP e o servidor Node antigo não são necessários para executar a versão atual.

Antes de iniciar o app:

1. Verifique se Node.js e npm estão disponíveis (`node --version` e `npm --version`). Se estiverem ausentes, avise o usuário e oriente a instalar uma versão LTS do Node.js.
2. Se `node_modules` não existir, instale as dependências do lockfile com `npm ci`. Se a instalação for bloqueada por permissões ou rede, explique o bloqueio e solicite a autorização necessária.
3. Verifique apenas se `.env` existe; não leia, mostre, registre em logs ou envie seus valores. Se estiver ausente, crie-o copiando `.env.example` e peça ao usuário para preencher `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` com os valores públicos do projeto Supabase.
4. Nunca solicite nem use uma chave `service_role` ou `secret` no frontend. O `.env` está no `.gitignore` e nunca deve ser commitado.

Para executar localmente, use `npm run dev` e abra o endereço informado pelo Vite.

## Supabase

- Em um projeto Supabase novo, o usuário deve executar `database/supabase.sql` uma vez no SQL Editor.
- Para um banco que já usava o esquema anterior baseado em e-mail, executar somente `database/supabase_username_migration.sql`.
- Não executar SQL no projeto remoto sem solicitação explícita do usuário. Não editar diretamente `auth.users` para criar contas ou trocar senhas.
- No GitHub Actions, o workflow de Pages recebe `SUPABASE_URL` e `SUPABASE_ANON_KEY` das variáveis do repositório e as injeta no build. Não adicionar credenciais ao código.

## Graphify

O skill Graphify está em `.claude/skills/graphify/SKILL.md`. Se o usuário invocar `/graphify` e o comando `graphify` não estiver instalado, avise que ele é uma ferramenta opcional do Graphify (não uma dependência do app) e oriente a instalação com `uv tool install --upgrade graphifyy`. A saída fica em `graphify-out/`, que é ignorada pelo Git.
