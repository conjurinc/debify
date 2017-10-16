#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(daysToKeepStr: '30'))
    skipDefaultCheckout()
  }

  stages {
    stage('Checkout') {
      steps {
        // One of our cukes tests to see if debify can correctly
        // determine the version for the package being created, based
        // on the tags in the repo. By default, the Git SCM plugin
        // doesn't pull tags, causing the cuke to fail.
        //
        // I couldn't find any way to configure the plugin, so I used
        // the Snippet Generator to create this:
        checkout([$class: 'GitSCM', branches: [[name: env.BRANCH_NAME]], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: false]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'conjur-jenkins', url: 'git@github.com:conjurinc/debify.git']]])
      }
    }
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
        branch 'master'
      }

      steps {
        sh './tag-image.sh'
        sh './push-image.sh'
      }
    }

    stage('Publish gem') {
      when {
        branch 'master'
      }

      steps {
        build job: 'release-rubygems', parameters: [string(name: 'GEM_NAME', value: 'conjur-debify')]
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
