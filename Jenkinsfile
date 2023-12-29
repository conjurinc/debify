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
      parallel {
        stage('Prepare AMD64') {
          steps {
            // Initialize VERSION file
            updateVersion("CHANGELOG.md", "${BUILD_NUMBER}")
          }
        }

        stage('Prepare ARM64') {
          agent { label 'executor-v2-arm' }

          steps {
            // Initialize VERSION file
            updateVersion("CHANGELOG.md", "${BUILD_NUMBER}")
          }
        }
      }
    }

    stage('Build Docker image') {
      parallel {
        stage('Build AMD64 image') {
          steps {
            sh './build.sh'
          }
        }

        stage('Build ARM64 image') {
          agent { label 'executor-v2-arm' }

          steps {
            sh './build.sh'
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
            scanAndReport("debify:${VERSION}", "HIGH", false)
          }
        }
        stage('Scan Docker image for all issues (AMD64 based)') {
          steps{
            script {
              VERSION = sh(returnStdout: true, script: 'cat VERSION')
            }
            scanAndReport("debify:${VERSION}", "NONE", true)
          }
        }
        stage('Scan Docker image for fixable issues (ARM64 based)') {
          agent { label 'executor-v2-arm' }

          steps{
            script {
              VERSION = sh(returnStdout: true, script: 'cat VERSION')
            }
            scanAndReport("debify:${VERSION}", "HIGH", false)
          }
        }
        stage('Scan Docker image for all issues (ARM64 based)') {
          agent { label 'executor-v2-arm' }

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
      parallel {
        stage('Run tests on AMD64') {
          steps {
            sh './test.sh'
          }
          post { always {
            junit 'features/reports/*.xml'
          }}
        }

        stage('Run tests on ARM64') {
          agent { label 'executor-v2-arm' }

          steps {
            sh './test.sh'
          }
          post { always {
            junit 'features/reports/*.xml'
          }}
        }
      }
    }

    stage('Push Docker image') {
      parallel {
        stage('Push AMD64 image') {
          steps {
            sh './push-image.sh amd64'
          }
        }

        stage('Push ARM64 image') {
          agent { label 'executor-v2-arm' }

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
