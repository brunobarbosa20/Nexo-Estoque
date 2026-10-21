# Controle de Estoque com Supabase

Aplicacao React/Vite para controle de produtos, movimentacoes e receitas. Usa Supabase Auth e PostgreSQL com Row Level Security e pode ser publicada no GitHub Pages. Nao precisa manter XAMPP nem uma API Node local.

## Preparar o Supabase

1. Crie um projeto Supabase.
2. No SQL Editor, execute database/supabase.sql uma vez em um projeto novo. Para um projeto que ja executou o esquema Supabase anterior, execute somente database/supabase_username_migration.sql.
3. Em Authentication > Sign In / Providers > Email, desative Confirm email. O app usa um identificador interno no formato de e-mail para o Supabase Auth, mas o usuario so informa nome de usuario e senha; esse endereco interno nao recebe mensagens.
4. Em Project Settings > API, copie a Project URL e a chave publica anon/publishable.
5. Em Authentication > URL Configuration, configure a URL do site Pages em Site URL e Redirect URLs. Para desenvolvimento local, inclua http://localhost:5173/**.

Nomes de usuario devem ter de 3 a 30 caracteres: letras sem acento, numeros, ponto, sublinhado ou hifen. Cada nome e unico. Use uma senha forte; sem um e-mail real, nao ha recuperacao automatica de senha.

## Rodar localmente

1. Copie .env.example para .env.
2. Preencha VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY com os valores do projeto.
3. Execute:

   powershell
   npm ci
   npm run dev

4. Abra o endereco local informado pelo Vite.

## Publicar no GitHub Pages

O workflow .github/workflows/deploy.yml publica a branch main. Em Settings > Secrets and variables > Actions > Variables, crie:

- SUPABASE_URL: Project URL.
- SUPABASE_ANON_KEY: chave publica anon/publishable.

Em Settings > Pages, escolha GitHub Actions como fonte. Configure tambem a URL final do Pages em Authentication > URL Configuration.

A chave anon/publishable e usada no navegador; a seguranca dos dados depende das politicas RLS. Nunca coloque a chave service_role no frontend ou nas variaveis de compilacao.

## Dados

- Cada usuario novo recebe um estoque privado.
- Administradores podem gerenciar permissoes; operadores podem movimentar estoque; visualizadores tem acesso de leitura.
- Movimentacoes atualizam o saldo por trigger PostgreSQL, e operacoes sensiveis passam por funcoes SQL.
- O SQL nao importa dados do MariaDB antigo. Os arquivos database/001_initial.sql, database/002_app_user_grants.sql e database/003_user_isolation.sql sao da versao MariaDB anterior.
