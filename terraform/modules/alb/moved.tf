# State migration: renamed medusa_* resources to generic names
moved {
  from = aws_lb_target_group.medusa_backend
  to   = aws_lb_target_group.backend
}

moved {
  from = aws_lb_target_group.medusa_storefront
  to   = aws_lb_target_group.storefront
}
