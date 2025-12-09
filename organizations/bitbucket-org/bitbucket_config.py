import os

API = "https://api.bitbucket.org/2.0"

CONFIG = {
    'WORKSPACE_SLUG': "masters-thesis-workspace",
    'PROJECT_KEY': "MTP",                           
    'PROJECT_NAME': "masters-thesis-project",
    'PROJECT_DESC': "Masters thesis project (created via atlassian-python-api)",
    'IS_PRIVATE': True,
    'CLIENT_ID': os.getenv("BB_CLIENT_ID"),
    'CLIENT_SECRET': os.getenv("BB_CLIENT_SECRET"),
    'USER_ACCOUNT_ID': os.getenv("BB_USER_ACCOUNT_ID")
}

REPOS = [
    {
        "name": "small-project",
        "description": "Imported from GitHub template",
        "import_url": "https://github.com/Krzychu-Z/MODBUS-CRC16-Golang.git"
    },
    {
        "name": "large-project",
        "description": "Imported from GitHub template",
        "import_url": "https://github.com/Krzychu-Z/rust-compiler.git"
    },
    {
        "name": "pipelines-repository",
        "description": "Empty repo initialized with README",
        "import_url": None
    }
]