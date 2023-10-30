resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.2"

  values = [
    templatefile("${path.module}/templates/ingress-nginx/${var.environment}.yaml", {
    })
  ]
}

resource "kubernetes_ingress_v1" "ingress_grafana" {
  metadata {
    name      = "ingress-grafana"
    namespace =  "kube-prometheus-stack"
    labels = {
      "app" = "ingress-nginx"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                number = 80
              }
            }
          }

          path      = "/"
          path_type = "Prefix"
        }
      }
    }
  }
    depends_on = [
    helm_release.ingress_nginx,
  ]
}

# resource "kubernetes_ingress_v1" "ingress_alb" {
#   metadata {
#     name      = "ingress-nginx"
#     namespace = "ingress-nginx"
#     labels = {
#       "app" = "ingress-nginx"
#     }
#     annotations = {
#       "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
#       # "alb.ingress.kubernetes.io/certificate-arn"  = lookup(local.env, "alb_cert_arn", "")
#       "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ "HTTP" : 80 }, { "HTTPS" : 443 }])
#       "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
#       "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
#       "alb.ingress.kubernetes.io/success-codes"    = "404"
#       "alb.ingress.kubernetes.io/target-type"      = "ip"
#     }
#   }

#   spec {
#     ingress_class_name = "nginx"
#     rule {
#       http {
#         path {
#           backend {
#             service {
#               name = "ingress-nginx-controller"
#               port {
#                 number = 443
#               }
#             }
#           }

#           path      = "/"
#           path_type = "Prefix"
#         }
#       }
#     }
#   }
# }