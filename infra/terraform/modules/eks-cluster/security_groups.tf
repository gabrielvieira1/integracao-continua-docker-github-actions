# Security Groups para EKS e RDS
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-sg"
  })
}

resource "aws_security_group" "node_group_sg" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS node group"
  vpc_id      = module.vpc.vpc_id

  # Allow pods to communicate with cluster API Server
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow pods to communicate with other pods
  egress {
    from_port = 1025
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  # Allow all outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-sg"
  })
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-rds-sg"
  })
}

# RDS Security Group Rules
resource "aws_security_group_rule" "rds_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group_sg.id
  security_group_id        = aws_security_group.rds_sg.id
  description              = "Allow PostgreSQL access from EKS nodes"
}

resource "aws_security_group_rule" "rds_ingress_from_cluster" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  security_group_id        = aws_security_group.rds_sg.id
  description              = "Allow PostgreSQL access from EKS cluster"
}

# Node Group Security Group Rules
resource "aws_security_group_rule" "node_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.node_group_sg.id
  description       = "Allow nodes to communicate with each other"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  security_group_id        = aws_security_group.node_group_sg.id
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
}

# Cluster Security Group Rules
resource "aws_security_group_rule" "cluster_ingress_node_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_group_sg.id
  security_group_id        = aws_security_group.eks_cluster_sg.id
  description              = "Allow pods to communicate with the cluster API Server"
}
