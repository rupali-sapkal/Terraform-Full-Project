# Jenkins Pipeline - Automatic Infrastructure Build Setup

## 📋 Enhanced Jenkinsfile Features

This upgraded Jenkinsfile provides **automatic infrastructure deployment** with:

✅ **Auto-Triggers** - SCM polling & webhook support
✅ **Automatic Approval** - Auto-approves for non-prod environments
✅ **Multi-stage Testing** - Validation, linting, security scan
✅ **Health Checks** - Post-deployment infrastructure validation
✅ **State Backups** - Automatic backup before changes
✅ **Cost Estimation** - Pre-deployment cost analysis
✅ **Notifications** - Slack integration
✅ **Detailed Logging** - Comprehensive execution logs
✅ **Parallel Validation** - Faster pipeline execution
✅ **Safety Guards** - Prod protection, destroy prevention

---

## 🚀 Quick Setup (10 minutes)

### Step 1: Create Jenkins Credentials

#### AWS Credentials
1. Go to **Manage Jenkins** → **Manage Credentials**
2. Click **Add Credentials** on left sidebar
3. Select **AWS Credentials**
4. Fill in:
   - **Access Key ID:** `[your-aws-access-key]`
   - **Secret Access Key:** `[your-aws-secret-key]`
   - **ID:** `aws-terraform-credentials`
5. Click **OK**

#### Slack Webhook (Optional but Recommended)
1. Create Slack App: https://api.slack.com/apps
2. Enable Incoming Webhooks
3. Add New Webhook URL to your channel
4. Go to **Manage Jenkins** → **Manage Credentials**
5. Add **Secret text** credential:
   - **Secret:** `https://hooks.slack.com/services/YOUR/WEBHOOK/URL`
   - **ID:** `slack-webhook-url`

### Step 2: Configure Jenkins Pipeline Job

1. Click **New Item**
2. Enter name: `Terraform-Infrastructure-Pipeline-Auto`
3. Select **Pipeline**
4. Click **OK**

### Step 3: Configure Pipeline Settings

In the job configuration:

#### General Tab
- ✅ **Discard old builds:** Max 20 builds
- ✅ **GitHub project:** `https://github.com/your-repo/Terraform-Full-Project`

#### Build Triggers Tab
- ✅ **Poll SCM:** `H/15 * * * *` (every 15 minutes)
- ✅ **Build when a change is pushed to GitHub**

#### Pipeline Tab
- **Definition:** `Pipeline script from SCM`
- **SCM:** `Git`
- **Repository URL:** `https://github.com/your-repo/Terraform-Full-Project.git`
- **Branch:** `*/main` (or your branch)
- **Script Path:** `Jenkinsfile`

### Step 4: Save Configuration

Click **Save** to create the job.

---

## 🔧 Pipeline Execution Modes

### Mode 1: Automatic (CI/CD) - Recommended for Dev/UAT

```
Trigger → Checkout → Validate → Plan → Auto-Approve → Apply → Test → Success
```

**When:** Code is pushed to main branch
**Parameters:**
- Environment: `dev` or `uat`
- Action: `auto`
- Auto Approve: `false` (for safety, but auto-approves for dev/uat anyway)

**Result:** Infrastructure automatically deployed

### Mode 2: Manual Plan-Only

```
Trigger → Checkout → Validate → Plan → Output
```

**When:** Human reviews changes first
**Parameters:**
- Environment: `dev`/`uat`/`prod`
- Action: `plan`
- Auto Approve: `false`

**Result:** Plan file archived for review

### Mode 3: Manual Apply with Approval

```
Trigger → Checkout → Validate → Plan → Manual Input → Apply → Test → Success
```

**When:** Production deployment or extra safety needed
**Parameters:**
- Environment: `prod`
- Action: `apply`
- Auto Approve: `false`

**Result:** Requires human approval for production

---

## 📊 Pipeline Workflow Diagram

