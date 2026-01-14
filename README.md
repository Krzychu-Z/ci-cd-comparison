# Analysis and Evaluation of CI/CD Platforms Integrated with Git Hosting Services: A Case Study of GitHub Actions, GitLab CI/CD, and Bitbucket Pipelines

<!-- vscode-markdown-toc -->
* 1. [Abstract](#Abstract)
* 2. [Repository structure](#Repositorystructure)
* 3. [Deployment instructions](#Deploymentinstructions)
	* 3.1. [Organizations deployment](#Organizationsdeployment)
		* 3.1.1. [Github organization deployment](#Githuborganizationdeployment)
		* 3.1.2. [Gitlab organization deployment](#Gitlaborganizationdeployment)
		* 3.1.3. [Bitbucket organization deployment](#Bitbucketorganizationdeployment)

##  1. <a name='Abstract'></a>Abstract
The aim of this master’s thesis is to conduct a comparative analysis of the Continuous Integration
and Continuous Delivery (CI/CD) pipelines offered by the three most popular Git hosting version
control system providers. This thesis provides a holistic comparison of the GitHub Actions, GitLab
CI/CD, and Bitbucket Pipelines services. The first chapter defines the objectives of the thesis, the
motivations behind selecting this research topic, the scope of the research, the research questions,
and the structure of this document. This section is set in the context of growing market demand for
automating the lifecycle of software, from the release of a new version, through testing, to deployment
in a production environment.

##  2. <a name='Repositorystructure'></a>Repository structure
```
.
├── environment
│   ├── bitbucket-arc.sh
│   ├── eks.tf
│   ├── github-arc.sh
│   ├── gitlab-arc.sh
│   ├── outputs.tf
│   ├── s3.tf
│   ├── terraform.tf
│   └── variables.tf
├── LICENSE
├── organizations
│   ├── bitbucket-org
│   │   ├── bitbucket_config.py
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── repo_functions.py
│   │   ├── requirements.txt
│   │   └── venv
│   ├── github-org
│   │   ├── organization.tf
│   │   ├── repos.tf
│   │   ├── terraform.tf
│   │   └── variables.tf
│   └── gitlab-org
│       ├── group.tf
│       ├── repos.tf
│       ├── terraform.tf
│       └── variables.tf
├── README.md
├── requirements.txt
└── run.py
```

##  3. <a name='Deploymentinstructions'></a>Deployment instructions
###  3.1. <a name='Organizationsdeployment'></a>Organizations deployment
Tools required for this part:
- Terraform CLI (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Python 3.9+ (https://www.python.org/downloads/)
- Github user account (https://www.github.com)
- Gitlab user account (https://about.gitlab.com/)
- Bitbucket user account (https://bitbucket.org/product/)

This instruction is designed for Ubuntu Linux OS. But it may work fine also with other shell terminals.
####  3.1.1. <a name='Githuborganizationdeployment'></a>Github organization deployment
In `github-org/`

1. Generate Personal Access Token with organization, repo and file level accesses (https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)

2. Export personal access token to shell environment
```
export GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwxyz1234567890
```

3. In `github-org/terraform.tf` replace path in `backend "local"` with your own custom statefile location - you can also replace this backend definition with remote backend (https://developer.hashicorp.com/terraform/language/backend/remote).

4. Use Terraform CLI standard workflow to deploy resources
```
terraform init
terraform plan
terraform apply
```

####  3.1.2. <a name='Gitlaborganizationdeployment'></a>Gitlab organization deployment
In `gitlab-org/`

1. Generate Personal Access Token with organization, repo and file level accesses (https://docs.gitlab.com/user/profile/personal_access_tokens/)

2. Export personal access token to shell environment
```
export GITLAB_TOKEN=glpat-12-aaaaaaaaaaaaaaaaaaaaaaaaaa...
```

3. In `gitlab-org/terraform.tf` replace path in `backend "local"` with your own custom statefile location - you can also replace this backend definition with remote backend (https://developer.hashicorp.com/terraform/language/backend/remote).

4. Use Terraform CLI standard workflow to deploy resources
```
terraform init
terraform plan
terraform apply
```

####  3.1.3. <a name='Bitbucketorganizationdeployment'></a>Bitbucket organization deployment
In `bitbucket-org/`

1. Create Bitbucket OAuth consumer and associated client key and secret (https://support.atlassian.com/bitbucket-cloud/docs/use-oauth-on-bitbucket-cloud)

2. Create local Python virtual environment (venv (https://docs.python.org/3/library/venv.html)).
```
python -m venv <venv>
```

3. Activate new venv and install required dependencies
```
source <venv>/bin/activate
pip install -r requirements.txt
```

4. Export Bitbucket OAuth keys to shell environment
```
export BB_CLIENT_ID=aaaaaaaaaaaaaaaaaa
export BB_CLIENT_SECRET=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
```

5. Run Python module and create resources in Bitbucket account
```
python main.py
```
