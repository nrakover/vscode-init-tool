function init_vscode_workspace() {

    PROJECT_LANG="python" # only supporting python for now
    WORKSPACE_DIR=`pwd`
    
    if (( $# == 1)); then
        WORKSPACE_DIR=`realpath $1`
    elif (( $# > 1 )); then
        echo "Error: expected at most one argument, found $#"
        return;
    fi

    echo "Initializing $PROJECT_LANG workspace in $WORKSPACE_DIR ..."

    # Create Dockerfile
    DOCKERFILE="$WORKSPACE_DIR/Dockerfile"
    if [[ ! -e $DOCKERFILE ]]; then
        echo " - Dockerfile"
        echo "FROM python:3-alpine" > $DOCKERFILE
        echo >> $DOCKERFILE
        echo "# Debugging: install debug library and establish debug port" >> $DOCKERFILE
        echo "RUN python3 -m pip install ptvsd==4.2.0" >> $DOCKERFILE
        echo "EXPOSE 3000" >> $DOCKERFILE
        echo >> $DOCKERFILE
        echo "# Application source" >> $DOCKERFILE
        echo "WORKDIR /app" >> $DOCKERFILE
        echo "COPY . /app" >> $DOCKERFILE
        echo >> $DOCKERFILE
        echo "# Install application dependencies" >> $DOCKERFILE
        echo "RUN python3 -m pip install -r requirements.txt" >> $DOCKERFILE
        echo >> $DOCKERFILE
        echo 'CMD [ "python3", "-u", "run.py", "--dev" ]' >> $DOCKERFILE
        echo >> $DOCKERFILE
    fi

    # .dockerignore
    DOCKERIGNORE_FILE="$WORKSPACE_DIR/.dockerignore"
    if [[ ! -e $DOCKERIGNORE_FILE ]]; then
        echo " - .dockerignore"
        echo > $DOCKERIGNORE_FILE
        echo "Dockerfile" >> $DOCKERIGNORE_FILE
        echo ".dockerignore" >> $DOCKERIGNORE_FILE
        echo ".git" >> $DOCKERIGNORE_FILE
        echo ".vscode" >> $DOCKERIGNORE_FILE
        echo ".DS_Store" >> $DOCKERIGNORE_FILE
        echo ".gitignore" >> $DOCKERIGNORE_FILE
        echo "README.md" >> $DOCKERIGNORE_FILE
    fi

    # Create .vscode directory
    VSC_DIR="$WORKSPACE_DIR/.vscode"
    if [[ ! -e $VSC_DIR ]]; then
        mkdir $VSC_DIR
    fi

    # Create VS Code debug configurations
    DEBUG_CONFIG="$VSC_DIR/launch.json"
    if [[ ! -e $DEBUG_CONFIG ]]; then
        echo " - launch.json for debug configurations"
        echo '{' > $DEBUG_CONFIG
        echo '    // Use IntelliSense to learn about possible attributes.' >> $DEBUG_CONFIG
        echo '    // Hover to view descriptions of existing attributes.' >> $DEBUG_CONFIG
        echo '    "version": "0.2.0",' >> $DEBUG_CONFIG
        echo '    "configurations": [' >> $DEBUG_CONFIG
        echo '        {' >> $DEBUG_CONFIG
        echo '            "name": "Python: Docker",' >> $DEBUG_CONFIG
        echo '            "type": "python",' >> $DEBUG_CONFIG
        echo '            "request": "attach",' >> $DEBUG_CONFIG
        echo '            "pathMappings": [' >> $DEBUG_CONFIG
        echo '                {' >> $DEBUG_CONFIG
        echo '                    "localRoot": "${workspaceFolder}",' >> $DEBUG_CONFIG
        echo '                    "remoteRoot": "/app"' >> $DEBUG_CONFIG
        echo '                }' >> $DEBUG_CONFIG
        echo '            ],' >> $DEBUG_CONFIG
        echo '            "port": 3000,' >> $DEBUG_CONFIG
        echo '            "host": "localhost"' >> $DEBUG_CONFIG
        echo '        }' >> $DEBUG_CONFIG
        echo '    ]' >> $DEBUG_CONFIG
        echo '}' >> $DEBUG_CONFIG
        echo >> $DEBUG_CONFIG
    fi

    # Create python virtual environment
    VENV_NAME=".pyenv"
    VENV_DIR="$VSC_DIR/$VENV_NAME"
    if [[ ! -e $VENV_DIR ]]; then
        python3 -m venv $VENV_DIR
        $VENV_DIR/bin/python3 -m pip install ptvsd==4.2.0 # install debugger library
        echo " - python3 venv at $VENV_DIR"
    fi

    # Configure worspace to use virtual environment
    VENV_PYTHON_PATH="\${workspaceFolder}/.vscode/$VENV_NAME/bin/python3"
    SETTINGS_FILE="$VSC_DIR/settings.json"
    if [[ ! -e $SETTINGS_FILE ]]; then
        echo " - settings.json for workspace preferences"
        echo > $SETTINGS_FILE
        echo "{" >> $SETTINGS_FILE
        echo "  \"python.pythonPath\": \"$VENV_PYTHON_PATH\"" >> $SETTINGS_FILE
        echo "}" >> $SETTINGS_FILE
    fi

    # Create workspace task configurations
    TASKS_FILE="$VSC_DIR/tasks.json"
    if [[ ! -e $TASKS_FILE ]]; then
        echo " - tasks.json for build task configurations"
        WORKSPACE_BASEPATH=${WORKSPACE_DIR##*/}
        echo "{" >> $TASKS_FILE
        echo "    \"version\": \"2.0.0\"," >> $TASKS_FILE
        echo "    \"tasks\": [" >> $TASKS_FILE
        echo "        {" >> $TASKS_FILE
        echo "            \"label\": \"Install Deps\"," >> $TASKS_FILE
        echo "            \"type\": \"shell\"," >> $TASKS_FILE
        echo "            \"command\": \"\${workspaceFolder}/.vscode/$VENV_NAME/bin/python3 -m pip install -r \${workspaceFolder}/requirements.txt\"," >> $TASKS_FILE
        echo "            \"problemMatcher\": []" >> $TASKS_FILE
        echo "        }," >> $TASKS_FILE
        echo "        {" >> $TASKS_FILE
        echo "            \"label\": \"Build Docker Image\"," >> $TASKS_FILE
        echo "            \"type\": \"shell\"," >> $TASKS_FILE
        echo "            \"command\": \"docker build --pull --rm -t \${input:imageName} .\"," >> $TASKS_FILE
        echo "            \"options\": {" >> $TASKS_FILE
        echo "                \"cwd\": \"\${workspaceFolder}\"" >> $TASKS_FILE
        echo "            }," >> $TASKS_FILE
        echo "            \"problemMatcher\": []" >> $TASKS_FILE
        echo "        }," >> $TASKS_FILE
        echo "        {" >> $TASKS_FILE
        echo "            \"label\": \"Build\"," >> $TASKS_FILE
        echo "            \"dependsOn\": [" >> $TASKS_FILE
        echo "                \"Install Deps\"," >> $TASKS_FILE
        echo "                \"Build Docker Image\"" >> $TASKS_FILE
        echo "            ]," >> $TASKS_FILE
        echo "            \"group\": {" >> $TASKS_FILE
        echo "                \"kind\": \"build\"," >> $TASKS_FILE
        echo "                \"isDefault\": true" >> $TASKS_FILE
        echo "            }" >> $TASKS_FILE
        echo "        }" >> $TASKS_FILE
        echo "    ]," >> $TASKS_FILE
        echo "    \"inputs\": [" >> $TASKS_FILE
        echo "        {" >> $TASKS_FILE
        echo "            \"type\": \"promptString\"," >> $TASKS_FILE
        echo "            \"id\": \"imageName\"," >> $TASKS_FILE
        echo "            \"description\": \"Name your image.\"," >> $TASKS_FILE
        echo "            \"default\": \"$WORKSPACE_BASEPATH:local\"" >> $TASKS_FILE
        echo "        }" >> $TASKS_FILE
        echo "    ]" >> $TASKS_FILE
        echo "}" >> $TASKS_FILE
    fi

    # Create runner
    RUNNER_FILE="$WORKSPACE_DIR/run.py"
    if [[ ! -e $RUNNER_FILE ]]; then
        echo > $RUNNER_FILE
        echo "DEBUG_ADDRESS = ('0.0.0.0', 3000)" >> $RUNNER_FILE
        echo >> $RUNNER_FILE
        echo "def doRun(devMode: bool=False):" >> $RUNNER_FILE
        echo "    print('Running {}...'.format('in DEV mode ' if devMode else ''))" >> $RUNNER_FILE
        echo >> $RUNNER_FILE
        echo "if __name__ == '__main__':" >> $RUNNER_FILE
        echo "    import sys" >> $RUNNER_FILE
        echo "    devMode = False" >> $RUNNER_FILE
        echo "    if '--dev' in sys.argv:" >> $RUNNER_FILE
        echo "        devMode = True" >> $RUNNER_FILE
        echo >> $RUNNER_FILE
        echo "        # enable VS Code debugging via ptvsd" >> $RUNNER_FILE
        echo "        import ptvsd" >> $RUNNER_FILE
        echo "        print('Enabling debug on {}'.format(DEBUG_ADDRESS))" >> $RUNNER_FILE
        echo "        ptvsd.enable_attach(address=DEBUG_ADDRESS, redirect_output=True)" >> $RUNNER_FILE
        echo "    " >> $RUNNER_FILE
        echo "    doRun(devMode)" >> $RUNNER_FILE
        echo >> $RUNNER_FILE
    fi

    # Create requirements.txt
    REQS_FILE="$WORKSPACE_DIR/requirements.txt"
    if [[ ! -e $REQS_FILE ]]; then
        touch $REQS_FILE
    fi

    echo "Done."
}