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
          sh "cp conjur-debify-*.gem release-assets/."
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
