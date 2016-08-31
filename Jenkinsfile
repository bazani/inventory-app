node ('v8s-dpcli') {
   stage 'Clean'
   sh 'sudo rm -rf inventory-app/'
   stage 'Git Clone'
   sh "git clone -b ${env.BRANCH_NAME} https://${env.GITUSER}:${env.GITTOKEN}@github.com/ClusterHQ/inventory-app"
   stage 'Ready test env'
   sh 'whoami'
   sh 'cd inventory-app/ && docker-compose -H unix:///var/run/docker.sock -f docker-compose.yml up -d'
   stage 'Build and Run Tests'
   sh 'docker run --rm -v inventory-app/:/app/ clusterhq/mochatest cd /app && npm install && mocha --debug test/*'
   stage 'Teardown'
   sh 'docker-compose -H unix:///var/run/docker.sock -f docker-compose.yml stop'
   sh 'docker-compose -H unix:///var/run/docker.sock -f docker-compose.yml rm -f'
   sh 'docker volume rm inventoryapp_rethink-data'
}
