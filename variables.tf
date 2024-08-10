variable "tags" {
  type = object({
    Project     = string,
    Environment = string
  })
  default = {
    Project     = "road-map-ec2-terraform"
    Environment = "dev"
  }
}