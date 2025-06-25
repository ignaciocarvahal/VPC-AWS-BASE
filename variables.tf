
variable "region" {
  default = "us-west-1"
}


variable "az" {
  default = "us-west-1a"
}

variable "key_name" {
  description = "Nombre del par de claves EC2"
  default     = "TNM-TOPUS"
}

variable "private_key_path" {
  description = "Ruta del archivo PEM"
  type        = string
}