```
START
  ↓
Pre-Build Checks (Validate Parameters)
  ↓
Checkout Code (from Git)
  ↓
Setup AWS Credentials
  ↓
Terraform Init
  ↓
Parallel Validation:
├─ Terraform Validate
├─ Format Check
├─ TFLint
└─ Security Scan
  ↓
Cost Estimation
  ↓
Terraform Plan
  ↓
Plan Analysis
  ↓
Approval Decision:
├─ Dev/UAT: Auto-Approve
└─ Prod: Manual Approval
  ↓
Backup State File
  ↓
Terraform Apply
  ↓
Extract Outputs
  ↓
Health Check (EC2, ALB, S3)
  ↓
Run Tests (Connectivity)
  ↓
Document Deployment
  ↓
Post Actions:
├─ Success: Slack notification
├─ Failure: Slack alert
└─ Archive: All logs & artifacts
  ↓
END
```

---

## 🎯 Running the Pipeline

### Via Web UI - Automatic Build

1. Push code to `main` branch
2. Pipeline automatically triggers (within 15 minutes)
3. Dev environment auto-deployed
4. Receive Slack notification

### Via Web UI - Manual Trigger

1. Go to job: `Terraform-Infrastructure-Pipeline-Auto`
2. Click **Build with Parameters**
3. Select parameters:
   - **Environment:** `dev` / `uat` / `prod`
   - **Action:** `auto` / `plan` / `apply` / `destroy`
   - **AUTO_APPROVE:** `false` (safety default)
   - **DESTROY_PROTECT:** `true` (prevent accidental destroy)
   - **ENABLE_TESTS:** `true` (run health checks)
   - **SKIP_APPROVAL:** `false` (require approval)
4. Click **Build**

### Via Jenkins CLI

```bash
# Install Jenkins CLI
wget http://jenkins-server:8080/jnlpJars/jenkins-cli.jar

# Trigger build with parameters
java -jar jenkins-cli.jar -s http://jenkins-server:8080 \
  build Terraform-Infrastructure-Pipeline-Auto \
  -p ENVIRONMENT=dev \
  -p ACTION=auto \
  -p AUTO_APPROVE=false

# Monitor output
java -jar jenkins-cli.jar -s http://jenkins-server:8080 \
  console Terraform-Infrastructure-Pipeline-Auto 5
```

---

## 🔐 Security Best Practices

### 1. Credential Management
```groovy
// ✅ Good: Use Jenkins credentials
sh '''
  export AWS_ACCESS_KEY_ID=${AWS_CREDENTIALS_USR}
  export AWS_SECRET_ACCESS_KEY=${AWS_CREDENTIALS_PSW}
'''

// ❌ Bad: Hardcoded credentials
sh 'aws configure set aws_access_key_id AKIAIOSFODNN7EXAMPLE'
```

### 2. Approval Gates
```groovy
// Production requires manual approval
when {
    expression {
        return params.ENVIRONMENT == 'prod' && !params.AUTO_APPROVE
    }
}
```

### 3. Destroy Protection
```groovy
// Prevent accidental production destroy
if [[ "${DESTROY_PROTECT}" == "true" && "${ACTION}" == "destroy" ]]; then
    if [[ "${ENVIRONMENT}" == "prod" ]]; then
        echo "❌ ERROR: Cannot destroy PRODUCTION!"
        exit 1
    fi
fi
```

### 4. Audit Logging
- All deployments logged
- Commit messages recorded
- Deployment reports generated
- Slack notifications sent

---

## 📈 Pipeline Stages Explained

### 1. Pre-Build Checks
Validates parameters and prevents unsafe operations:
- Checks for prod destroy attempts
- Validates environment selection
- Verifies destroy protection

### 2. Checkout
Clones the repository:
- Gets latest code
- Records commit info
- Stores for later reference

