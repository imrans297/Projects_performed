variable "bucket_name" {
  description = "Name of the S3 bucket to upload files to"
  type        = string
}

variable "tags" {
  description = "Tags to apply to S3 objects"
  type        = map(string)
  default     = {}
}