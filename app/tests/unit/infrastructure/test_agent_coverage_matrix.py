import json
import re
from pathlib import Path


def _get_repo_root() -> Path:
    return Path(__file__).resolve().parent.parent.parent.parent.parent


def _parse_matrix_rows(coverage_path: Path) -> list[tuple[str, str, str, str]]:
    content = coverage_path.read_text(encoding="utf-8")
    lines = content.splitlines()
    in_table = False
    rows: list[tuple[str, str, str, str]] = []
    for line in lines:
        if line.startswith("| Superficie |"):
            in_table = True
            continue
        if in_table:
            if line.startswith("|---"):
                continue
            if not line.startswith("|") or not line.strip():
                break
            parts = [part.strip() for part in line.split("|")[1:-1]]
            if len(parts) >= 4:
                rows.append((parts[0], parts[1], parts[2], parts[3]))
    return rows


def test_coverage_matrix_table_exists_and_parses() -> None:
    repo_root = _get_repo_root()
    coverage_path = repo_root / "docs" / "agent-coverage.md"
    assert coverage_path.is_file()
    rows = _parse_matrix_rows(coverage_path)
    assert len(rows) >= 10


def test_coverage_matrix_docs_exist() -> None:
    repo_root = _get_repo_root()
    coverage_path = repo_root / "docs" / "agent-coverage.md"
    rows = _parse_matrix_rows(coverage_path)
    docs_dir = repo_root / "docs"
    for _, doc_col, _, _ in rows:
        matches = re.findall(r"\[([^\]]+)\]\(([^)]+)\)", doc_col)
        for _, link in matches:
            target_path = (docs_dir / link).resolve()
            assert target_path.is_file(), f"Documento referenciado nao existe: {target_path}"


def test_coverage_matrix_rules_match_filesystem() -> None:
    repo_root = _get_repo_root()
    coverage_path = repo_root / "docs" / "agent-coverage.md"
    rows = _parse_matrix_rows(coverage_path)
    rules_dir = repo_root / ".agents" / "rules"
    assert rules_dir.is_dir()

    matrix_rules: set[str] = set()
    for _, _, rule_col, _ in rows:
        rules = re.findall(r"`([^`]+\.mdc)`", rule_col)
        for rule in rules:
            matrix_rules.add(rule)

    filesystem_rules = {path.name for path in rules_dir.glob("*.mdc")}
    assert matrix_rules == filesystem_rules


def test_coverage_matrix_skills_match_filesystem() -> None:
    repo_root = _get_repo_root()
    coverage_path = repo_root / "docs" / "agent-coverage.md"
    rows = _parse_matrix_rows(coverage_path)
    skills_dir = repo_root / ".agents" / "skills"
    assert skills_dir.is_dir()

    matrix_skills: set[str] = set()
    for _, _, _, skill_col in rows:
        skills = re.findall(r"`([^`]+)`", skill_col)
        for skill in skills:
            if skill != "—":
                matrix_skills.add(skill)

    filesystem_skills = {path.parent.name for path in skills_dir.glob("*/SKILL.md")}
    assert matrix_skills == filesystem_skills


def test_coverage_matrix_subagents_exist() -> None:
    repo_root = _get_repo_root()
    agents_dir = repo_root / ".agents" / "agents"
    assert agents_dir.is_dir()
    expected_agents = {
        "mcs-senior-cloud-ops.md",
        "mcs-senior-qa-auditor.md",
        "mcs-senior-software-engineer.md",
    }
    present_agents = {path.name for path in agents_dir.glob("*.md")}
    assert expected_agents.issubset(present_agents)


def test_cursor_compatibility_bridge() -> None:
    repo_root = _get_repo_root()
    cursor_dir = repo_root / ".cursor"
    assert cursor_dir.is_dir()
    for item in ("rules", "skills", "agents", "mcp.json"):
        path = cursor_dir / item
        assert path.exists(), f"Ponte do Cursor ausente: {path}"
        assert path.is_symlink(), f"Item no .cursor deve ser link simbolico: {path}"


def test_mcp_config_valid() -> None:
    repo_root = _get_repo_root()
    mcp_path = repo_root / ".agents" / "mcp.json"
    assert mcp_path.is_file()
    payload = json.loads(mcp_path.read_text(encoding="utf-8"))
    assert isinstance(payload, dict)
    assert "mcpServers" in payload
