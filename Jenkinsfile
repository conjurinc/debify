#!/usr/bin/env groovy

// Automated release, promotion and dependencies
properties([
  release.addParams(),
  dependencies(['cyberark/conjur-base-image'])
])

if (params.MODE == "PROMOTE") {
  release.promote(params.VERSION_TO_PROMOTE) { sourceVersion, targetVersion, assetDirectory ->
    sh './publish-rubygem.sh'
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
        // Allow ARM64 architecture build
        sh 'sudo apt-get install qemu binfmt-support qemu-user-static'
        sh 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
        sh 'docker buildx ls'
      }
    }

    stage('Build Docker image') {
      parallel {
        stage('Build AMD64 image') {
          steps {
            sh './build.sh amd64'
          }
        }

        stage('Build ARM64 image') {
          steps {
            sh './build.sh arm64'
          }
        }
      }
    }

    stage('Scan Docker image') {
      parallel {
        stage('Scan Docker image for fixable issues (AMD64 based)') {
          steps{
            script {
              VERSION = sh(returnStdout: true, script: 'cat VERSION')
            }
            scanAndReport("debify:${VERSION}-amd64", "HIGH", false)
          }
        }
        stage('Scan Docker image for all issues (AMD64 based)') {
          steps{
            script {
              VERSION = sh(returnStdout: true, script: 'cat VERSION')
            }
            scanAndReport("debify:${VERSION}-amd64", "NONE", true)
          }
        }

        stage('Scan Docker image for fixable issues (ARM64 based)') {
          steps{
            script {
              VERSION = sh(returnStdout: true, script: 'cat VERSION')
            }
            scanAndReport("debify:${VERSION}-arm64", "HIGH", false)
          }
        }
        stage('Scan Docker image for all issues (ARM64 based)') {
          steps{
            script {
              VERSION = sh(returnStdout: true, script: 'cat VERSION')
            }
            scanAndReport("debify:${VERSION}-arm64", "NONE", true)
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
      parallel {
        stage('Push AMD64 image') {
          steps {
            sh './push-image.sh amd64'
          }
        }

        stage('Push ARM64 image') {
          steps {
            sh './push-image.sh arm64'
          }
        }
      }
    }

    stage('Push Docker manifest with multi-arch') {
      steps {
        sh './push-manifest.sh'
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
