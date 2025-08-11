# Get all files from html-web-app directory
locals {
  web_files = fileset("${path.root}/../html-web-app", "**/*")
  
  # MIME type mapping
  mime_types = {
    "html" = "text/html"
    "htm"  = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "xml"  = "application/xml"
    "md"   = "text/markdown"
  }
}

# Upload all web application files to S3
resource "aws_s3_object" "web_files" {
  for_each = local.web_files
  
  bucket = var.bucket_name
  key    = "html-web-app/${each.value}"
  source = "${path.root}/../html-web-app/${each.value}"
  etag   = filemd5("${path.root}/../html-web-app/${each.value}")
  
  # Set appropriate content type based on file extension
  content_type = lookup(
    local.mime_types,
    lower(split(".", each.value)[length(split(".", each.value)) - 1]),
    "application/octet-stream"
  )
  
  tags = var.tags
}