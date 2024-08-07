pipeline {
    agent any

    environment {
        dockerimagename = '992568741/astarosh'
        dockerImage = ''
        KUBECONFIG = credentials('kubeconfig-credentials')
        TOKEN = credentials('telegramToken')
        CHAT_ID = credentials('telegramChatid')
        CURRENT_BUILD_NUMBER = "${currentBuild.number}"
        GIT_MESSAGE = sh(returnStdout: true, script: "git log -n 1 --format=%s ${GIT_COMMIT}").trim()
        GIT_AUTHOR = sh(returnStdout: true, script: "git log -n 1 --format=%ae ${GIT_COMMIT}").trim()
        GIT_COMMIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short ${GIT_COMMIT}").trim()
        GIT_INFO = "Branch(Version): ${GIT_BRANCH}\nLast Message: ${GIT_MESSAGE}\nAuthor: ${GIT_AUTHOR}\nCommit: ${GIT_COMMIT_SHORT}"
        TEXT_BREAK = '--------------------------------------------------------------'
        TEXT_CI_SUCCESS = "${TEXT_BREAK}\n${GIT_INFO}\n${JOB_NAME} All CI stages completed successfully!"

        TEXT_SUCCESS_DEPLOY = "${TEXT_BREAK}\n${JOB_NAME} finish successfully!"
        TEXT_FAILURE_DEPLOY = "${TEXT_BREAK}\n${JOB_NAME} not finish, check errors!"
    }

    stages {
        stage('Checkout Source') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Surviv87/test_project'
            }
        }

        stage('Lint Dockerfile') {
            steps {
                script {
                    sh 'hadolint Dockerfile'
                }
            }
        }

        stage('Build image') {
            steps {
                script {
                    dockerImage = docker.build dockerimagename
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    sh "docker run --rm ${dockerimagename} sh -c 'nohup npm run start & ./check_http.sh'"
                }
            }
        }

        stage('Pushing Image') {
            environment {
                registryCredential = 'dockerhub-credentials'
            }
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', registryCredential) {
                        dockerImage.push('reactapp')
                    }
                }
            }
        }

        stage('Validate k8s manifest') {
            steps {
                script {
                    sh 'kubeconform *.yaml'
                }
            }
        }
        stage('CI notification') {
            steps {
                sh "curl --location --request POST 'https://api.telegram.org/bot${TOKEN}/sendMessage' --form text='${TEXT_CI_SUCCESS}' --form chat_id='${CHAT_ID}'"
            }
        }

        stage('Deploy app to k8s pre-prod namespace') {
            steps {
                script {
                    // Deploy using kubectl  
                    sh 'kubectl create namespace pre-production && kubectl apply -f deployment_dev.yaml'
                }
            }
        }

        stage('Check HTTP avaiablity deploy app-dev') {
            steps {
                script {
                    def response = httpRequest('http://reactappdev.test.local')

                    echo "HTTP Response Code: ${response.status}"

                    if (response.status != 200) {
                        error "HTTP request failed with code: ${response.status}"
                    } else {
                        echo "HTTP is available"
                    }
                }
            }
        }    

        stage('Check Dev Deployment Status') {
            steps {
                script {
                    def readyReplicas = sh(script: "kubectl get deployment reactapp-dev -n pre-production -o jsonpath='{.status.readyReplicas}'", returnStdout: true).trim()
                    def desiredReplicas = sh(script: "kubectl get deployment reactapp-dev -n pre-production -o jsonpath='{.spec.replicas}'", returnStdout: true).trim()

                    echo "Deployment Status: Ready Replicas: ${readyReplicas}, Desired Replicas: ${desiredReplicas}"

                }
            }
        }

        stage('Manual Approval') {
            steps {
                script {
                    def userInput = input(
                        id: 'ApprovalInput',
                        message: " Approve to continue?",
                        parameters: [
                            [$class: 'BooleanParameterDefinition', name: 'Approve', defaultValue: false]
                        ]
                    )
                    
                    if (userInput) {
                        echo "Approved. Let's continue"
                    } else {
                        error "User did not approve to continue. Exiting pipeline."
                    }
                }
            }
        }
        stage('Deploy app to k8s prod namespace') {
            steps {
                script {
                    // Deploy using kubectl  
                    sh 'kubectl create namespace production && kubectl apply -f deployment_prod.yaml'
                }
            }
        }

        stage('Check HTTP avaiablity deploy app-prod') {
            steps {
                script {
                    def response = httpRequest('http://reactapp.test.local')

                    echo "HTTP Response Code: ${response.status}"

                    if (response.status != 200) {
                        error "HTTP request failed with code: ${response.status}"
                    } else {
                        echo "HTTP is available"
                    }
                }
            }
        }    

        stage('Check Prod Deployment Status') {
            steps {
                script {
                    def readyReplicas = sh(script: "kubectl get deployment reactapp-prod -n production -o jsonpath='{.status.readyReplicas}'", returnStdout: true).trim()
                    def desiredReplicas = sh(script: "kubectl get deployment reactapp-prod -n production -o jsonpath='{.spec.replicas}'", returnStdout: true).trim()

                    echo "Deployment Status: Ready Replicas: ${readyReplicas}, Desired Replicas: ${desiredReplicas}"

                }
            }
        }

        stage('Delete app from k8s pre-prod namespace') {
            steps {
                script {
                    // Deploy using kubectl  
                    sh 'kubectl delete -f deployment_dev.yaml'
                }
            }
        }

    }

    post {
        success {
            script {
                sh "curl --location --request POST 'https://api.telegram.org/bot${TOKEN}/sendMessage' --form text='${TEXT_SUCCESS_DEPLOY}' --form chat_id='${CHAT_ID}'"
            }
        }
        failure {
            script {
                sh "curl --location --request POST 'https://api.telegram.org/bot${TOKEN}/sendMessage' --form text='${TEXT_FAILURE_DEPLOY}' --form chat_id='${CHAT_ID}'"
            }
        }
    }
}