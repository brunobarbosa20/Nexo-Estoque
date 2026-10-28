# AGENTS.md — Instruções do projeto para agentes de IA

## 1. Visão geral do projeto

Este projeto utiliza:

- React
- TypeScript
- Vite
- Supabase

A versão publicada no GitHub Pages é estática. O MariaDB/XAMPP e o servidor Node antigo não são necessários para executar a versão atual.

Respeite a arquitetura existente e compreenda o funcionamento do código antes de propor ou realizar alterações.

## 2. Configuração em um computador novo

Ao abrir o repositório em um computador novo:

1. Verifique se Node.js e npm estão disponíveis (`node --version` e `npm --version`). Se estiverem ausentes, avise o usuário e oriente a instalação de uma versão LTS do Node.js.
2. Se `node_modules` não existir, instale as dependências do lockfile com `npm ci`. Se a instalação for bloqueada por permissões ou rede, explique o bloqueio e solicite a autorização necessária.
3. Verifique apenas se `.env` existe. Não leia, mostre, registre em logs ou envie seus valores.
4. Se `.env` estiver ausente, crie-o copiando `.env.example` e peça ao usuário para preencher `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` com os valores públicos do projeto Supabase.
5. Nunca solicite nem utilize uma chave `service_role` ou `secret` no frontend.
6. O arquivo `.env` está no `.gitignore` e nunca deve ser commitado.

Para executar localmente, utilize:

`npm run dev`

Abra o endereço informado pelo Vite.

## 3. Supabase

- Em um projeto Supabase novo, o usuário deve executar `database/supabase.sql` uma vez no SQL Editor.
- Para um banco que já utilizava o esquema anterior baseado em e-mail, executar somente `database/supabase_username_migration.sql`.
- Não executar SQL no projeto remoto sem solicitação explícita do usuário.
- Não editar diretamente `auth.users` para criar contas ou trocar senhas.
- Nunca adicionar credenciais ao código-fonte.
- No GitHub Actions, o workflow de Pages recebe `SUPABASE_URL` e `SUPABASE_ANON_KEY` das variáveis do repositório e as injeta no build.

## 4. Graphify — Análise e navegação do código

O projeto possui um grafo de conhecimento em `graphify-out/`, contendo relacionamentos entre funções, arquivos, módulos e componentes.

O Graphify deve ser utilizado como ferramenta de apoio para compreender a arquitetura do projeto e facilitar a identificação de funções, dependências e relacionamentos entre diferentes partes do código.

### 4.1. Regra obrigatória de consulta

Quando `graphify-out/graph.json` existir, antes da primeira pesquisa (`grep`, busca textual ou equivalente) ou leitura de arquivos-fonte para responder a uma questão sobre o código, execute:

`graphify query "pergunta ou objetivo da análise"`

Essa regra também deve ser incluída nas instruções de todos os subagentes que forem investigar o código.

Não comece uma investigação ampla diretamente pelos arquivos quando o grafo estiver disponível.

### 4.2. Identificação de funções e relacionamentos

Utilize os comandos conforme a necessidade:

- `graphify query "..."`: localizar funções, arquivos, componentes e relacionamentos relevantes para uma investigação.
- `graphify path "A" "B"`: identificar o caminho de relacionamento entre duas funções, módulos ou conceitos.
- `graphify explain "..."`: obter uma explicação focada sobre uma função, conceito ou parte específica do sistema.

Priorize essas consultas para identificar:

- Onde uma função está definida.
- Quais partes do sistema utilizam determinada função.
- Quais funções são chamadas por outras funções.
- Quais componentes dependem de determinado serviço ou módulo.
- Como os dados circulam entre componentes, hooks e serviços.
- Quais partes podem ser afetadas por uma alteração.

Utilize os resultados do grafo para direcionar a investigação e reduzir pesquisas desnecessárias.

### 4.3. Navegação pela documentação

Se `graphify-out/wiki/index.md` existir, utilize-o como ponto de partida para navegação ampla pela arquitetura e documentação do projeto, em vez de começar explorando diretamente os arquivos-fonte.

Consulte `graphify-out/GRAPH_REPORT.md` somente quando:

- For necessária uma revisão ampla da arquitetura.
- As consultas `query`, `path` e `explain` não fornecerem contexto suficiente.
- For necessário compreender a estrutura geral do projeto.

