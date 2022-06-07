# SSH-Keys  

## local development  
Copy your key-pair to this folder, otherwise a new pair gets created, when the container will be built. Heroku expects the default naming for ssh keys so be aware of naming them correctly (id_rsa).  

In Alpine containers you can use the roots folder /root/.ssh/  

## in deployment  
You can run your GitHub Actions without creating a SSH-Keypair. It gets created by the deployment script (entrypoint.sh). The __only requirement__ is your API-Key. The SSH-Key gets registered on Heroku during the deployment and is removed after successfully running the deployment.  
Note: Choose a unique user@domain for the automatic SSH-Key. Heroku looks for this combination and will delete this key.  

# Authentification / Authorization with Heroku  

If you pass in the API-KEY as environment variable you don't need to run heroku login procedures. You can directly interact with the heroku API.  
To interact with the repository of Heroku you have to create a .netrc file, which is stored in the users folder (i.e. /root oder ~/user).  
@see: https://devcenter.heroku.com/articles/git#http-git-authentication  
@see: https://devcenter.heroku.com/articles/authentication#netrc-file-format  

## Example  

    machine git.heroku.com
        login user@domain
        password ${HEROKU_API_KEY}