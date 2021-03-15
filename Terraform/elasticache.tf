resource "aws_elasticache_cluster" "buildsec-elasticache" {
  cluster_id           = "opa-rate-limiter-cache-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  //engine_version       = "6.0.5"
  port                 = 6379
  subnet_group_name = aws_elasticache_subnet_group.buildsec-elasticache-subnet-group.name
  security_group_ids = [aws_security_group.buildsec-elasticache.id]
}

resource "aws_elasticache_subnet_group" "buildsec-elasticache-subnet-group" {
  name       = "buildsec-elasticache-subnet-group"
  subnet_ids = [aws_subnet.buildsec-subnet-public-1.id]
}
