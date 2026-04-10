pipeline {
  agent any
          parameters {
     string(name: "App_Version", description: "provide application version")
  }
  environment {
    DOCKERHUB_CREDENTIALS=credentials("dockerhub")
  }
  stages {
    stage("Checkout") {
      steps {
        checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/VikramYenuga/jenkins-datastore.git']])
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
                withSonarQubeEnv('SonarQube') {   // ✅ FIXED
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
          echo "-------- Pushing Artifacts To S3 Completed --------"
        """
      }
    }
    stage("Docker Image Build") {
      steps {
        sh """
          echo "-------- Building Docker Image --------"
          docker build -t datastore:"${App_Version}" .
          echo "-------- Image Successfully Built --------"
        """
      }
    }
    stage("Docker Image Scan") {
      steps {
        sh """
          echo "-------- Scanning Docker Image --------"
          trivy image datastore:"${App_Version}"
          echo "-------- Scanning Docker Image Complete --------"
        """
      }
    }
    stage("Docker Image Tag") {
      steps{
        sh """
          echo "-------- Tagging Docker Image --------"
          docker tag datastore:"${App_Version}" vikramyenuga/datastore:"${App_Version}"
          echo "-------- Tagging Docker Image Completed."
        """
      }
    }
    stage("Loggingin & Pushing Docker Image") {
      steps {
        sh """
          echo "-------- Logging To DockerHub --------"
          docker login -u $DOCKERHUB_CREDENTIALS_USR --password $DOCKERHUB_CREDENTIALS_PSW
          echo "-------- DockerHub Login Successful --------"

          echo "-------- Pushing Docker Image To DockerHub --------"
          docker push vikramyenuga/datastore:"${App_Version}"
          echo "-------- Docker Image Pushed Successfully --------"
        """
      }
    }

}
}