### 3. AWS Setup
Configures credentials:
- Exports AWS access keys
- Verifies account access
- Stores account ID

### 4. Terraform Init
Initializes Terraform:
- Downloads providers
- Configures backend
- Validates S3 access

### 5. Validation (Parallel)
Four validation checks run simultaneously:
- **Terraform Validate** - Syntax check
- **Format Check** - Code formatting
- **TFLint** - Best practices linter
- **Security Scan** - Hardcoded secrets check

### 6. Cost Estimation
Estimates monthly costs:
- Dev: $50-80
- UAT: $50-80
- Prod: $80-120

### 7. Terraform Plan
Creates execution plan:
- Shows what will change
- Archives plan file
- Extracts resource count

### 8. Approval Decision
Automatic or manual approval:
- Dev/UAT: Auto-approved
- Prod: Requires manual input

### 9. State Backup
Backs up current state:
- Downloads from S3
- Saves locally
- Enables rollback

### 10. Terraform Apply
Applies infrastructure:
- Creates/updates resources
- Updates state file
- Logs all changes

### 11. Health Check
Validates deployed resources:
- Checks EC2 instances
- Tests ALB
- Verifies S3 buckets

### 12. Infrastructure Tests
Tests actual connectivity:
- Pings ALB endpoint
- Verifies HTTP response
- Validates deployment

### 13. Documentation
Creates deployment records:
- Generates deployment log
- Records timestamps
- Stores for audit trail

---

## 📊 Output & Artifacts

Pipeline automatically archives:

```
✅ terraform.log          - Terraform debug logs
✅ terraform-outputs.txt  - Infrastructure outputs
✅ outputs.json          - Outputs in JSON format
✅ deployment-log.txt    - Deployment report
✅ commit-message.txt    - Git commit message
✅ git-commit.txt        - Git commit hash
✅ aws-account-id.txt    - AWS account ID
✅ backup-state-*.tfstate - State file backup
✅ plan-output.txt       - Terraform plan output
```

Access from job page: **Build** → **Artifacts**

---

## 🔔 Slack Notifications

### Auto-sent messages:

**On Success:**
```
✅ Terraform Deployment Successful
📦 Environment: dev
🎯 Action: auto
🔢 Build: #42
```

**On Failure:**
```
❌ Terraform Deployment Failed
📦 Environment: prod
🎯 Action: apply
🔢 Build: #43
📋 Check console output
```

### Custom Notifications

Edit Jenkinsfile post block to add:
```groovy
emailext(
    subject: "Terraform ${ENVIRONMENT} Deployment ${currentBuild.result}",
    body: "Build logs attached",
    to: "devops@example.com",
    attachLog: true
)
```

---

## 🛠️ Troubleshooting

### Pipeline Timeout
```
Solution: Increase timeout in options:
timeout(time: 120, unit: 'MINUTES')
```

### Credentials Not Found
```
Solution: 
1. Verify credentials in Manage Jenkins
2. Check credential IDs match Jenkinsfile
3. Ensure Jenkins agent has permission
```

### SCM Polling Not Triggering
```
Solution:
1. Check Poll SCM is enabled: H/15 * * * *
2. Verify GitHub webhook is set (alternative)
3. Check Jenkins can reach GitHub
```

### Auto-Approval Not Working
```
Solution:
1. Verify SKIP_APPROVAL parameter = false
2. Check environment is dev or uat
3. Ensure ACTION != 'destroy'
```

### S3 Backend Error
```
Solution:
1. Verify S3 buckets exist
2. Check DynamoDB table exists
3. Verify AWS credentials have S3 permissions
4. Ensure Account ID is correct in provider.tf
```

---

## 📚 Jenkins Plugins Required

Install from **Manage Jenkins** → **Manage Plugins**:

| Plugin | Purpose |
|--------|---------|
| Pipeline | Pipeline support |
| Git | Git integration |
| AWS Credentials | AWS credential management |
| CloudBees AWS Credentials | Additional AWS features |
| Log Parser | Parse and colorize logs |
| AnsiColor | ANSI color support |
| Timestamper | Add timestamps |

