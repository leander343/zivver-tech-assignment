terraform {
  backend "s3" {
    bucket         = "tfstate-zivvy"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "app-state-zivvy"
  }
}