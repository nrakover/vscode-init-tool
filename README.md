# vscode-init-tool
Simple script to bootstrap a Visual Studio Code workspace for Dockerized Python development

## Requirements
The only requirement to _run_ the tool is `python3`.

Now, to make use of a workspace created with the tool, you will need [Visual Studio Code](https://code.visualstudio.com/) and [Docker](https://www.docker.com/).

## Usage
`source vscode-init-tool.sh` (just once per session)

`init_vscode_workspace [DIRECTORY]` will bootstrap `DIRECTORY`, if specified, or the current working directory
