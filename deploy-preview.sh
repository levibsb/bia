#!/bin/bash
set -e

REGION="us-east-1"
ECR_REPO="894565488639.dkr.ecr.us-east-1.amazonaws.com/bia"
CLUSTER="cluster-bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"

COMMIT_HASH=$(git rev-parse --short=7 HEAD)
IMAGE_URI="$ECR_REPO:$COMMIT_HASH"

CURRENT_REVISION=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY \
  --region $REGION --query 'taskDefinition.revision' --output text)

echo "==============================="
echo " PREVIEW DO DEPLOY"
echo "==============================="
echo " Commit hash : $COMMIT_HASH"
echo " Imagem      : $IMAGE_URI"
echo " Task def    : $TASK_FAMILY:$CURRENT_REVISION → $TASK_FAMILY:$((CURRENT_REVISION + 1))"
echo " Cluster     : $CLUSTER"
echo " Service     : $SERVICE"
echo "==============================="
echo ""
read -p "Confirma o deploy? (s/N) " CONFIRM

if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
  echo "Deploy cancelado."
  exit 0
fi

exec "$(dirname "$0")/deploy-versioned.sh"
