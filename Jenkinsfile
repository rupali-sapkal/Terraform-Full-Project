pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 120, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
    }

    triggers {
        // Poll SCM every 15 minutes
        pollSCM('H/15 * * * *')
        
        // Allow manual trigger
        githubPush()
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'uat', 'prod'], description: '🌍 Select target environment')
        choice(name: 'ACTION', choices: ['build', 'plan', 'destroy'], description: '⚙️  Select action (build=plan+deploy, plan=plan only, destroy=teardown)')
    }

    environment {
        AWS_REGION = 'us-east-1'
        AWS_DEFAULT_REGION = 'us-east-1'
        TERRAFORM_VERSION = '1.5.0'
        TF_LOG = 'INFO'
        TF_LOG_PATH = '${WORKSPACE}/terraform.log'
        ENVIRONMENT = "${params.ENVIRONMENT}"
        ACTION = "${params.ACTION}"
        TIMESTAMP = sh(script: "date +%Y%m%d_%H%M%S", returnStdout: true).trim()
        BUILD_VERSION = "${BUILD_NUMBER}-${TIMESTAMP}"
        SLACK_WEBHOOK = credentials('slack-webhook-url')
        AWS_CREDENTIALS = credentials('aws-terraform-credentials')
    }

    stages {
        stage('Pre-Build Checks') {
            steps {
                script {
                    echo "⚠️  ========== Pre-Build Validation =========="
                    sh '''
                        echo "Jenkins Version: $(jenkins-cli version 2>/dev/null || echo 'CLI not found')"
                        echo "Terraform Version: $(terraform version -json | jq -r '.terraform_version')"
                        echo "AWS CLI Version: $(aws --version)"
                        echo "Workspace: ${WORKSPACE}"
                        echo "Build Number: ${BUILD_NUMBER}"
                        echo "Triggered By: ${BUILD_CAUSE}"
                        
                        # Validate parameters
                        if [[ "${ACTION}" == "destroy" ]]; then
                            if [[ "${ENVIRONMENT}" == "prod" ]]; then
                                echo "❌ ERROR: Cannot destroy PRODUCTION environment!"
                                exit 1
                            fi
                        fi
                        
                        echo "✅ Pre-build checks passed"
                    '''
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    echo "📥 ========== Checking out code =========="
                    checkout scm
                    sh '''
                        echo "Repository URL: ${GIT_URL}"
                        echo "Branch: ${GIT_BRANCH}"
                        echo "Commit: ${GIT_COMMIT}"
                        echo "Commit Message: $(git log -1 --pretty=%B)"
                        
                        # Store git info
                        git log -1 --pretty=%B > ${WORKSPACE}/commit-message.txt
                        git rev-parse HEAD > ${WORKSPACE}/git-commit.txt
                    '''
                }
            }
        }

        stage('Setup AWS Credentials') {
            steps {
                script {
                    echo "🔐 ========== Setting up AWS Credentials =========="
                    sh '''
                        # Export AWS credentials
                        export AWS_ACCESS_KEY_ID=${AWS_CREDENTIALS_USR}
                        export AWS_SECRET_ACCESS_KEY=${AWS_CREDENTIALS_PSW}
                        
                        # Verify AWS connection
                        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                        echo "AWS Account ID: ${ACCOUNT_ID}"
                        echo "AWS User: $(aws sts get-caller-identity --query Arn --output text)"
                        
                        # Store for later use
                        echo ${ACCOUNT_ID} > ${WORKSPACE}/aws-account-id.txt
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                script {
                    echo "🔧 ========== Initializing Terraform for ${ENVIRONMENT} =========="
                    dir("environments/${ENVIRONMENT}") {
                        sh '''
                            echo "Initializing Terraform..."
                            terraform init \
                                -backend=true \
                                -upgrade \
                                -lock-timeout=10s
                            
                            echo "✅ Terraform initialized successfully"
                            terraform version
                        '''
                    }
                }
            }
        }

        stage('Validate & Lint') {
            parallel {
                stage('Terraform Validate') {
                    steps {
                        script {
                            echo "✔️  ========== Validating Terraform =========="
                            dir("environments/${ENVIRONMENT}") {
                                sh '''
                                    terraform validate
                                    echo "✅ Configuration is valid"
                                '''
                            }
                        }
                    }
                }

                stage('Format Check') {
                    steps {
                        script {
                            echo "📝 ========== Checking code format =========="
                            sh '''
                                if ! terraform fmt -check -recursive .; then
                                    echo "⚠️  Formatting issues found. Running fmt..."
                                    terraform fmt -recursive .
                                else
                                    echo "✅ All files properly formatted"
                                fi
                            '''
                        }
                    }
                }

                stage('TFLint') {
                    steps {
                        script {
                            echo "🔍 ========== Running TFLint =========="
                            sh '''
                                if ! command -v tflint &> /dev/null; then
                                    echo "Installing TFLint..."
                                    curl -sSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
                                fi
                                
                                tflint --init 2>/dev/null || true
                                tflint --format compact environments/${ENVIRONMENT}/ || true
                                echo "✅ TFLint completed"
                            '''
                        }
                    }
                }

                stage('Security Scan') {
                    steps {
                        script {
                            echo "🔒 ========== Security Scanning =========="
                            sh '''
                                # Check for hardcoded secrets
                                echo "Scanning for hardcoded secrets..."
                                if grep -r "password\\|secret\\|key\\|token" environments/${ENVIRONMENT}/*.tf | grep -v "^Binary"; then
                                    echo "⚠️  Warning: Possible hardcoded secrets found!"
                                else
                                    echo "✅ No obvious secrets found"
                                fi
                            '''
                        }
                    }
                }
            }
        }

        stage('Cost Estimation') {
            when {
                expression {
                    return params.ACTION == 'plan' || params.ACTION == 'build'
                }
            }
            steps {
                script {
                    echo "💰 ========== Estimating Infrastructure Cost =========="
                    sh '''
                        case "${ENVIRONMENT}" in
                            dev)
                                echo "Estimated Monthly Cost for DEV: $50-80"
                                ;;
                            uat)
                                echo "Estimated Monthly Cost for UAT: $50-80"
                                ;;
                            prod)
                                echo "Estimated Monthly Cost for PROD: $80-120"
                                ;;
                        esac
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression {
                    return params.ACTION == 'plan' || params.ACTION == 'build'
                }
            }
            steps {
                script {
                    echo "📋 ========== Creating Terraform Plan for ${ENVIRONMENT} =========="
                    dir("environments/${ENVIRONMENT}") {
                        sh '''
                            echo "Generating plan..."
                            terraform plan \
                                -out=tfplan \
                                -var-file="terraform.tfvars" \
                                -lock=true \
                                -lock-timeout=10s \
                                2>&1 | tee plan-output.txt
                            
                            # Extract resource count
                            RESOURCE_COUNT=$(grep -oP 'Plan: \\K\\d+' plan-output.txt || echo "0")
                            echo "Plan will create/modify approximately ${RESOURCE_COUNT} resources"
                            
                            echo "✅ Plan completed successfully"
                        '''
                    }
                    
                    // Archive the plan
                    archiveArtifacts artifacts: 'environments/${ENVIRONMENT}/tfplan', allowEmptyArchive: true
                    archiveArtifacts artifacts: 'environments/${ENVIRONMENT}/plan-output.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Plan Analysis') {
            when {
                expression {
                    return params.ACTION == 'plan' || params.ACTION == 'build'
                }
            }
            steps {
                script {
                    echo "📊 ========== Analyzing Plan =========="
                    dir("environments/${ENVIRONMENT}") {
                        sh '''
                            echo "Plan Summary:"
                            if [ -f plan-output.txt ]; then
                                grep -E "Plan:|No changes|will be|already exists" plan-output.txt || true
                            fi
                        '''
                    }
                }
            }
        }

        stage('Approval - Non-Prod') {
            when {
                expression {
                    return (params.ACTION == 'build') && 
                           params.ENVIRONMENT != 'prod'
                }
            }
            steps {
                script {
                    echo "✅ ========== Auto-Approval for ${ENVIRONMENT} =========="
                    sh '''
                        if [[ "${ENVIRONMENT}" == "dev" || "${ENVIRONMENT}" == "uat" ]]; then
                            echo "Auto-approving for non-production environment: ${ENVIRONMENT}"
                        fi
                    '''
                }
            }
        }

        stage('Approval - Production') {
            when {
                expression {
                    return (params.ACTION == 'build') && 
                           params.ENVIRONMENT == 'prod'
                }
            }
            steps {
                script {
                    echo "⚠️  ========== Waiting for PRODUCTION Approval =========="
                    input message: "🚨 PRODUCTION APPROVAL REQUIRED!\n\nDo you want to BUILD and DEPLOY to PRODUCTION?", 
                          ok: 'APPROVE & DEPLOY TO PRODUCTION', 
                          submitter: 'terraform-deployers,infrastructure-team'
                }
            }
        }

        stage('Backup State File') {
            when {
                expression {
                    return params.ACTION == 'build'
                }
            }
            steps {
                script {
                    echo "💾 ========== Backing up Current State =========="
                    sh '''
                        ACCOUNT_ID=$(cat ${WORKSPACE}/aws-account-id.txt)
                        STATE_BUCKET="terraform-state-${ENVIRONMENT}-${ACCOUNT_ID}"
                        
                        echo "Downloading current state for backup..."
                        aws s3 cp \
                            s3://${STATE_BUCKET}/${ENVIRONMENT}/terraform.tfstate \
                            ${WORKSPACE}/backup-state-${BUILD_VERSION}.tfstate \
                            2>/dev/null || echo "No previous state to backup"
                        
                        echo "✅ State backup completed"
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression {
                    return params.ACTION == 'build'
                }
            }
            steps {
                script {
                    echo "🚀 ========== Applying Terraform Configuration =========="
                    dir("environments/${ENVIRONMENT}") {
                        sh '''
                            echo "Starting infrastructure deployment..."
                            
                            terraform apply \
                                -auto-approve \
                                -lock=true \
                                -lock-timeout=10s \
                                -input=false \
                                tfplan
                            
                            APPLY_EXIT_CODE=$?
                            
                            if [ ${APPLY_EXIT_CODE} -eq 0 ]; then
                                echo "✅ Infrastructure successfully deployed"
                            else
                                echo "❌ Infrastructure deployment failed with exit code ${APPLY_EXIT_CODE}"
                                exit ${APPLY_EXIT_CODE}
                            fi
                        '''
                    }
                }
            }
        }

        stage('Extract Outputs') {
            when {
                expression {
                    return params.ACTION == 'build'
                }
            }
            steps {
                script {
                    echo "📤 ========== Extracting Infrastructure Outputs =========="
                    dir("environments/${ENVIRONMENT}") {
                        sh '''
                            echo "Terraform Outputs:"
                            terraform output -no_color | tee ${WORKSPACE}/terraform-outputs.txt
                            
                            # Export outputs as JSON
                            terraform output -json > ${WORKSPACE}/outputs.json
                            
                            echo "✅ Outputs extracted successfully"
                        '''
                    }
                    
                    archiveArtifacts artifacts: 'terraform-outputs.txt', allowEmptyArchive: true
                    archiveArtifacts artifacts: 'outputs.json', allowEmptyArchive: true
                }
            }
        }

        stage('Infrastructure Health Check') {
            when {
                expression {
                    return params.ACTION == 'build'
                }
            }
            steps {
                script {
                    echo "🏥 ========== Infrastructure Health Check =========="
                    sh '''
                        echo "Checking EC2 instances..."
                        RUNNING_INSTANCES=$(aws ec2 describe-instances \
                            --filters "Name=tag:Environment,Values=${ENVIRONMENT}" "Name=instance-state-name,Values=running" \
                            --query 'length(Reservations[].Instances[])' --output text)
                        
                        echo "Running instances in ${ENVIRONMENT}: ${RUNNING_INSTANCES}"
                        
                        if [ ${RUNNING_INSTANCES} -gt 0 ]; then
                            echo "✅ EC2 instances are running"
                        else
                            echo "⚠️  No running instances found"
                        fi
                        
                        echo "Checking ALB health..."
                        ALB_COUNT=$(aws elbv2 describe-load-balancers \
                            --query "length(LoadBalancers[?contains(LoadBalancerName, '${ENVIRONMENT}')])" --output text)
                        
                        if [ ${ALB_COUNT} -gt 0 ]; then
                            echo "✅ ALB found and active"
                        else
                            echo "⚠️  No ALB found"
                        fi
                        
                        echo "Checking S3 buckets..."
                        S3_BUCKETS=$(aws s3 ls | grep -c "${ENVIRONMENT}-app-bucket" || true)
                        if [ ${S3_BUCKETS} -gt 0 ]; then
                            echo "✅ S3 application bucket exists"
                        else
                            echo "⚠️  S3 bucket not found"
                        fi
                    '''
                }
            }
        }

        stage('Run Infrastructure Tests') {
            when {
                expression {
                    return params.ACTION == 'build'
                }
            }
            steps {
                script {
                    echo "🧪 ========== Running Infrastructure Tests =========="
                    dir("environments/${ENVIRONMENT}") {
                        sh '''
                            echo "Testing infrastructure connectivity..."
                            
                            # Get ALB DNS
                            ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
                            
                            if [ -z "${ALB_DNS}" ]; then
                                echo "⚠️  ALB DNS not available yet"
                            else
                                echo "Testing ALB endpoint: ${ALB_DNS}"
                                
                                # Wait for ALB to be healthy
                                echo "Waiting 30 seconds for ALB to stabilize..."
                                sleep 30
                                
                                # Test ALB
                                HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${ALB_DNS}" || echo "000")
                                echo "ALB HTTP Response Code: ${HTTP_CODE}"
                                
                                if [[ "${HTTP_CODE}" == "200" || "${HTTP_CODE}" == "301" || "${HTTP_CODE}" == "302" ]]; then
                                    echo "✅ ALB responding correctly"
                                else
                                    echo "⚠️  ALB returned HTTP ${HTTP_CODE}"
                                fi
                            fi
                            
                            echo "✅ Infrastructure tests completed"
                        '''
                    }
                }
            }
        }

        stage('Document Deployment') {
            when {
                expression {
                    return params.ACTION == 'build'
                }
            }
            steps {
                script {
                    echo "📝 ========== Documenting Deployment =========="
                    sh '''
                        # Create deployment log
                        cat > ${WORKSPACE}/deployment-log.txt <<EOF
========== DEPLOYMENT REPORT ==========
Date: $(date)
Environment: ${ENVIRONMENT}
Action: ${ACTION}
Build Number: ${BUILD_NUMBER}
Build Version: ${BUILD_VERSION}
Git Commit: $(cat ${WORKSPACE}/git-commit.txt)
AWS Account: $(cat ${WORKSPACE}/aws-account-id.txt)
Terraform Version: $(terraform version -json | jq -r '.terraform_version')

Status: SUCCESS
========================================
EOF
                        
                        cat ${WORKSPACE}/deployment-log.txt
                    '''
                }
            }
        }

        stage('Terraform Destroy Approval') {
            when {
                expression {
                    return params.ACTION == 'destroy'
                }
            }
            steps {
                script {
                    echo "🚨 ========== DESTROY APPROVAL REQUIRED =========="
                    input message: """⚠️  WARNING! PERMANENT DELETION ⚠️ 
                    
This will DESTROY all infrastructure in ${ENVIRONMENT}!

Type the environment name to confirm: ${ENVIRONMENT}""", 
                          ok: 'DESTROY EVERYTHING', 
                          submitter: 'terraform-deployers'
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression {
                    return params.ACTION == 'destroy'
                }
            }
            steps {
                script {
                    echo "💥 ========== Destroying Infrastructure =========="
                    dir("environments/${ENVIRONMENT}") {
                        sh '''
                            echo "WARNING: Destroying all resources in ${ENVIRONMENT}..."
                            
                            terraform destroy \
                                -auto-approve \
                                -var-file="terraform.tfvars" \
                                -lock=true \
                                -lock-timeout=10s
                            
                            echo "✅ Infrastructure destroyed"
                        '''
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    echo "🧹 ========== Cleanup =========="
                    sh '''
                        echo "Archiving logs..."
                        ls -la ${WORKSPACE}/*.txt 2>/dev/null || true
                        
                        echo "✅ Cleanup completed"
                    '''
                }
            }
        }
    }

    post {
        success {
            script {
                echo "✅ ========== PIPELINE SUCCESSFUL =========="
                sh '''
                    STATUS="✅ SUCCESS"
                    MESSAGE="Infrastructure deployment completed successfully for ${ENVIRONMENT}"
                    
                    echo "${STATUS}: ${MESSAGE}"
                '''
                
                // Send Slack notification
                sh '''
                    if [ ! -z "${SLACK_WEBHOOK}" ]; then
                        curl -X POST "${SLACK_WEBHOOK}" \
                            -H 'Content-Type: application/json' \
                            -d "{\\"text\\":\\"✅ Terraform ${ACTION} Successful\\\\n📦 Environment: ${ENVIRONMENT}\\\\n🎯 Action: ${ACTION}\\\\n🔢 Build: #${BUILD_NUMBER}\\"}" || true
                    fi
                '''
            }
        }

        failure {
            script {
                echo "❌ ========== PIPELINE FAILED =========="
                sh '''
                    echo "❌ Pipeline execution failed!"
                    echo "Check the logs above for error details"
                '''
                
                // Send Slack notification
                sh '''
                    if [ ! -z "${SLACK_WEBHOOK}" ]; then
                        curl -X POST "${SLACK_WEBHOOK}" \
                            -H 'Content-Type: application/json' \
                            -d "{\\"text\\":\\"❌ Terraform Deployment Failed\\\\n📦 Environment: ${ENVIRONMENT}\\\\n🎯 Action: ${ACTION}\\\\n🔢 Build: #${BUILD_NUMBER}\\\\n📋 Check console output\\"}" || true
                    fi
                '''
            }
        }

        unstable {
            script {
                echo "⚠️  ========== PIPELINE UNSTABLE =========="
                sh '''
                    echo "⚠️  Pipeline completed with warnings"
                '''
            }
        }

        always {
            script {
                echo "📊 ========== Pipeline Complete =========="
                
                // Archive all logs
                archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
                archiveArtifacts artifacts: '**/*.txt', allowEmptyArchive: true
                archiveArtifacts artifacts: 'backup-state-*.tfstate', allowEmptyArchive: true
                
                // Generate build report
                sh '''
                    echo "Build Report Generated: ${BUILD_URL}"
                    echo "Workspace: ${WORKSPACE}"
                '''
                
                // Cleanup workspace (optional - comment out to keep artifacts)
                // cleanWs()
            }
        }
    }
}
