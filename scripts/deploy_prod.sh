#!/usr/bin/env bash
# Deploy production Cloud Functions and Firestore rules
# Usage: ./deploy_prod.sh <PROJECT_ID>
set -euo pipefail
PROJECT_ID=${1:-}
if [ -z "$PROJECT_ID" ]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 2
fi

echo "Checking firebase project: $PROJECT_ID"
# Ensure firebase tools are installed
if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI not found. Install with: npm install -g firebase-tools"
  exit 2
fi

echo "Make sure you've enabled Blaze billing for project $PROJECT_ID in Firebase Console."
read -p "Have you enabled Blaze for $PROJECT_ID? (y/N) " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Enable Blaze and re-run this script when ready. Exiting."
  exit 3
fi

# Deploy functions
echo "Deploying Cloud Functions to $PROJECT_ID..."
firebase deploy --only functions --project "$PROJECT_ID"

# Deploy rules (using production rules file if present)
if [ -f firestore.rules.prod ]; then
  echo "Applying production rules from firestore.rules.prod"
  cp firestore.rules.prod firestore.rules
fi

echo "Deploying Firestore rules to $PROJECT_ID..."
firebase deploy --only firestore:rules --project "$PROJECT_ID"

echo "Deployment complete. Run smoke tests to validate production behavior." 
