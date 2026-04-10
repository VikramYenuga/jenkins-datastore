pipeline {
    agent any

    stages {

        stage("Checkout") {
            steps {
                git 'https://github.com/VikramYenuga/jenkins-datastore.git'
            }
        }

        stage("Maven Build") {
            steps {
                sh '''
                   echo "-------- Building Application --------"
                   mvn clean package
                '''
            }
        }

        stage("Maven Test") {
            steps {
                sh '''
                    echo "-------- Running Tests --------"
                    mvn test
                '''
            }
        }

        stage("SonarQube Analysis") {
            steps {
                withSonarQubeEnv('SonarQube') {   // ✅ FIXED
                    sh '''
                        echo "-------- SonarQube Analysis --------"
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
                sh '''
                  echo "-------- Uploading to S3 --------"
                  aws s3 cp ./target/*.jar s3://vikram-datastore-artefact-store-jenkins-apps/
                '''
            }
        }

        stage("Docker Image Build") {
            steps {
                sh '''
                  echo "-------- Building Docker Image --------"
                  docker build -t datastore:${App_Version} .
                '''
            }
        }
    }
}
