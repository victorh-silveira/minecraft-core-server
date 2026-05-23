export default {
  // ---- CONFIGURACAO BASE ----
  extends: ["@commitlint/config-conventional"],

  rules: {
    // ---- TIPOS DE COMMIT (type-enum) ----
    "type-enum": [
      2,
      "always",
      [
        "build",
        "chore",
        "ci",
        "docs",
        "feat",
        "fix",
        "perf",
        "qa",
        "refactor",
        "revert",
        "style",
        "test",
      ],
    ],

    // ---- ESCOPOS DO PROJETO MINECRAFT (scope-enum) ----
    "scope-enum": [
      2,
      "always",
      [
        "all",
        "config",
        "deps",
        "docker",
        "domain",
        "infra",
        "interface",
        "mods",
        "release",
        "repo",
        "scripts",
        "test",
        "tools",
      ],
    ],

    // ---- REGRAS DE FORMATACAO E OBRIGATORIEDADE ----
    "type-case": [2, "always", "lower-case"],
    "type-empty": [2, "never"],
    "scope-empty": [2, "never"],
    "subject-empty": [2, "never"],
    "subject-case": [0],
    "body-leading-blank": [2, "always"],
    "body-empty": [2, "never"],
    "header-max-length": [2, "always", 100],
  },
};
