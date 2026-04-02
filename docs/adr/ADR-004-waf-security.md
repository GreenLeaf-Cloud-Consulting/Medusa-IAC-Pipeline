ADR-004 - WAF (Web Application Firewall)

Date : mars 2026
Statut : validé, association en attente

On a mis en place un WAF AWS pour protéger le site. Les règles qu'on a activées :
- Protection contre les IPs malveillantes connues (liste AWS)
- Protection OWASP Top 10 (injections, XSS, etc.)
- Protection contre les injections SQL
- Rate limiting : 2000 requêtes par 5 minutes par IP

Un truc qu'on a pas anticipé : AWS WAFv2 supporte seulement les ALB (Application Load Balancer), pas les Classic ELB. Or Kubernetes crée un Classic ELB par défaut quand on fait un service de type LoadBalancer. Du coup le WAF est bien créé dans AWS mais il est pas associé à notre load balancer pour l'instant.

Pour l'associer il faudrait migrer vers AWS Load Balancer Controller qui crée des ALB à la place. On a pas eu le temps de faire ça mais le module Terraform est prêt avec la variable elb_arn qui attend juste l'ARN de l'ALB.
