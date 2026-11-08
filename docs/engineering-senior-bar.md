# Barra Senior de Engenharia (Software + Cloud Ops)

Padroes e postura tecnica exigidos de engenheiros de software e operadores seniores que atuam no repositorio Minecraft Core Server. Complementa a doutrina em [`llm-engineering-doctrine.md`](llm-engineering-doctrine.md) e a matriz em [`agent-coverage.md`](agent-coverage.md).

Subagentes seniores: [`.agents/agents/mcs-senior-*.md`](../.agents/agents/). Habilidades correspondentes: `mcs-senior-software`, `mcs-senior-cloud-ops`, `mcs-senior-review`.

## 1. Postura de Engenharia Senior

- Decisao orientada a evidencias: Prefira sempre metricas, saidas de linters, testes automatizados e probes de saude a opinioes e suposicoes.
- Foco no dominio Minecraft Forge: Desenvolva solucoes minimas, elegantes e diretamente alinhadas as necessidades do jogo, evitando complexidades acidentais.
- Trate a causa raiz: Proibido mascarar erros de compilacao, linters ou testes; solucione a origem do problema.
- Segregacao de competencias: Separe claramente o papel de **Engenharia de Software** (camadas Python, TDD, design hexagonal) do papel de **Cloud Ops** (paridade Docker Compose, Kubernetes AKS, Terraform e seguranca OIDC).

## 2. Engenharia de Software Senior (Python Hexagonal)

- Inversao de Dependencia Estrita: Os casos de uso devem depender exclusivamente de abstracoes (`typing.Protocol`), nunca de adaptadores concretos.
- Isolamento de Modelos Externos: Nunca permita que estruturas de dados de APIs externas (ex: Modrinth API) vazem para o dominio. Utilize DTOs intermediarios e mappers dedicados.
- Resiliencia na Borda: Implemente retries inteligentes, backoff exponencial e verificacao de checksum criptografico SHA-256 dentro dos adaptadores de I/O.
- Pureza de Tipagem: O codigo deve compilar sob `mypy --strict` com zero erros e sem supressoes genericas.
- Cobertura Completa: Manutencao de 100% de cobertura branch com testes unitarios baseados em fakes e testes de integracao para adaptadores.

## 3. Cloud Ops e DevOps Senior (Docker, Kubernetes e Azure)

- Seguranca de Contêineres: Dockerfiles em multi-stage build, ausencia de pacotes desnecessarios em tempo de execucao, execucao não-root e escaneamento continuo via Trivy.
- Resiliencia de Orquestracao: Manifestos Kubernetes Kustomize configurados com probes de startup, liveness e readiness baseadas em checagens TCP/RCON e politicas de PersistentVolumeClaim.
- Infraestrutura Declarativa e Testada: Modulos Terraform parametrizados e modulares, testados via `terraform test` e validados via TFLint e Tfsec.
- Identidade Federada OIDC: Pipelines do GitHub Actions autenticando na nuvem Azure exclusivamente via OIDC federado, eliminando segredos estaticos do repositorio.
