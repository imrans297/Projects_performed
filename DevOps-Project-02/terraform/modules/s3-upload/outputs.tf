output "uploaded_files" {
  description = "List of uploaded file keys"
  value       = keys(aws_s3_object.web_files)
}

output "upload_count" {
  description = "Number of files uploaded"
  value       = length(aws_s3_object.web_files)
}