#!/usr/bin/env bash
# Déploie les règles Firestore et les Cloud Functions en production.
# Les tests des règles (émulateur, JDK 21+) doivent passer avant tout déploiement.
# Usage : ./scripts/deploy_prod.sh <PROJECT_ID>
set -euo pipefail
PROJECT_ID=${1:-}
if [ -z "$PROJECT_ID" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 2
fi
cd "$(dirname "$0")/.."

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI introuvable : npm install -g firebase-tools"
  exit 2
fi

echo "Les Cloud Functions exigent le forfait Blaze sur $PROJECT_ID."
read -p "Blaze est-il activé sur $PROJECT_ID ? (y/N) " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Activez Blaze puis relancez. Abandon."
  exit 3
fi

echo "Tests des règles Firestore..."
(cd test_rules && npm ci --no-audit --no-fund && npm test)

echo "Déploiement des règles et des Cloud Functions sur $PROJECT_ID..."
firebase deploy --only firestore:rules,firestore:indexes,functions --project "$PROJECT_ID"

echo "Déploiement terminé."
