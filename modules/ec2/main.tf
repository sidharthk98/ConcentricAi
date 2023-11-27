
data "aws_iam_policy_document" "bastion-assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "bastion_instance_profile"
  role = aws_iam_role.bastion-role.name
}

resource "aws_iam_role" "bastion-role" {
  name               = "bastion-role"
  assume_role_policy = data.aws_iam_policy_document.bastion-assume_role.json
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.bastion-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.bastion-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"              
  role       = aws_iam_role.bastion-role.name
}

resource "aws_iam_role_policy_attachment" "AmazonS3ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"              
  role       = aws_iam_role.bastion-role.name
}

resource "aws_iam_role_policy" "EKS-cluster-action-policy" {
  name = "EKS-cluster-action-policy"
  role = aws_iam_role.bastion-role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:ListNodegroups",
          "eks:ListEksAnywhereSubscriptions",
          "eks:UpdateAddon",
          "eks:UpdateClusterConfig",
          "eks:DescribeEksAnywhereSubscription",
          "eks:DescribeNodegroup",
          "eks:ListUpdates",
          "eks:DescribeUpdate",
          "eks:AccessKubernetesApi",
          "eks:CreateAddon",
          "eks:UpdateNodegroupConfig",
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:eks:us-east-1:403968538415:cluster/private-eks"
      },
    ]
  })
}
# ----------------------------------------------------------------------------
# Bastion EC2


data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = var.subnet
  iam_instance_profile = aws_iam_instance_profile.bastion_instance_profile.name

    tags = {
    Name = "bastion-instance"
  }
  user_data_replace_on_change = true
  user_data =file("script.sh")

}

output "bastion_role" {
  value = aws_iam_role.bastion-role
}