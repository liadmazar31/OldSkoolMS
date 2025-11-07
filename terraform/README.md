# Cosmic MapleStory Server - Terraform Deployment

This Terraform configuration deploys the Cosmic MapleStory server on AWS EC2 with Docker and Docker Compose.

## Architecture

- **VPC**: Custom VPC with public subnet
- **EC2 Instance**: Amazon Linux 2023 with Docker (t2.micro - free tier eligible)
- **Security Groups**: Restricted access allowing only required ports
- **Elastic IP**: Static public IP address for consistent connectivity
- **Docker Compose**: Automatically starts MapleStory server and MySQL database on boot

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** installed (>= 1.0)
4. **SSH Key Pair** created in AWS EC2

## Quick Start

### 1. Create SSH Key Pair (if you don't have one)

```bash
aws ec2 create-key-pair --key-name cosmic-key --query 'KeyMaterial' --output text > ~/.ssh/cosmic-key.pem
chmod 400 ~/.ssh/cosmic-key.pem
```

### 2. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:
- `key_name`: Your AWS SSH key pair name
- `allowed_ssh_cidr`: Your IP address for SSH access (get it from https://whatismyip.com)

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply
```

### 4. Get Connection Information

After deployment completes, Terraform will output:
- Public IP address
- SSH command
- MapleStory connection details

```bash
# View outputs again
terraform output
```

## Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region | `us-east-1` | No |
| `project_name` | Project name for resources | `cosmic-maplestory` | No |
| `instance_type` | EC2 instance type | `t2.micro` | No |
| `key_name` | SSH key pair name | - | **Yes** |
| `allowed_ssh_cidr` | CIDR blocks for SSH | `["0.0.0.0/0"]` | No |
| `root_volume_size` | Root volume size (GB) | `30` | No |
| `db_password` | MySQL root password | `""` | No |

### Security

The security group allows:
- **Port 22** (SSH): From IPs in `allowed_ssh_cidr`
- **Port 8484** (MapleStory Login): Public access
- **Ports 7575-7577** (MapleStory Channels): Public access
- **Outbound**: All traffic allowed

**IMPORTANT**: Update `allowed_ssh_cidr` to restrict SSH access to your IP only!

## Ports

- **8484**: MapleStory Login Server
- **7575-7577**: MapleStory Game Channels (World 1, Channels 1-3)
- **3307**: MySQL (accessible only within container network)

## Access the Server

### SSH into Instance

```bash
ssh -i ~/.ssh/cosmic-key.pem ec2-user@<public-ip>
```

### Check Deployment Status

```bash
# Check user data script execution
sudo cat /var/log/cloud-init-output.log

# Check Docker containers
sudo docker ps

# Check application logs
cd /opt/cosmic
sudo docker-compose logs -f
```

### Verify Services

```bash
# Check MapleStory server logs
sudo docker-compose logs maplestory

# Check MySQL logs
sudo docker-compose logs db

# Restart services if needed
sudo docker-compose restart
```

## Client Configuration

To connect your MapleStory client to the server:

1. Edit your MapleStory client's connection settings to point to the public IP
2. Server IP: `<terraform-output-public-ip>`
3. Login Port: `8484`

## Costs

With default settings (t2.micro):
- **EC2 Instance**: Free tier eligible (750 hours/month for 12 months)
- **EBS Volume**: ~$3/month for 30GB
- **Data Transfer**: First 100GB/month free, then $0.09/GB
- **Elastic IP**: Free while attached to running instance

## Troubleshooting

### Server Not Responding

```bash
# SSH into instance
ssh -i ~/.ssh/cosmic-key.pem ec2-user@<public-ip>

# Check if Docker is running
sudo systemctl status docker

# Check if containers are running
sudo docker ps

# Restart Docker Compose
cd /opt/cosmic
sudo docker-compose down
sudo docker-compose up -d
```

### Database Issues

```bash
# Check database container logs
sudo docker-compose logs db

# Access MySQL directly
sudo docker-compose exec db mysql -u root -p cosmic
```

### Update Server Configuration

```bash
# SSH into instance
ssh -i ~/.ssh/cosmic-key.pem ec2-user@<public-ip>

# Edit config
cd /opt/cosmic
sudo nano config.yaml

# Restart services
sudo docker-compose restart
```

## Maintenance

### Update the Server

```bash
cd /opt/cosmic
sudo git pull
sudo docker-compose down
sudo docker-compose up -d --build
```

### Backup Database

```bash
sudo docker-compose exec db mysqldump -u root cosmic > backup.sql
```

### Monitor Resources

```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check Docker resource usage
sudo docker stats
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete the EC2 instance and all data!

## Notes

- The user data script automatically clones the Cosmic repository and starts services
- Server configuration is updated automatically with the instance's public IP
- Docker Compose is configured to start automatically on boot via systemd
- The free tier t2.micro instance may have limited performance for many concurrent users
- Consider upgrading to t3.small or larger for production use

## Support

For issues with:
- **Terraform/AWS**: Check AWS CloudWatch logs or Terraform state
- **Cosmic Server**: See [Cosmic GitHub Repository](https://github.com/P0nk/Cosmic)
- **MapleStory Client**: Refer to client-specific documentation
