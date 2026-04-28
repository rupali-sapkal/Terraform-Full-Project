# Jenkins Pipeline Setup Guide

## Prerequisites

1. **Jenkins Server** - Version 2.200 or higher
2. **Required Jenkins Plugins:**
   - Pipeline
   - Git
   - AWS Credentials
   - Timestamper
   - Log Parser

### Install Plugins

```bash
# Via Jenkins UI:
# Manage Jenkins → Manage Plugins → Available Plugins
# Search and install:
# - Pipeline
# - Git
# - Pipeline: Stage View
# - AWS Credentials
# - Timestamper
```

## Jenkins Setup

### Step 1: Configure AWS Credentials

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **Add Credentials** on the left sidebar
3. Select **AWS Credentials**
4. Enter your AWS Access Key ID and Secret Access Key
5. Set Credentials ID: `aws-terraform-credentials`
6. Click **OK**

### Step 2: Create Pipeline Job

1. Click **New Item** on Jenkins home
2. Enter job name: `Terraform-Infrastructure-Pipeline`
3. Select **Pipeline**
4. Click **OK**

### Step 3: Configure Pipeline

In the job configuration:

1. **General Tab:**
   - Check "This project is parameterized"
   - Add parameters as defined in Jenkinsfile

2. **Build Triggers:**
   - Check "Poll SCM" (if using SCM)
   - Schedule: `H H * * *` (daily)

3. **Pipeline Tab:**
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/your-repo/Terraform-Full-Project.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

### Step 4: Add Build Approvers

1. Go to **Configure** → **Build Triggers**
2. Add users to `terraform-deployers` group:
   ```bash
   jenkins-cli -s http://localhost:8080 \
     create-job-template "Terraform-Infrastructure-Pipeline"
   ```

## Jenkins Agent Setup

### Install Required Tools on Jenkins Agent

```bash
#!/bin/bash

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Verify installations
terraform version
aws --version
tflint --version
```

## Running the Pipeline

### Via Web UI

1. Click **Build with Parameters**
2. Select environment (dev, prod, uat)
3. Select action (plan, apply, destroy)
4. Optionally check "Auto Approve"
5. Click **Build**

### Via Jenkins CLI

```bash
# Plan changes
java -jar jenkins-cli.jar -s http://localhost:8080 \
  build Terraform-Infrastructure-Pipeline \
  -p ENVIRONMENT=dev \
  -p ACTION=plan

# Apply changes
java -jar jenkins-cli.jar -s http://localhost:8080 \
  build Terraform-Infrastructure-Pipeline \
  -p ENVIRONMENT=dev \
  -p ACTION=apply
```

## Monitoring Pipeline

### View Logs

1. Click on build number in **Build History**
2. Click **Console Output**
3. View real-time logs

### Plugins for Better Visibility

- **Pipeline Stage View** - Visual pipeline representation
- **Log Parser** - Parse and highlight logs
- **Build Name Updater** - Update build description

## Security Best Practices

1. **AWS Credentials:**
   - Use IAM users with minimal permissions
   - Rotate credentials regularly
   - Consider using IAM roles for EC2

2. **Jenkins Access:**
   - Enable authentication (LDAP/Active Directory)
   - Use SSL/TLS
   - Implement role-based access control

3. **Pipeline Security:**
   - Review all changes before applying
   - Use approval gates for production
   - Audit all infrastructure changes

4. **State File Security:**
   - Encrypt S3 state buckets
   - Enable versioning
   - Restrict S3 bucket access

## Troubleshooting

### Common Issues

1. **Pipeline timeout**
   ```
   Solution: Increase timeout in OPTIONS section of Jenkinsfile
   ```

2. **AWS credentials not found**
   ```bash
   # Verify credentials are configured:
   aws sts get-caller-identity
   ```

3. **Terraform init fails**
   ```bash
   # Check S3 bucket exists:
   aws s3 ls | grep terraform-state
   
   # Check DynamoDB table exists:
   aws dynamodb list-tables
   ```

4. **Permission denied errors**
   ```
   Solution: Check IAM permissions for Jenkins user/role
   ```

## Advanced Configuration

### Email Notifications

Add to Jenkinsfile post section:

```groovy
post {
    always {
        emailext(
            subject: "Jenkins Build ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            body: "Build log attached",
            to: "devops@example.com",
            attachLog: true
        )
    }
}
```

### Slack Notifications

Add to Jenkinsfile post section:

```groovy
post {
    always {
        slackSend(
            channel: '#devops',
            message: "Build ${env.BUILD_NUMBER} ${currentBuild.result}",
            webhookUrl: 'YOUR_SLACK_WEBHOOK_URL'
        )
    }
}
```

### Archive Artifacts

```groovy
archiveArtifacts artifacts: 'environments/*/tfplan',
    allowEmptyArchive: true
```

## Resource Links

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [Jenkins Blue Ocean](https://www.jenkins.io/doc/book/blueocean/)
- [AWS Credentials Plugin](https://plugins.jenkins.io/aws-credentials/)
