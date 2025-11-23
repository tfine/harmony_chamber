"""
Minimal implementation executor that turns Harmony implementation mandates into GitHub PRs.
Uses GLM 4.6 (z.ai) optionally to draft a plan; otherwise creates a placeholder change.
"""
import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path
from typing import Any, Dict, Optional

import httpx
from github import Github


def load_env() -> Dict[str, str]:
    github_token = os.getenv("GITHUB_TOKEN")
    harmony_status_url = os.getenv("HARMONY_IMPL_STATUS_URL")
    glm_api_key = os.getenv("GLM_API_KEY")
    if not github_token or not harmony_status_url:
        raise SystemExit("GITHUB_TOKEN and HARMONY_IMPL_STATUS_URL are required")
    return {
        "github_token": github_token,
        "harmony_status_url": harmony_status_url.rstrip("/"),
        "glm_api_key": glm_api_key,
    }


def glm_plan(prompt: str, glm_api_key: Optional[str]) -> str:
    if not glm_api_key:
        return "No GLM key provided; using placeholder plan."
    try:
        resp = httpx.post(
            "https://api.zhipu.ai/v1/chat/completions",
            headers={"Authorization": f"Bearer {glm_api_key}"},
            json={
                "model": "glm-4.6",
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a senior engineer drafting a short implementation plan.",
                    },
                    {"role": "user", "content": prompt},
                ],
            },
            timeout=30.0,
        )
        resp.raise_for_status()
        data = resp.json()
        return data["choices"][0]["message"]["content"]
    except Exception:
        return "GLM plan unavailable; proceed with baseline change."


def clone_repo(repo_url: str, token: str) -> Path:
    tmp = Path(tempfile.mkdtemp(prefix="impl_exec_"))
    auth_url = repo_url.replace("https://", f"https://{token}:x-oauth-basic@")
    subprocess.check_call(["git", "clone", auth_url, str(tmp)])
    return tmp


def create_branch(repo_path: Path, branch: str) -> None:
    subprocess.check_call(["git", "-C", str(repo_path), "checkout", "-b", branch])


def commit_and_push(repo_path: Path, message: str, branch: str) -> None:
    subprocess.check_call(["git", "-C", str(repo_path), "add", "."])
    subprocess.check_call(["git", "-C", str(repo_path), "commit", "-m", message])
    subprocess.check_call(["git", "-C", str(repo_path), "push", "origin", branch])


def open_pr(repo_full_name: str, branch: str, base: str, title: str, body: str, token: str) -> str:
    gh = Github(token)
    repo = gh.get_repo(repo_full_name)
    pr = repo.create_pull(title=title, body=body, head=branch, base=base)
    return pr.html_url


def post_status(env: Dict[str, str], impl_id: str, status: str, pr_url: Optional[str] = None, branch: Optional[str] = None, error: Optional[str] = None) -> None:
    payload: Dict[str, Any] = {
        "id": impl_id,
        "status": status,
        "pr_url": pr_url,
        "branch": branch,
        "error": error,
    }
    httpx.post(env["harmony_status_url"], json=payload, timeout=10.0)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mandate", required=True, help="Path to mandate JSON")
    parser.add_argument("--base-branch", default="main")
    args = parser.parse_args()

    env = load_env()
    mandate = json.loads(Path(args.mandate).read_text())
    impl_id = mandate["id"]
    repo_url = mandate["target_repo"]
    branch_name = f"{mandate.get('branch_hint', 'bill')}-{impl_id}"

    post_status(env, impl_id, "running", None, branch_name)

    plan = glm_plan(
        f"Bill: {mandate['bill_title']}\nSummary: {mandate['bill_summary']}\nGoal: implement changes and open a PR.",
        env["glm_api_key"],
    )

    repo_path = clone_repo(repo_url, env["github_token"])
    create_branch(repo_path, branch_name)

    # Placeholder change: write plan to IMPLEMENTATION_PLAN.md
    plan_path = repo_path / "IMPLEMENTATION_PLAN.md"
    plan_content = f"# Plan for {mandate['bill_title']}\n\nMandate ID: {impl_id}\nConstitution: {mandate['constitution_id']}\n\n{plan}\n"
    plan_path.write_text(plan_content)

    commit_and_push(repo_path, f"Bill {mandate['bill_id']}: plan", branch_name)
    pr_url = open_pr(
        repo_full_name=repo_url.split(":")[-1].replace(".git", ""),
        branch=branch_name,
        base=args.base_branch,
        title=f"[Bill {mandate['bill_id']}] {mandate['bill_title']}",
        body=plan_content,
        token=env["github_token"],
    )

    post_status(env, impl_id, "completed", pr_url, branch_name)


if __name__ == "__main__":
    main()
