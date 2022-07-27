resource "aws_route53_zone" "cartographie_nationale" {
  name = local.domainName
  tags = local.tags
}

resource "aws_route53_record" "main_name_servers_record" {
  name            = aws_route53_zone.cartographie_nationale.name
  allow_overwrite = true
  ttl             = 30
  type            = "NS"
  zone_id         = aws_route53_zone.cartographie_nationale.zone_id
  records         = aws_route53_zone.cartographie_nationale.name_servers
}

resource "aws_acm_certificate" "acm_certificate" {
  provider                  = aws.us-east-1
  domain_name               = local.domainName
  subject_alternative_names = ["*.${local.domainName}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_route53_record" "certificate_validation_main" {
  name            = sort(aws_acm_certificate.acm_certificate.domain_validation_options[*].resource_record_name)[0]
  depends_on      = [aws_acm_certificate.acm_certificate]
  zone_id         = aws_route53_zone.cartographie_nationale.id
  type            = "CNAME"
  ttl             = "300"
  records         = [sort(aws_acm_certificate.acm_certificate.domain_validation_options[*].resource_record_value)[0]]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "certification_main" {
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.acm_certificate.arn
  validation_record_fqdns = [
    aws_route53_record.certificate_validation_main.fqdn,
  ]
  timeouts {
    create = "15m"
  }
}

resource "aws_route53_record" "cartographie_nationale_record_ipv4" {
  name    = local.service.cartographie_nationale.name
  zone_id = aws_route53_zone.cartographie_nationale.zone_id
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cartographie_nationale.domain_name
    zone_id                = aws_cloudfront_distribution.cartographie_nationale.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "driver_record_ipv6" {
  name    = local.service.cartographie_nationale.name
  zone_id = aws_route53_zone.cartographie_nationale.zone_id
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.cartographie_nationale.domain_name
    zone_id                = aws_cloudfront_distribution.cartographie_nationale.hosted_zone_id
    evaluate_target_health = false
  }
}