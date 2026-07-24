resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/tech-challenge-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/tech-challenge-frontend"
  retention_in_days = 7
}
