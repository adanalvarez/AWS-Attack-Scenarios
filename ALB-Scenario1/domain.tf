# Fetch information about the existing hosted zone
data "aws_route53_zone" "my_zone" {
  name         = "adanalvarez.click." # Change to your domain
  private_zone = false
}

# Create a new record in the hosted zone
resource "aws_route53_record" "my_subdomain" {
  zone_id = data.aws_route53_zone.my_zone.zone_id
  name    = "test.adanalvarez.click"   # Change to your domain
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "subdomain_cert" {
  domain_name       = "test.adanalvarez.click" # Change to your domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.subdomain_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.my_zone.zone_id
  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.subdomain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
