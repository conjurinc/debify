#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(daysToKeepStr: '30'))
  }

  stages {
    stage('Build docker image') {
      steps {
        sh './build.sh'
      }
    }

    stage('Run feature tests') {
      steps {
        sh './test.sh'
        junit 'features/reports/*.xml'
      }
    }

    stage('Push Docker image') {
      when {
        anyOf {
          branch 'master'
          branch 'dockerize_20170929'
        }
      }
      
      steps {
        sh './push-image.sh'
      }
    }
  }

  post {
    always {
      sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'
      deleteDir()
    }
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}
