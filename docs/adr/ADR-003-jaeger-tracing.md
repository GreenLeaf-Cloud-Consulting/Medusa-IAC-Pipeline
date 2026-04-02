ADR-003 - Choix de Jaeger pour le tracing distribué

Date : mars 2026
Statut : validé

On avait besoin de voir ce qui se passe entre les 11 microservices quand une requête prend du temps ou échoue. Sans tracing on voyait juste "erreur 500" dans les logs sans savoir lequel des services était en cause.

On a regardé AWS X-Ray et Jaeger. On a pris Jaeger parce que c'est cloud-agnostic, si on change de cloud un jour on repart avec le même outil. X-Ray c'est 100% lié à AWS.

La config a été galère au début. Le frontend Online Boutique envoie les traces mais faut savoir quelles variables d'env mettre. On a d'abord essayé OTEL_EXPORTER_OTLP_ENDPOINT avec le port 4318 (HTTP) mais ça marchait pas. Ensuite port 4317 (gRPC) mais toujours rien dans l'interface Jaeger. En regardant les logs du pod on a vu "Tracing disabled." - donc le tracing était désactivé par défaut. La vraie variable c'est ENABLE_TRACING=1 et COLLECTOR_SERVICE_ADDR pour l'endpoint.

Autre problème : les Network Policies qu'on avait mises bloquaient le trafic du namespace boutique vers le namespace tracing. Fallait ajouter une règle egress explicite pour le port 4317.

En prod on mettrait Jaeger avec un vrai backend de stockage (Elasticsearch) parce que là les traces sont en mémoire et perdues si le pod redémarre.
