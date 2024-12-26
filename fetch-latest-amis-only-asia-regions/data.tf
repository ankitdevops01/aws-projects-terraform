data "aws_regions" "all_regions" {
  all_regions = true
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  asia_regions = [
      for region in data.aws_regions.all_regions.names : region if startswith(region, "ap-")
  ]
}

# Fetch the latest Amazon Linux 2 AMI using AWS CLI within a null_resource
resource "null_resource" "latest_ami" {
  for_each = toset(local.asia_regions)
  provisioner "local-exec" {
    command = <<EOT
      aws ec2 describe-images \
        --region ${each.key} \
        --owners amazon \
        --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
        --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
        --output text > ami_id_${each.key}.txt
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}