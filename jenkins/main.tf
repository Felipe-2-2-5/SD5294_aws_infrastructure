module "env" {
  source      = "../modules/env"
  environment = var.environment
  project     = var.project

}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  user_data = <<-EOT
    #!/bin/bash
    echo "Copying the SSH Key Of Jenkins to the server"
    echo -e "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHLk5yPp+B/1QBg6Ox0lMySfFisBRFi0H04Qww+X+w8lMFo+Wcec1MET6TfjGhmFEOvj4NbYcaknRKHqczwgubg= trunglv" >> /home/ubuntu/.ssh/authorized_keys
    ## install java 17
    apt update && apt install curl wget openjdk-17-jre openjdk-17-jdk -y
    ##  install jenkin
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ |  tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update && apt-get install jenkins -y
    systemctl enable jenkins && systemctl start jenkins
    ## install docker
    # Add Docker's official GPG key:
    apt-get update
    apt-get install ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    systemctl enable docker && systemctl start docker
    # Add Jenkins user into docker group
    usermod -aG docker jenkins

    ## install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client

    ## install trivy
    # Debian/Ubuntu
    apt-get install wget apt-transport-https gnupg lsb-release
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key |  apt-key add -
    echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main |  tee -a /etc/apt/sources.list.d/trivy.list
    apt-get update
    apt-get install trivy -y
    # Refer: https://aquasecurity.github.io/trivy/v0.29.2/getting-started/installation/
    # install aws cli
    apt install unzip -y
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    aws --version


  EOT
}


module "ec2_jenkins" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-instance"

  create_spot_instance        = true
  spot_price                  = "0.60"
  spot_type                   = "persistent"
  associate_public_ip_address = true
  instance_type               = "t3.medium"
  ami                         = data.aws_ami.ubuntu.id
  monitoring                  = true
  subnet_id                   = data.terraform_remote_state.networking.outputs.vpc_public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.sg_jenkins.id]
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance Jenkins"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore         = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEC2ContainerRegistryFullAccess = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  }

  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true

  instance_tags = {
    Terraform   = "true"
    Environment = var.environment
    Name        = "jenkins"
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Name        = "jenkins"
  }
}

resource "aws_security_group" "sg_jenkins" {
  name_prefix = "sg_jenkins"
  description = "Allow Jenkins traffic"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.networking.outputs.vpc_cidr_block]
  }

  ingress {
    description      = "allow 8080 jenkins"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "allow ssh jenkins"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
