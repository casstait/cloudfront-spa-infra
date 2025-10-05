resource "aws_shield_protection" "cloudfront_cdn" {
  name         = "cdn-shield-protection"
  resource_arn = aws_cloudfront_distribution.this.arn
}

resource "aws_shield_application_layer_automatic_response" "cloudfront_cdn" {
  ## Shield protection must be deployed before enabling automatic response
  depends_on = [aws_shield_protection.cloudfront_cdn]

  resource_arn = aws_cloudfront_distribution.this.arn
  action       = "BLOCK"
}
