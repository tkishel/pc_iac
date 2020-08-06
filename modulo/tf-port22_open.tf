resource "aws_network_acl" "main" {
 

  egress {
    protocol   = "udp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 135
    to_port    = 135
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 100
    action     = "allow"
  }

  # Allow incoming traffic from FTP.
  egress {
    from_port   = 21
    to_port     = 21
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 300
    action     = "allow"
  }

  # Allow incoming traffic from FTP.
  egress {
    from_port   = 137
    to_port     = 139
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
    rule_no    = 400
    action     = "allow"
  }

  # Allow incoming traffic to VNC.
  ingress {
    from_port   = 5800
    to_port     = 5800
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 500
    action     = "allow"
  }

  # Allow incoming traffic to VNC.
  ingress {
    from_port   = 5900
    to_port     = 5903
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 600
    action     = "allow"
  }

  # Allow incoming traffic to Telnet.
  ingress {
    from_port   = 2323
    to_port     = 2323
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 700
    action     = "allow"
  }

  # Allow incoming traffic to Telnet.
  ingress {
    from_port   = 23
    to_port     = 23
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 800
    action     = "allow"
  }

  # Allow incoming traffic to SMTP.
  ingress {
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 900
    action     = "allow"
  }

  # Allow incoming traffic to POP3.
  ingress {
    from_port   = 110
    to_port     = 110
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 1000
    action     = "allow"
  }

  # Allow incoming traffic to IMAP.
  ingress {
    from_port   = 143
    to_port     = 143
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 1100
    action     = "allow"
  }

  # Allow incoming traffic to DNS.
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
    rule_no    = 1200
    action     = "allow"
  }

  # Allow incoming traffic from TFTP.
  egress {
    from_port   = 69
    to_port     = 69
    protocol    = "udp"
    cidr_block = "0.0.0.0/0"
    rule_no    = 1300
    action     = "allow"
  }

  tags = {
    Name = "main"
  }
}