# Import Existing Elastic IP into Terraform

## Step 1: Find the EIP Allocation ID

You have two options:

### Option A: Using AWS Console
1. Go to AWS Console → EC2 → Elastic IPs
2. Find the Elastic IP associated with your instance (public IP: 51.84.246.221 or 51.85.13.77)
3. Copy the **Allocation ID** (format: `eipalloc-xxxxxxxxxxxxxxxxx`)

### Option B: Using AWS CLI
```bash
# List all Elastic IPs
aws ec2 describe-addresses --region il-central-1

# Or find by public IP
aws ec2 describe-addresses \
  --filters "Name=public-ip,Values=51.84.246.221" \
  --region il-central-1 \
  --query 'Addresses[0].AllocationId' \
  --output text
```

## Step 2: Import the EIP

Once you have the allocation ID, run:

```bash
cd terraform
terraform import aws_eip.cosmic_eip <allocation-id>
```

Example:
```bash
terraform import aws_eip.cosmic_eip eipalloc-0a1b2c3d4e5f6g7h8
```

## Step 3: Update the Configuration

After import, uncomment the instance association in `main.tf`:

```hcl
resource "aws_eip" "cosmic_eip" {
  domain   = "vpc"
  instance = aws_instance.cosmic_server.id  # Uncomment this line

  tags = {
    Name = "${var.project_name}-eip"
  }

  depends_on = [aws_internet_gateway.cosmic_igw]
}
```

## Step 4: Verify and Apply

```bash
terraform plan
# Review the changes - it should show the instance association
terraform apply
```

## Note

If the public IP is NOT an Elastic IP (just an auto-assigned public IP), you'll need to:
1. Allocate a new Elastic IP in AWS Console
2. Associate it with your instance
3. Then import it using the steps above

