variable "aws" {
    type = "map"
    default = {
        access_key = ""
        secret_key = ""
        ec2_key_path = ""
        ec2_key_name = ""
        region = "ap-northeast-1"
        image = "ami-08e5c166"
        instance_type = "g2.2xlarge"
        root = "ec2-user"
    }
}

provider "aws" {
    access_key = "${var.aws.access_key}"
    secret_key = "${var.aws.secret_key}"
    region = "${var.aws.region}"
}

resource "aws_security_group" "allow_ssh_httpd" {
    name = "allow_ssh_httpd"
    description = "Allow ssh and HTTP inbound traffic"
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
}

resource "aws_instance" "coco" {
    ami = "${var.aws.image}"
    key_name = "${var.aws.ec2_key_name}"
    security_groups = ["${aws_security_group.allow_ssh_httpd.name}"]
    instance_type = "${var.aws.instance_type}"
    connection {
        key_file = "${var.aws.ec2_key_path}"
    }
    tags {
        Name = "ML"
    }
}

resource "aws_eip" "coco" {
    instance = "${aws_instance.coco.id}"
    
    connection {
        host = "${self.public_ip}"
        user = "${var.aws.root}"
        password = ""
        private_key = "${var.aws.ec2_key_path}"
    }

    provisioner "file" {
        source = "./setup.sh"
        destination = "/tmp/setup.sh"
    }
    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/setup.sh",
            "sed -i 's/\r//' /tmp/setup.sh",
            "sudo /tmp/setup.sh"
        ]
    }

}