### 4.4. Leitura e validação do código-fonte

- Leia os arquivos-fonte somente depois que o Graphify ou uma leitura anterior tiver localizado os trechos relevantes.
- Utilize o grafo para direcionar a leitura, não como substituto da análise do código.
- Confirme diretamente no código-fonte as funções, chamadas, dependências e comportamentos identificados.
- Não presuma que uma função não é utilizada apenas porque ela não aparece no grafo.
- Não realize alterações com base exclusivamente nas informações do grafo.

### 4.5. Atualização do grafo

Depois de modificar o código, execute:

`graphify update .`

Essa atualização mantém o grafo sincronizado com a estrutura atual do projeto.

A atualização é baseada em AST e não possui custo de API.

Não deixe de atualizar o grafo após modificações no código.

Se o Graphify não estiver instalado ou disponível, informe o usuário e, quando possível, continue a investigação utilizando os meios convencionais.

### 4.6. Git e arquivos do Graphify

- A pasta `graphify-out/` contém os arquivos gerados pelo Graphify.
- O arquivo `graphify-out/graph.json` pode ser reescrito integralmente durante uma atualização.
- Um diff grande nesse arquivo é esperado e não deve ser considerado automaticamente um problema.
- Não recomende ignorar a atualização do grafo ou remover seus hooks apenas por causa do tamanho do diff.
- Respeite a configuração atual do Git e não altere regras de versionamento sem necessidade.

### 4.7. Instalação do Graphify

O skill Graphify está localizado em:

`.claude/skills/graphify/SKILL.md`

Se o usuário solicitar a utilização do Graphify e o comando `graphify` não estiver instalado, informe que se trata de uma ferramenta opcional, não de uma dependência do aplicativo.

Oriente a instalação com:

`uv tool install --upgrade graphifyy`

Os arquivos gerados ficam em `graphify-out/`, conforme a configuração de versionamento do projeto.

## 5. Desenvolvimento e alterações no código

### 5.1. Antes de modificar

- Entenda o objetivo da solicitação.
- Analise a implementação existente.
- Consulte o Graphify quando disponível e aplicável.
- Identifique os arquivos, funções e componentes envolvidos.
- Verifique os possíveis impactos em outras partes do sistema.
- Preserve os padrões e a arquitetura existentes sempre que possível.

### 5.2. Durante as modificações

- Altere somente o que for necessário para atender à solicitação.
- Evite duplicar funções ou implementar comportamentos que já existem.
- Reutilize componentes, hooks, serviços e funções existentes quando apropriado.
- Não remova funcionalidades sem necessidade ou autorização.
- Não faça alterações estruturais fora do escopo solicitado.
- Não substitua implementações existentes sem compreender suas dependências.

### 5.3. Após as modificações

- Execute `graphify update .` após alterações no código.
- Execute os testes pertinentes, quando disponíveis.
- Verifique erros de TypeScript, lint e build conforme os scripts existentes no `package.json`.
- Analise o resultado das modificações.
- Informe quais arquivos foram alterados e o motivo.
- Informe quais verificações foram executadas e seus resultados.
- Se alguma verificação não puder ser executada, explique o motivo.

## 6. Git e checkpoints

O Git deve ser utilizado para preservar pontos de restauração durante o desenvolvimento.

- Antes de alterações estruturais relevantes, verifique o estado do repositório com `git status`.
- Quando apropriado, recomende criar um commit de segurança antes de iniciar uma mudança significativa.
- Não sobrescreva alterações existentes do usuário.
- Não execute `git reset --hard`, `git clean -fd` ou operações destrutivas sem autorização explícita.
- Não faça commits ou pushes sem solicitação do usuário.
- Explique as alterações importantes para facilitar a compreensão e eventual reversão.

## 7. Comunicação com o usuário

- Explique o que será feito antes de mudanças complexas.
- Apresente os motivos das decisões técnicas importantes.
- Informe quais funções, componentes e arquivos estão envolvidos.
- Quando identificar problemas, explique a causa antes de propor a solução.
- Não declare uma funcionalidade concluída sem verificar sua implementação.
- Prefira explicações claras e passo a passo, evitando termos técnicos sem explicação.