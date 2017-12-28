node {
    def app

    stage('Clone repository') {
        /* Let's make sure we have the repository cloned to our workspace */
        slackSend "Build Started - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"

        checkout scm
        
        def COMMITHASH = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
        echo ("Commit hash: "+COMMITHASH.substring(0,7))
    }

    stage('Build image') {
        /* This builds the actual image; synonymous to
         * docker build on the command line */
        println('Build image stage');
        app = docker.build("visumenu-1312/recorder_asterisk")

    }

    stage('Push image') {
        /* Finally, we'll push the image with two tags:
         * First, the incremental build number from Jenkins
         * Second, the 'latest' tag.
         * Pushing multiple tags is cheap, as all the layers are reused. */

        docker.withRegistry('https://us.gcr.io', 'gcr:visumenu-1312') {
            app.push("${env.BUILD_NUMBER}")
            app.push("latest")
        }
        slackSend "Docker image is built and pushed to GCP <https://console.cloud.google.com/gcr/images/visumenu-1312/US/recorder_asterisk?project=visumenu-1312&gcrImageListsize=50|Container Registry>  "
    }
   
    stage('Deploy the image to GCP'){
        def userInput = true
        def didTimeout = false
        try {
            slackSend "Please enter some details - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}input/|Open>).\nYou have only 10 min. to enter them, else deployment will be cancelled."
            timeout(time: 600, unit: 'SECONDS') { // change to a convenient timeout for you
                userInput = input(
                   id: 'userInput', message: 'If you want to deploy the image to GCP, please enter DBs name preffix (to get full DB names "-AsteriskConf" and "-DialerDB" will be added to the preffix)\n Note: You need to create the DBs by yourself,\n if you don\'t want to deploy it please press Abort:', parameters: [
                   [$class: 'TextParameterDefinition', defaultValue: "crawler${env.BUILD_NUMBER}", description: 'DB name preffix', name: 'dbname']
                ])
            }
        } catch(err) { // timeout reached or input false
            def user = err.getCauses()[0].getUser()
            if('SYSTEM' == user.toString()) { // SYSTEM means timeout.
                didTimeout = true
            } else {
                userInput = false
                echo "Aborted by: [${user}]"
            }
        }

        if (didTimeout) {
            // do something on timeout
            echo "no input was received before timeout"
            slackSend "No input recived, deployment has been cancelled!!! But the DOCKER image is available in <https://console.cloud.google.com/gcr/images/visumenu-1312/US/recorder_asterisk?project=visumenu-1312&gcrImageListsize=50|GCP Container Registry> "
        } else if ( userInput != false ) {
            echo ("input was received DB preffix: " +userInput)
            def InstanceName = "crawler$BUILD_NUMBER-"+userInput.trim()
            sh '/usr/bin/gcloud beta compute --project "visumenu-1312" instances create "'+InstanceName+'" --zone "us-central1-a" --machine-type "n1-standard-1" --subnet "default" --metadata "gce-container-declaration=spec:\n  containers:\n    - name: '+InstanceName+'\n      image: us.gcr.io/visumenu-1312/recorder_asterisk:latest\n      securityContext:\n        privileged: true\n      env:\n        - name: ENVDBNAME\n          value: '+userInput+'\n      stdin: false\n      tty: true\n  restartPolicy: Always\n" --maintenance-policy "MIGRATE" --service-account "443184526722-compute@developer.gserviceaccount.com" --scopes "https://www.googleapis.com/auth/cloud-platform" --min-cpu-platform "Automatic" --tags "asterisk","http-server" --image "cos-stable-63-10032-71-0" --image-project "cos-cloud" --boot-disk-size "10" --boot-disk-type "pd-standard" --boot-disk-device-name "'+InstanceName+'"'
            def WANIP = sh(returnStdout: true, script: "gcloud compute instances list --filter=\"name=('"+InstanceName+"')\" --format=text|grep '^networkInterfaces'|grep 'natIP:'|sed 's/^.* //g'").trim()
            echo ("Commit WANIP: "+WANIP)

            slackSend "Build finished,\n the container has been deployed to GCP:crawler$BUILD_NUMBER server with IP "+WANIP
            slackSend "The container will be ready in 3-4 of minutes.\n Don't forget to:\n 1) check <http://"+WANIP+"/crawler/test/|new server's configuration>) \n 2) Allow outbound calls from "+WANIP
            slackSend "If DBs set properly then this crawler is fully working and it's ready to process your requests in the DB (cron jobs are enabled)"
            slackSend "Use "+WANIP+" as SIP server address (Extensions and password standard for all servers)"
        } else {
            // do something else
            echo "this was not successful"
            currentBuild.result = 'SUCCESS'
            slackSend "The deployment was canceled!!!"
            slackSend "You can deploy the container with:"
            slackSend "gcloud docker -- pull us.gcr.io/visumenu-1312/recorder_asterisk:latest"
            slackSend "Please don't forget to set environment variables to the container ENVDBNAME - DB name preffix"
        } 
       
    }

}

