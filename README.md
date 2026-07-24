# Tech Challenge 1: React and Express on Amazon ECS

## Project Overview

This project deploys a containerized full-stack application to Amazon Web Services using Infrastructure as Code and an automated GitOps deployment workflow.

The application contains:

- A React frontend
- An Express backend
- Docker container images
- Amazon Elastic Container Registry repositories
- Amazon Elastic Container Service services and tasks
- An internet-facing Application Load Balancer
- Terraform-managed AWS infrastructure
- GitHub Actions CI/CD
- GitHub OpenID Connect authentication to AWS

The deployed application returns a unique identifier through the Application Load Balancer, demonstrating successful communication between the frontend, backend, and AWS infrastructure.

## Project Status

**Core project:** Complete  
**GitOps bonus:** Complete  
**AWS Region:** `us-east-2`  
**Git branch used for deployment:** `gitops`

Verified deployment state:

- Frontend ECS service: `ACTIVE`
- Backend ECS service: `ACTIVE`
- Frontend desired tasks: `1`
- Frontend running tasks: `1`
- Backend desired tasks: `1`
- Backend running tasks: `1`
- Application Load Balancer: Active
- GitHub Actions deployment workflow: Successful
- GitHub Actions authentication: AWS OIDC with no long-lived AWS access keys

## Architecture

The solution uses the following deployment flow:

```text
Developer
   |
   v
GitHub Repository — gitops branch
   |
   v
GitHub Actions
   |
   | AWS OIDC authentication
   v
AWS IAM Role
   |
   +----------------------+
   |                      |
   v                      v
Build Docker images    Update ECS services
   |
   v
Amazon ECR
   |
   v
Amazon ECS tasks
   |
   v
Application Load Balancer
   |
   v
Application users
```

### AWS Architecture

The Terraform configuration provisions an AWS environment containing:

- One VPC
- Two public subnets
- Two private subnets
- An Internet Gateway
- Public routing
- Security groups for the load balancer and ECS tasks
- One internet-facing Application Load Balancer
- Frontend and backend target groups
- One Amazon ECS cluster
- One frontend ECS service
- One backend ECS service
- Frontend and backend ECS task definitions
- Frontend and backend Amazon ECR repositories
- An ECS task execution IAM role

> The architecture diagram should represent the verified as-built environment. It should not claim that optional services such as Amazon S3, AWS Secrets Manager, or Amazon CloudWatch were configured unless those resources are added and verified.

## Application Components

### Frontend

The frontend is a React application deployed as a Docker container through Amazon ECS.

It receives public HTTP traffic from the Application Load Balancer and communicates with the backend service.

### Backend

The backend is an Express application deployed as a separate Docker container through Amazon ECS.

The backend generates and returns a universally unique identifier. The successful identifier displayed through the load balancer confirms that the deployed application is functioning.

## Repository Structure

```text
devops-code-challenge1/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   └── application source files
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   └── application source files
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── supporting Terraform files
├── .gitignore
└── README.md
```

The exact filenames may vary, but the repository separates application code, infrastructure code, and automation workflows.

## Technologies Used

| Category | Technology |
|---|---|
| Frontend | React |
| Backend | Node.js and Express |
| Containers | Docker |
| Infrastructure as Code | Terraform |
| Container registry | Amazon ECR |
| Container orchestration | Amazon ECS |
| Load balancing | Application Load Balancer |
| Source control | GitHub |
| CI/CD | GitHub Actions |
| AWS authentication | GitHub OIDC |
| Identity and access | AWS IAM |

## Infrastructure Deployment

### Prerequisites

Install and configure:

- Git
- Docker Desktop
- Terraform
- AWS CLI
- GitHub CLI, if using command-line GitHub management
- An AWS account with appropriate permissions

Confirm the tools are available:

```bash
git --version
docker --version
terraform --version
aws --version
gh --version
```

Confirm the AWS identity before deploying:

```bash
aws sts get-caller-identity
```

### Clone the Repository

```bash
git clone https://github.com/obiwang33k-ui/devops-code-challenge1.git
cd devops-code-challenge1
git checkout gitops
```

### Initialize Terraform

```bash
cd terraform
terraform init
```

### Format and Validate Terraform

```bash
terraform fmt -recursive
terraform validate
```

### Review the Deployment Plan

```bash
terraform plan
```

Review the proposed resources carefully before applying the configuration.

### Deploy the Infrastructure

```bash
terraform apply
```

Enter `yes` only after reviewing the plan.

### Review Terraform-Managed Resources

```bash
terraform state list
```

The state should include resources for the VPC, subnets, security groups, load balancer, target groups, ECR repositories, ECS cluster, task definitions, services, and IAM roles.

## Container Build Requirements

Because the Amazon ECS runtime expects Linux container images, images built on an Apple Silicon Mac should explicitly target the AMD64 Linux platform when required.

Example:

```bash
docker buildx build \
  --platform linux/amd64 \
  --tag <repository-uri>:latest \
  --push \
  ./backend
```

Repeat the process for the frontend image using its ECR repository URI.

The GitHub Actions workflow performs the production image build and push automatically.

## GitOps CI/CD Bonus

The `gitops` branch triggers a GitHub Actions deployment workflow.

The workflow performs these operations:

1. Checks out the repository.
2. Authenticates to AWS through GitHub OIDC.
3. Assumes the approved AWS IAM role.
4. Logs in to Amazon ECR.
5. Builds the backend Docker image.
6. Pushes the backend image to Amazon ECR.
7. Builds the frontend Docker image.
8. Pushes the frontend image to Amazon ECR.
9. Updates the backend ECS service.
10. Updates the frontend ECS service.
11. Waits for both ECS services to stabilize.
12. Displays the final service status.

