#!/usr/bin/env groovy

// Automated release, promotion and dependencies
properties([
  release.addParams(),
  dependencies(['cyberark/conjur-base-image'])
])

if (params.MODE == "PROMOTE") {
  release.promote(params.VERSION_TO_PROMOTE) { sourceVersion, targetVersion, assetDirectory ->
    sh './publish-rubygems.sh'
  }
  return
}

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(daysToKeepStr: '30'))
    skipDefaultCheckout()
  }

  triggers {
    cron(getDailyCronString())
  }

  environment {
    MODE = release.canonicalizeMode()
  }

  stages {
    stage ("Skip build if triggering job didn't create a release") {
      when {
        expression {
          MODE == "SKIP"
        }
      }
      steps {
        script {
          currentBuild.result = 'ABORTED'
          error("Aborting build because this build was triggered from upstream, but no release was built")
        }
      }
    }
    stage('Prepare') {
      steps {
        // One of our cukes tests to see if debify can correctly
        // determine the version for the package being created, based
        // on the tags in the repo. By default, the Git SCM plugin
        // doesn't pull tags, causing the cuke to fail.
        //
        // I couldn't find any way to configure the plugin, so I used
        // the Snippet Generator to create this:
        checkout([$class: 'GitSCM', branches: [[name: env.BRANCH_NAME]], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: false]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'conjur-jenkins', url: 'git@github.com:conjurinc/debify.git']]])

        // Initialize VERSION file
        updateVersion("CHANGELOG.md", "${BUILD_NUMBER}")
      }
    }
    stage('Build docker image') {
      steps {
        sh './build.sh'
      }
    }

    stage('Scan Docker image') {
      parallel {
        stage('Scan Docker image for fixable issues') {
          steps{
            script {
              VERSION = sh(returnStdout: true, script: 'cat VERSION')
            }
            scanAndReport("debify:${VERSION}", "HIGH", false)
          }
        }
        stage('Scan Docker image for all issues') {
          steps{
            script {
              VERSION = sh(returnStdout: true, script: 'cat VERSION')
            }
            scanAndReport("debify:${VERSION}", "NONE", true)
          }
        }
      }
    }

    stage('Run feature tests') {
      steps {
        sh './test.sh'
      }
      post { always {
        junit 'features/reports/*.xml'
      }}
    }

    stage('Push Docker image') {
      steps {
        sh './tag-image.sh'
        sh './push-image.sh'
      }
    }

    stage('Publish to RubyGems') {
      when {
        expression {
          MODE == "RELEASE"
        }
      }

      steps {
        release {
          sh './publish-rubygem.sh'
        }
      }
    }
  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}