---

## 🚀 Advanced Configuration

### Enable GitHub Webhooks

1. Go to GitHub repository Settings
2. Click **Webhooks**
3. Click **Add webhook**
4. **Payload URL:** `http://jenkins-server:8080/github-webhook/`
5. **Content type:** `application/json`
6. **Events:** `Push events`
7. Click **Add webhook**

### Configure Jenkins for GitHub

1. Go to **Manage Jenkins** → **Configure System**
2. Find **GitHub** section
3. Click **Add GitHub Server**
4. Set **API URL:** `https://api.github.com`
5. Add GitHub token in credentials

### Enable Email Notifications

1. **Manage Jenkins** → **Configure System**
2. Find **Email Notification**
3. Set **SMTP server:** `smtp.gmail.com`
4. Check **Use SMTP Authentication**
5. Set credentials
6. Port: `587`
7. Check **Use TLS**

---

## 💡 Tips & Tricks

### 1. Skip Approval for Dev Only
```groovy
when {
    expression {
        return params.ENVIRONMENT == 'dev' && !params.AUTO_APPROVE
    }
}
```

### 2. Parallel Execution
```groovy
parallel {
    stage('Validate') { ... }
    stage('TFLint') { ... }
    stage('Security') { ... }
}
```

### 3. Archive Important Artifacts
```groovy
archiveArtifacts artifacts: 'backup-state-*.tfstate'
archiveArtifacts artifacts: '**/*.log'
```

### 4. Environment-Specific Actions
```bash
case "${ENVIRONMENT}" in
    prod)
        echo "Production safeguards enabled"
        ;;
    dev)
        echo "Development mode - relaxed rules"
        ;;
esac
```

---

## 📖 Complete Workflow Example

### Scenario: Deploy to Development

```
1. Developer pushes code to main branch
2. Jenkins detects change (polling or webhook)
3. Pipeline automatically starts
4. Runs all validation checks
5. Auto-approves for dev environment
6. Applies infrastructure changes
7. Runs health checks
8. Sends success notification to Slack
9. Archives deployment artifacts
10. Development environment updated ✅
```

**Time:** 5-10 minutes

### Scenario: Deploy to Production

```
1. Release manager clicks "Build with Parameters"
2. Selects: Environment=prod, Action=apply
3. Jenkins runs full validation
4. Pipeline waits for manual approval
5. Release manager reviews plan
6. Approves deployment
7. Pipeline applies to production
8. Runs comprehensive health checks
9. Sends notification to ops team
10. Production infrastructure updated ✅
```

**Time:** 15-20 minutes

---

## ✅ Verification Checklist

- [ ] AWS credentials configured in Jenkins
- [ ] Slack webhook configured (optional)
- [ ] Pipeline job created
- [ ] SCM polling enabled
- [ ] GitHub webhook configured (optional)
- [ ] S3 backend created
- [ ] DynamoDB tables created
- [ ] Account ID updated in provider files
- [ ] Test pipeline execution
- [ ] Verify Slack notifications work
- [ ] Check artifact archiving

---

## 🎓 Learning Resources

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Terraform Jenkins Integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub + Jenkins Webhook Setup](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [Jenkins Best Practices](https://www.jenkins.io/doc/book/architecture-and-concepts/)

---

## 🆘 Support

For issues:
1. Check Jenkins logs: **Build** → **Console Output**
2. Review Terraform logs: Check artifacts
3. Verify credentials: **Manage Jenkins** → **Manage Credentials**
4. Test manually: Run `terraform plan` locally
5. Contact DevOps team

---

**Status:** ✅ Enhanced Jenkinsfile Ready for Automatic Deployment

Next: Follow the Quick Setup steps above to activate automatic infrastructure builds!
