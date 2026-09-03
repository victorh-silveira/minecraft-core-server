---
name: mcs-senior-review
description: >-
  Revisa mudancas contra a barra senior MCS (DIP, Docker, AKS/TF, CI/CD, QA
  gates) e reporta achados priorizados. Use when the user asks for code review
  senior, auditoria de PR, review de infra/CI, or mentions mcs-senior-review /
  engineering-senior-bar.
---

# Senior Review

## Processo

1. Identificar superficies tocadas via `docs/agent-coverage.md`
2. Ler `docs/engineering-senior-bar.md` + rules `mcs-senior-*` relevantes
3. Inspecionar diff (codigo, YAML, TF, workflow)
4. Classificar achados: Bloqueante / Importante / Nit
5. Citar arquivo e comportamento esperado; propor correcao concreta
6. Se nada bloqueante: declarar aprovado com ressalvas (se houver)

## Lentes

| Area | Procurar |
|------|----------|
| Hexagonal | Import ilegal; DTO vazando; log no use case |
| Sync | Hash skip; 429 sem backoff; secret em log |
| Docker | root, latest, sem HEALTHCHECK/signal |
| K8s/TF | probes misturados; secret bake-in; state/OIDC fraco |
| CI | skip-cd burla QA; latest; Trivy/Hadolint ausente |
| QA | cov < 100%; type ignore; `# nosec` injustificado |

## Saida

```
## Veredito
Aprovado | Aprovado com ressalvas | Bloqueado

## Achados
- [Bloqueante] path — problema — correcao
- [Importante] ...
- [Nit] ...

## Gates sugeridos
make app-lint / app-test / app-security (WSL)
```

Sem emojis. PT-BR.
