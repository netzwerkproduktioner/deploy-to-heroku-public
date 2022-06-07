#!/bin/sh

cd /opt/

# set your vars or take fallbacks  
DEPLOY_BOT_NAME=${DEPLOY_BOT_NAME:-deployment-robot}
DEPLOY_BOT_MAIL=${DEPLOY_BOT_MAIL:-robot.heroku@domain.test}
HEROKU_BOT_LOGIN_USERNAME=${HEROKU_BOT_LOGIN_USERNAME:-heroku@domain.test}

HEROKU_APP_NAME=${HEROKU_APP_NAME:-default-app}

# absolute paths (be aware of your container structure)
BUILD=${HEROKU_DOCKER_REPO_BUILD_PATH:-/opt/heroku/repos/build}
# ORIGN = folder where your Heroko Git gets cloned  
ORIGN=${HEROKU_DOCKER_REPO_ORIGN_PATH:-/opt/heroku/repos/orign}


# ssh keys for usage with Heroku Git  
if [[ -e /root/.ssh/id_rsa && -e /root/.ssh/id_rsa.pub ]] # -e test if exists  
then
    echo "ssh key pair found.."
    heroku keys:add --yes
else
    echo "create ssh key"
    # generate ssh key pair without passphrase
    ssh-keygen -t rsa -b 4096 -C "${DEPLOY_BOT_MAIL}" -f ~/.ssh/id_rsa -N '' 
    # automatically add keys to heroku
    heroku keys:add --yes   
fi

if [ "$?" == "0" ]
then
    # generate a .netrc file and store it into the users directory (i.e. /root)
    printf "machine git.heroku.com\n  login ${HEROKU_BOT_LOGIN_USERNAME}\n  password ${HEROKU_API_KEY}" >> /root/.netrc
    echo ".netrc file created."
else 
    echo "an error occured!"
fi


findAndRemoveGitAndJunkFiles() {
    if [ -n "$1" ]
    then
        # remove obsolete system files (i.e. .DS_Store, ..) 
        find ${1} -name '.DS_Store' -delete
        # add more if you like..
        
        # remove the .git/.github folder if your build was a repo folder  
        find . -regex '^\.\/\.git.*' -delete
    else
        : # do nothing  
    fi

    return 0
}

cleanupFolder() {
    # expects the absolute path to folder, which should be cleaned  
    # (i.e. /opt/path/to/folder)  
    # removes also hidden files like .git, ..
    if [ -n "$1" ]
    then
        # delete the hidden files too (errors for '.' and '..' are hidden)
        echo "Cleanup. Delete file(s) from ${1}.."
        rm -Rf ${1}/* && rm -Rf ${1}/.* 2> /dev/null 
    else
        : # do nothing, you could add a default dir/folder like './' here (but it's dangerous!)
    fi

    return 0
}

findAndRemoveGitAndJunkFiles ${BUILD}

# check if given directory exists and if there are files in it  
# -d : is file and directory  
# -n : is not empty  
if [ -d "${BUILD}" ] && files=$(ls -A -- "${BUILD}") && [ -n "${files}" ]
then 
    echo "build files found.."
    
    # (re)create and enter folder for local repo  
    mkdir -p ${ORIGN} && cd ${ORIGN}  

    # avoid github actions error 'unsafe repository'
    git config --global --add safe.directory ${ORIGN}  
   
    # @see: https://devcenter.heroku.com/articles/git  
    # clone the app repo to orign folder (note the './', cloning without a app-subfolder)  
    heroku git:clone --app ${HEROKU_APP_NAME} ${ORIGN}

    # remove all files from the local repo folder except the .git folder
    # find all files and folders in this subfolder without the regex-pattern and delete them
    # this will delete all files and folders in the directory '.' without the .git folder and all its subfolders  
    cd ${ORIGN}
    find . ! -regex '^\.\/\.git.*' -delete
    # delete all .gitignore files which have been skipped by deletion above  
    cd ${ORIGN}
    find . -name '.gitignore' -delete

    # sync all files from build folder to local repo folder  
    # rsync recursive (-r) all files with preserve attributes (-a)
    rsync -ar ${BUILD}/ ${ORIGN}

    # create commit message/info with the hash from the initial deployment commit
    COMMIT=$(git rev-parse --short ${GITHUB_SHA}) # this needs access to env GITHUB_SHA from deployment scope 
    # 'fallback' commit message
    COMMIT_DEFAULT="unknown commit"

    if [ "${DEPLOY_DRYRUN}" = "FALSE" -o "${DEPLOY_DRYRUN}" = "false" ]
    then  
        echo "run in deployment mode.."
        DRY_RUN=""
    else
        # defaults to all strings without 'false/FALSE'  
        echo "run in dry-run mode.."
        DRY_RUN="--dry-run" # set parameter  
    fi

    git config user.name "${DEPLOY_BOT_NAME}"
    git config user.email "${DEPLOY_BOT_MAIL}"

    git add ${ORIGN}
    git commit -am "adds build, automatic commit based on ${COMMIT:-$COMMIT_DEFAULT}" $DRY_RUN
    git push heroku ${DEPLOY_BRANCH:?"Error: branch not set!"} $DRY_RUN

    # delete ssh key on heroku  
    heroku keys:remove ${DEPLOY_BOT_MAIL}

    # cleanup repo (orign) folder  
    cleanupFolder ${ORIGN}

    # write a new placeholder .gitignore file (only for debugging/testing)
    # echo "# .gitignore as a placeholder (to keep the empty folder in the repo)" > ${ORIGN}/.gitignore

else
    echo "build directory is empty, no file(s) found."
    exit 1
fi  

# start the shell (keeps container alive - and exits with code 137)
# comment after debugging (container will exit gracefully) 
# /bin/sh