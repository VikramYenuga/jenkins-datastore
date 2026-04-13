pipeline {
    agent any

    parameters {
        string(name: "App_Version", description: "provide application version")
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials("dockerhub")
    }

    stages {

        stage("Checkout") {
            steps {
                checkout scmGit(
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/VikramYenuga/jenkins-datastore.git']]
                )
            }
        }

        stage("Maven Build") {
            steps {
                sh """
                    echo "-------- Building Application --------"
                    mvn clean package
                    echo "------- Application Built Successfully --------"
                """
            }
        }

        stage("Maven Test") {
            steps {
                sh """
                    echo "-------- Executing Testcases --------"
                    mvn test
                    echo "-------- Testcases Execution Complete --------"
                """
            }
        }

        stage("SonarQube Analysis") {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        echo "-------- Running SonarQube Analysis --------"
                        mvn sonar:sonar \
                          -Dsonar.projectKey=DataStore \
                          -Dsonar.projectName=DataStore
                    '''
                }
            }
        }

        stage("Quality Gate") {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Artifact Store") {
            steps {
                sh """
                    echo "-------- Pushing Artifacts To S3 --------"
                    aws s3 cp ./target/*.jar s3://vikram-datastore-artefact-store-jenkins-apps/
                    echo "-------- Pushing Artifacts Completed --------"
                """
            }
        }

        stage("Docker Image Build") {
            steps {
                sh """
                    echo "-------- Building Docker Image --------"
                    docker build -t datastore:${App_Version} .
                    echo "-------- Image Successfully Built --------"
                """
            }
        }

        stage("Docker Image Scan") {
            steps {
                sh """
                    echo "-------- Scanning Docker Image --------"
                    trivy image datastore:${App_Version}
                    echo "-------- Scan Complete --------"
                """
            }
        }

        stage("Docker Image Tag") {
            steps {
                sh """
                    echo "-------- Tagging Docker Image --------"
                    docker tag datastore:${App_Version} vikramyenuga/datastore:${App_Version}
                    echo "-------- Tagging Completed --------"
                """
            }
        }

        stage("Login & Push Docker Image") {
            steps {
                sh """
                    echo "-------- Logging into DockerHub --------"
                    docker login -u $DOCKERHUB_CREDENTIALS_USR --password $DOCKERHUB_CREDENTIALS_PSW

                    echo "-------- Pushing Image --------"
                    docker push vikramyenuga/datastore:${App_Version}

                    echo "-------- Push Successful --------"
                """
            }
        }

        stage("Cleanup") {
            steps {
                sh """
                    echo "-------- Cleaning Up --------"
                    docker image prune -a -f
                    echo "-------- Cleanup Done --------"
                """
            }
        }

        stage("Deployment Acceptance") {
            steps {
                input 'Trigger Down Stream Job??'
            }
        }

        stage("Triggering Deployment") {
            steps {
                build job: "Kubernetes-ArgoCD",
                parameters: [
                    string(name: "App_Name", value: "datastore-deploy"),
                    string(name: "App_Version", value: "${params.App_Version}")
                ]
            }
        }
    }

    post {
        success {
            slackSend channel: '#alerting',
                      color: 'good',
                      message: "✔️ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} completed successfully."
        }

        failure {
            slackSend channel: '#alerting',
                      color: 'danger',
                      message: "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER} failed.\nCheck: ${env.BUILD_URL}"
        }

        unstable {
            slackSend channel: '#alerting',
                      color: 'warning',
                      message: "⚠️ UNSTABLE: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }

        aborted {
            slackSend channel: '#alerting',
                      color: '#808080',
                      message: "⛔️ ABORTED: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }

        always {
            slackSend channel: '#alerting',
                      color: '#439FE0',
                      message: "ℹ️ Build finished: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}
