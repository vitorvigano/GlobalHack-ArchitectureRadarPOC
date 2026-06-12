# Architecture Radar

Ferramenta de análise arquitetural baseada em IA. A partir do contexto real de um sistema (domínio, escala, equipe, restrições), o Architecture Radar usa Claude (Anthropic) para inferir as características de qualidade mais relevantes, expor os trade-offs entre elas e levantar riscos técnicos — ainda nas fases iniciais de design.

Baseado no método de análise de trade-offs de Neal Ford / Mark Richards (ATAM). "Everything in software architecture is a trade-off."

## Stack

- Ruby 4.0.2
- Rails 8.1
- SQLite 3
- Claude API (Anthropic)
- Hotwire (Turbo + Stimulus)

## Pré-requisitos

- Ruby 4.0.2 (recomendado via [rbenv](https://github.com/rbenv/rbenv) ou [mise](https://mise.jdx.dev))
- Bundler
- Chave de API da Anthropic

## Instalação

```bash
# Clone o repositório
git clone <repo-url>
cd Hackaton

# Instale as dependências
bundle install

# Configure as variáveis de ambiente
cp .env.example .env
# Edite .env e adicione sua ANTHROPIC_API_KEY
```

## Variáveis de ambiente

Crie um arquivo `.env` na raiz do projeto:

```env
ANTHROPIC_API_KEY=sua_chave_aqui
```

## Banco de dados

```bash
bin/rails db:create db:migrate
```

## Rodando localmente

```bash
bin/rails server
```

Acesse [http://localhost:3000](http://localhost:3000).

## Como usar

1. Preencha o formulário com o contexto do seu sistema:
   - **Domínio e subdomínio** — área de negócio do sistema
   - **Business drivers** — preocupações e objetivos principais
   - **Escala** — usuários esperados, RPS, crescimento, padrão de tráfego
   - **Criticidade** — tolerância a falhas
   - **Equipe** — tamanho, experiência e budget
   - **Restrições** — integrações legadas, estilo arquitetural preferido

2. Submeta o formulário.

3. O Claude analisa o contexto e gera um radar com as características arquiteturais priorizadas, trade-offs explícitos e riscos técnicos identificados.

## Testes

```bash
bin/rails test
```

## Estrutura principal

```
app/
  controllers/
    projects_controller.rb   # wizard de intake e exibição do radar
  views/
    projects/
      new.html.erb            # formulário de contexto
      show.html.erb           # radar + análise gerada pelo Claude
  models/
    project.rb                # entidade com campos de contexto e resultado cacheado
lib/
  architecture_analysis_service.rb  # integração com Claude API
```
