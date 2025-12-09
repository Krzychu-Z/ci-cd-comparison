import requests
import tempfile
import subprocess
import shlex
import re

import bitbucket_config as bbconfig


def _slug(name: str) -> str:
    s = name.strip().lower().replace(" ", "-")
    return re.sub(r"[^a-z0-9\-]+", "-", s).strip("-")

def create_repo_in_project(proj, name, headers_input, is_private=True):
    """
    Create repo in a Bitbucket Cloud project. Idempotent.
    proj: Cloud project object (or project key string)
    headers_input: {"Authorization": "Bearer <token>"}
    """
    workspace = bbconfig.CONFIG['WORKSPACE_SLUG']

    project_key = getattr(proj, "key", proj)  # accept object or string
    slug = _slug(name)

    url = f"{bbconfig.API}/repositories/{workspace}/{slug}"
    payload = {"scm": "git", "is_private": is_private, "project": {"key": project_key}}

    r = requests.post(url, headers={**headers_input, "Content-Type": "application/json"},
                      json=payload, timeout=30)

    # Already exists? Bitbucket returns 400/409 with 'exists' in body
    if r.status_code in (200, 201):
        return slug
    if r.status_code in (400, 409) and "exists" in r.text.lower():
        return slug

    r.raise_for_status()
    return slug

def grant_user_write_access(workspace: str, slug: str, user_account_id: str, headers_input):
    """
    Give a specific Bitbucket user explicit WRITE permission to a repository.

    workspace: workspace slug
    slug:      repo slug
    user_account_id: Atlassian account_id of the user (e.g. '557058:ba89...')
                     Must already be a member of the workspace.
    """
    url = f"{bbconfig.API}/repositories/{workspace}/{slug}/permissions-config/users/{user_account_id}"
    payload = {"permission": "write"}

    r = requests.put(
        url,
        headers={**headers_input, "Content-Type": "application/json"},
        json=payload,
        timeout=30,
    )

    if r.status_code not in (200, 201):
        r.raise_for_status()

def init_readme(workspace, slug, headers_input, branch="master"):
    files = {
        "message": (None, "initial commit"),
        "branch": (None, branch),
        "README.md": (None, f"# {slug}\n\nInitialized by automation.\n"),
    }
    r = requests.post(
        f"{bbconfig.API}/repositories/{workspace}/{slug}/src",
        headers=headers_input,
        files=files,
        timeout=60,
    )
    r.raise_for_status()

def mirror_import(src_url, dst_https):
    with tempfile.TemporaryDirectory() as td:
        subprocess.check_call(shlex.split(f"git clone --mirror {src_url} {td}"))
        subprocess.check_call(["git", "--git-dir", td, "push", "--mirror", dst_https])
