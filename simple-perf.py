from datetime import datetime, UTC
import os

from github import Github, Auth
from gitlab import Gitlab
import argparse
import requests
from tqdm import tqdm



# Github vars
GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
GITHUB_OWNER = "masters-thesis-org"
GITHUB_REPO_NAME = "small-project"
GITHUB_WORKFLOW_FILE = "simple.yml"
GITHUB_SELF_HOSTED_WORKFLOW_FILE = "k8s.yml"

# Gitlab vars
GITLAB_TOKEN = os.environ["GITLAB_TOKEN"]
GITLAB_OWNER = "masters-thesis-group"
GITLAB_REPO_NAME = "small-project"

# Bitbucket vars
BITBUCKET_CLIENT_ID = os.environ["BB_CLIENT_ID"]
BITBUCKET_CLIENT_SECRET = os.environ["BB_CLIENT_SECRET"]
WORKSPACE = "masters-thesis-workspace"       
REPO_SLUG = "small-project"             
CUSTOM_PIPELINE_NAME = "simple-performance"
CUSTOM_K8S_PIPELINE_NAME = "simple-performance-k8s"

REF = "master"

# Init API clients
auth = Auth.Token(GITHUB_TOKEN)
gh = Github(auth=auth)
gl = Gitlab("https://gitlab.com", private_token=GITLAB_TOKEN)


def get_bitbucket_access_token() -> str:
    token_url = "https://bitbucket.org/site/oauth2/access_token"
    resp = requests.post(
        token_url,
        auth=(BITBUCKET_CLIENT_ID, BITBUCKET_CLIENT_SECRET),
        data={"grant_type": "client_credentials"},
    )
    resp.raise_for_status()
    return resp.json()["access_token"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--self-hosted", action="store_true")
    args = parser.parse_args()


    for i in tqdm(range(2)):
        ###############################################
        # Github
        ###############################################
        repo = gh.get_repo(f"{GITHUB_OWNER}/{GITHUB_REPO_NAME}")
        if args.self_hosted:
            workflow = repo.get_workflow(GITHUB_SELF_HOSTED_WORKFLOW_FILE)
        else:
            workflow = repo.get_workflow(GITHUB_WORKFLOW_FILE)

        # Timestamp
        now = datetime.now(UTC)
        ns = now.microsecond * 1_000
        time_stamp = f"{now:%H:%M:%S}.{ns:09d}"

        # Trigger dispatch
        response = workflow.create_dispatch(
            ref=REF,
            inputs={
                "pipeline-call-ts": time_stamp
            }
        )

        print(f"Dispatched Github workflow ({i}):", response)

        ###############################################
        # Gitlab
        ###############################################
        project = gl.projects.get(f"{GITLAB_OWNER}/{GITLAB_REPO_NAME}")

        # Timestamp
        now = datetime.now(UTC)
        ns = now.microsecond * 1_000
        time_stamp = f"{now:%H:%M:%S}.{ns:09d}"

        # create pipeline with variable PIPELINE_CALL_TS
        if args.self_hosted:
            pipeline = project.pipelines.create({
                "ref": REF,
                "variables": [
                    {"key": "PIPELINE_CALL_TS", "value": time_stamp},
                    {"key": "PIPELINE_TYPE", "value": "k8s-perf"}
                ],
            })
        else:
            pipeline = project.pipelines.create({
                "ref": REF,
                "variables": [
                    {"key": "PIPELINE_CALL_TS", "value": time_stamp},
                    {"key": "PIPELINE_TYPE", "value": "simple-perf"}
                ],
            })

        print(f"Dispatched Gitlab pipeline ({i}):", pipeline.id)

        ###############################################
        # Bitbucket
        ###############################################
        access_token = get_bitbucket_access_token()
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }

        # Timestamp
        now = datetime.now(UTC)
        ns = now.microsecond * 1_000
        time_stamp = f"{now:%H:%M:%S}.{ns:09d}"

        url = f"https://api.bitbucket.org/2.0/repositories/{WORKSPACE}/{REPO_SLUG}/pipelines/"

        payload = {
            "target": {
                "ref_type": "branch",
                "type": "pipeline_ref_target",
                "ref_name": REF,
                "selector": {
                    "type": "custom",
                    "pattern": CUSTOM_K8S_PIPELINE_NAME if args.self_hosted else CUSTOM_PIPELINE_NAME,
                }
            },
            "variables": [
                {
                    "key": "PIPELINE_CALL_TS",
                    "value": time_stamp,
                    "secured": False,
                }
            ],
        }

        resp = requests.post(url, json=payload, headers=headers)
        resp.raise_for_status()
        data = resp.json()

        print(f"Dispatched Bitbucket pipeline ({i}):", data.get("uuid"), data.get("state", {}).get("name"))


if __name__ == "__main__":
    main()