### Security Benefit of OIDC

GitHub OIDC allows the workflow to request short-lived AWS credentials.

This design avoids storing long-lived AWS access keys in GitHub repository secrets. The IAM role trust policy limits which GitHub repository and branch can assume the role.

The workflow uses the AWS role:

```text
GitHubActions-TechChallenge1-Role
```

The trusted repository and branch must match:

```text
obiwang33k-ui/devops-code-challenge1
gitops
```

## Triggering the Deployment

From the repository root:

```bash
git checkout gitops
git status
git add .
git commit -m "Update application deployment"
git push origin gitops
```

The push starts the GitHub Actions workflow.

Monitor the most recent workflow:

```bash
gh run list --workflow deploy.yml
```

Watch a specific run:

```bash
gh run watch <run-id>
```

View its logs:

```bash
gh run view <run-id> --log
```

## Deployment Verification

### Verify ECS Services

```bash
aws ecs describe-services \
  --cluster tech-challenge-cluster \
  --services \
    tech-challenge-backend-service \
    tech-challenge-frontend-service \
  --region us-east-2 \
  --query 'services[].{Service:serviceName,Status:status,Desired:desiredCount,Running:runningCount,Rollout:deployments[0].rolloutState}' \
  --output table
```

Expected results:

- Both services are `ACTIVE`.
- Each service has a desired count of `1`.
- Each service has a running count of `1`.
- The latest deployment rollout state is `COMPLETED`.

### Verify Running Tasks

```bash
aws ecs list-tasks \
  --cluster tech-challenge-cluster \
  --desired-status RUNNING \
  --region us-east-2
```

### Verify the Load Balancer

```bash
aws elbv2 describe-load-balancers \
  --names tech-challenge-alb \
  --region us-east-2 \
  --query 'LoadBalancers[0].{DNS:DNSName,State:State.Code,Scheme:Scheme}' \
  --output table
```

### Retrieve the Application URL

```bash
aws elbv2 describe-load-balancers \
  --names tech-challenge-alb \
  --region us-east-2 \
  --query 'LoadBalancers[0].DNSName' \
  --output text
```

Open the returned DNS name in a browser using:

```text
http://<load-balancer-dns-name>
```

A successful response displays:

```text
SUCCESS
<unique-identifier>
```

## Security Design

The project applies several important security practices:

- GitHub OIDC uses short-lived AWS credentials.
- No long-lived AWS access keys are required by the CI/CD workflow.
- IAM roles provide task and deployment permissions.
- The Application Load Balancer is the public application entry point.
- ECS tasks are separated from direct public access.
- Security groups restrict communication between the load balancer and ECS services.
- Frontend and backend workloads run as separate ECS services.
- Infrastructure is defined through version-controlled Terraform code.
- Deployment activity is recorded in GitHub Actions workflow history.

## Evidence of Completion

Recommended submission evidence includes:

1. Successful GitHub Actions workflow.
2. ECS services showing `ACTIVE`.
3. ECS tasks showing `RUNNING`.
4. ECR repositories containing frontend and backend images.
5. Active Application Load Balancer.
6. Browser displaying `SUCCESS` and a unique identifier.
7. GitHub repository on the `gitops` branch.
8. Terraform state list.
9. AWS CLI ECS service status.
10. AWS CLI load balancer DNS output.
11. Final as-built architecture diagram.

## Troubleshooting Notes

### OIDC Role Assumption Failure

Example error:

```text
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

Review:

- The IAM role trust policy.
- The GitHub organization or username.
- The repository name.
- The branch restriction.
- The OIDC provider URL.
- The `sts.amazonaws.com` audience.
- The role ARN in the workflow.

The trust-policy subject must match the GitHub repository and branch exactly.

### ECS Tasks Fail to Start

Review:

```bash
aws ecs describe-services \
  --cluster tech-challenge-cluster \
  --services tech-challenge-frontend-service tech-challenge-backend-service \
  --region us-east-2
```

Also check:

- Task definition image URIs
- Container architecture
- ECR image availability
- ECS task execution role permissions
- Security group rules
- Container ports
- Target group health

### Unhealthy Load Balancer Targets

Confirm:

- The target group port matches the application container port.
- The health-check path exists.
- The ECS security group allows traffic from the ALB security group.
- The application listens on `0.0.0.0`, not only `localhost`.
- The tasks are running in subnets reachable by the load balancer.

## Cleanup

Destroy the AWS resources after grading when they are no longer needed to avoid continued charges.

From the Terraform directory:

```bash
terraform plan -destroy
terraform destroy
```

Enter `yes` only after reviewing the destroy plan.

Then verify that billable resources are gone:

```bash
aws ecs list-clusters --region us-east-2
aws elbv2 describe-load-balancers --region us-east-2
aws ecr describe-repositories --region us-east-2
```

ECR repositories containing images may require image deletion before repository removal, depending on their configuration.

## Lessons Learned

This project demonstrated how application development, containerization, cloud infrastructure, security, and deployment automation work together.

Key lessons include:

- Terraform creates repeatable infrastructure.
- Docker packages applications consistently.
- Amazon ECR stores versioned application images.
- Amazon ECS manages containerized workloads.
- An Application Load Balancer distributes and routes application traffic.
- GitHub Actions automates builds and deployments.
- GitHub OIDC strengthens CI/CD security by replacing long-lived AWS credentials with short-lived role sessions.
- Verification commands and screenshots provide evidence that the system is operating as intended.

## Author

**W. Jackson**

## Repository

`https://github.com/obiwang33k-ui/devops-code-challenge1`

## License

This project was created for educational and portfolio purposes.
