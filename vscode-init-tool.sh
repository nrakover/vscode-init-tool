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
    echo "FROM python:3-alpine" > $DOCKERFILE
    echo >> $DOCKERFILE
    echo "# Debugging: install debug library and establish debug port" >> $DOCKERFILE
    echo "RUN python3 -m pip install ptvsd==4.2.0" >> $DOCKERFILE
    echo "EXPOSE 3000" >> $DOCKERFILE
    echo >> $DOCKERFILE
    echo "# Application source" >> $DOCKERFILE
    echo "WORKDIR /app" >> $DOCKERFILE
    echo "ADD . /app" >> $DOCKERFILE
    echo >> $DOCKERFILE
    echo "# Install application dependencies" >> $DOCKERFILE
    echo "RUN python3 -m pip install -r requirements.txt" >> $DOCKERFILE
    echo >> $DOCKERFILE
    echo 'CMD [ "python3", "run.py", "--dev" ]' >> $DOCKERFILE
    echo >> $DOCKERFILE

    # Create .vscode directory
    VSC_DIR="$WORKSPACE_DIR/.vscode"
    mkdir $VSC_DIR

    # Create VS Code debug configurations
    DEBUG_CONFIG="$VSC_DIR/launch.json"
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

    # Create runner
    RUNNER_FILE="$WORKSPACE_DIR/run.py"
    echo > $RUNNER_FILE
    echo "DEBUG_ADDRESS = ('0.0.0.0', 3000)" >> $RUNNER_FILE
    echo >> $RUNNER_FILE
    echo "def doRun(devMode: bool=False):" >> $RUNNER_FILE
    echo "    print('Running {}...''.format('in DEV mode ' if devMode else ''))" >> $RUNNER_FILE
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

    echo "Done."
}