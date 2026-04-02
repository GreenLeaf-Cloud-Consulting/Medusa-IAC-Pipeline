# ADR-005 : External Secrets Operator pour la gestion des secrets

**Date** : 2026-04-01  
**Statut** : Accepté

## Contexte

Les secrets (credentials, mots de passe) ne doivent **jamais** être stockés dans Git. Kubernetes propose des Secrets natifs, mais ils sont en base64 (pas chiffrés) et difficiles à auditer.

## Décision

Utilisation d'**External Secrets Operator (ESO)** avec **AWS Secrets Manager** comme backend.

## Architecture

```
AWS Secrets Manager
  └── prod/online-boutique/config
          │
          ▼ (sync automatique toutes les 1h)
External Secrets Operator (namespace: external-secrets)
          │
          ▼
K8s Secret: boutique-config (namespace: boutique)
          │
          ▼
Pods (montage via envFrom ou volumeMount)
```

## Alternatives évaluées

- **Sealed Secrets** : chiffrement côté K8s, mais pas d'audit centralisé
- **Vault (HashiCorp)** : plus puissant mais overhead opérationnel élevé
- **IRSA** : à préférer en prod (pas de credentials hardcodés dans K8s)

## Conséquences

- **Positif** : Secrets centralisés, rotation automatique, audit trail AWS
- **Positif** : Un seul endroit pour mettre à jour un secret
- **Négatif actuel** : Credentials AWS stockés dans K8s Secret (accepté pour ce projet)
- **En prod** : Utiliser IRSA (IAM Roles for Service Accounts) — zéro credentials dans K8s
