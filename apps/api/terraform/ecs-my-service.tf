module "ecs_cluster_my_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.2.2"

  cluster_name = "my-service"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 0
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 0
      }
    }
  }
}

module "ecs_service_my_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.2.2"

  name        = "my-service"
  cluster_arn = module.ecs_cluster_my_service.arn

  cpu    = 1024
  memory = 4096

  container_definitions = {
    ("my-service") = {
      essential = true
      cpu       = 512
      memory    = 1024
      image     = "0000000000.dkr.ecr.eu-west-1.amazonaws.com/service-name"

      port_mappings = [
        {
          name          = "my-service"
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      readonly_root_filesystem = false

      enable_cloudwatch_logging = false

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/my-service"
          awslogs-region        = local.region
          awslogs-stream-prefix = "ecs"
        }
      }

      memory_reservation = 100
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.ecs_alb_my_service.target_group_arns, 0)
      container_name   = "my-service"
      container_port   = 3000
    }
  }

  subnet_ids = module.vpc.private_subnets

  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      source_security_group_id = module.ecs_alb_sg_my_service.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_service_discovery_http_namespace" "my_service" {
  name = "my-service"
}

module "ecs_alb_sg_my_service" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name   = "my-service"
  vpc_id = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
}

module "ecs_alb_my_service" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.7.0"

  name = "my-service"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.ecs_alb_sg_my_service.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "my-service"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "ip"

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/api/_health/live"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-299"
      }
    },
  ]
}

output "cluster_arn" {
  description = "ARN that identifies the cluster"
  value       = module.ecs_cluster_my_service.arn
}

output "cluster_id" {
  description = "ID that identifies the cluster"
  value       = module.ecs_cluster_my_service.id
}

output "cluster_name" {
  description = "Name that identifies the cluster"
  value       = module.ecs_cluster_my_service.name
}

output "cluster_capacity_providers" {
  description = "Map of cluster capacity providers attributes"
  value       = module.ecs_cluster_my_service.cluster_capacity_providers
}

output "service_id" {
  description = "ARN that identifies the service"
  value       = module.ecs_service_my_service.id
}

output "service_name" {
  description = "Name of the service"
  value       = module.ecs_service_my_service.name
}

output "service_iam_role_name" {
  description = "Service IAM role name"
  value       = module.ecs_service_my_service.iam_role_name
}

output "service_iam_role_arn" {
  description = "Service IAM role ARN"
  value       = module.ecs_service_my_service.iam_role_arn
}

output "service_iam_role_unique_id" {
  description = "Stable and unique string identifying the service IAM role"
  value       = module.ecs_service_my_service.iam_role_unique_id
}

output "service_container_definitions" {
  description = "Container definitions"
  value       = module.ecs_service_my_service.container_definitions
}

output "service_task_definition_arn" {
  description = "Full ARN of the Task Definition (including both `family` and `revision`)"
  value       = module.ecs_service_my_service.task_definition_arn
}
