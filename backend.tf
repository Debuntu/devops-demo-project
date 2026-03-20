terraform {
  backend "s3" {
    bucket = "terrabucket-deba"
    #using key path, terraform will create a subdir named 'state' and under it , it  will create a file named 'terraform.tfstate' where it will save the state file.
    key = "state/terraform.tfstate"
    region = "us-east-1"
  }
}