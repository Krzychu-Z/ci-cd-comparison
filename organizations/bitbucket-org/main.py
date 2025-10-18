import requests

from atlassian.bitbucket import Cloud

import bitbucket_config as bbconfig
import repo_functions as bbfuncs
        

def main():
    # Obtain OAuth2 token using client credentials grant
    resp = requests.post(
        "https://bitbucket.org/site/oauth2/access_token",
        auth=(bbconfig.CONFIG['CLIENT_ID'], bbconfig.CONFIG['CLIENT_SECRET']),
        data={"grant_type": "client_credentials"},
        timeout=30,
    )

    resp.raise_for_status()
    tok = resp.json()

    HEADERS = {"Authorization": f"Bearer {tok['access_token']}", "Content-Type": "application/json"}

    # Initialize Bitbucket Cloud client with OAuth2 token
    bitbucket = Cloud(oauth2={"client_id": bbconfig.CONFIG['CLIENT_ID'], "token": tok})

    # Create a new project in the specified workspace
    ws = bitbucket.workspaces.get(bbconfig.CONFIG['WORKSPACE_SLUG'])

    r = requests.get(f"{bbconfig.API}/workspaces/{bbconfig.CONFIG['WORKSPACE_SLUG']}/projects/{bbconfig.CONFIG['PROJECT_KEY']}", headers=HEADERS, timeout=20)
    if r.status_code != 200:
        project = ws.projects.create(
            key=bbconfig.CONFIG['PROJECT_KEY'],
            name=bbconfig.CONFIG['PROJECT_NAME'],
            is_private=bbconfig.CONFIG['IS_PRIVATE'],
            description=bbconfig.CONFIG['PROJECT_DESC']
        )

        print(f"Created project: {project.key} - {project.name}")
    else:
        project = ws.projects.get(bbconfig.CONFIG['PROJECT_KEY'])
        print(f"Project already exists: {project.key} - {project.name}")

    # Create repositories as per configuration
    for r in bbconfig.REPOS:
        slug = bbfuncs.create_repo_in_project(project, r["name"], headers_input=HEADERS, is_private=True)

        if r["import_url"]:
            # Use OAuth2 token for HTTPS git: user must be 'x-token-auth'
            dst = f"https://x-token-auth:{tok['access_token']}@bitbucket.org/{bbconfig.CONFIG['WORKSPACE_SLUG']}/{slug}.git"
            bbfuncs.mirror_import(r["import_url"], dst)
        else:
            # init pipelines-repository with README on master
            bbfuncs.init_readme(bbconfig.CONFIG["WORKSPACE_SLUG"], slug, headers_input=HEADERS, branch="master")

        # Force PRs to change main/master (block direct pushes)
        for branch in ("main", "master"):
            bbfuncs.block_pushes(bbconfig.CONFIG["WORKSPACE_SLUG"], slug, branch, HEADERS)

    print("Done.")

if __name__ == "__main__":
    main()