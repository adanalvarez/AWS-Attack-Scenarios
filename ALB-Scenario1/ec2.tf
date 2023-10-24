resource "aws_instance" "ec2" {
  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = lookup(var.aws_amis, var.aws_region)

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = aws_subnet.subnet.id
  user_data              = file("userdata.sh")
}