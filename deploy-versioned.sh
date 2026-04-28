#!/bin/bash
set -e

REGION="us-east-1"
ECR_REGISTRY="894565488639.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="$ECR_REGISTRY/bia"
CLUSTER="cluster-bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"
CONTAINER_NAME="bia"

COMMIT_HASH=$(git rev-parse --short=7 HEAD)
IMAGE_URI="$ECR_REPO:$COMMIT_HASH"

echo "==> Commit: $COMMIT_HASH"
echo "==> Imagem: $IMAGE_URI"

# Login ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build e push
docker build -t "$IMAGE_URI" .
docker push "$IMAGE_URI"

# Busca task definition atual e gera nova com a imagem do commit
TASK_DEF=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY --region $REGION \
  --query 'taskDefinition' --output json)

NEW_TASK_DEF=$(echo "$TASK_DEF" | python3 -c "
import json, sys
td = json.load(sys.stdin)
for c in td['containerDefinitions']:
    if c['name'] == '$CONTAINER_NAME':
        c['image'] = '$IMAGE_URI'
for key in ['taskDefinitionArn','revision','status','requiresAttributes','registeredAt','registeredBy','compatibilities']:
    td.pop(key, None)
print(json.dumps(td))
")

# Registra nova revisão da task definition
NEW_REVISION=$(aws ecs register-task-definition --region $REGION \
  --cli-input-json "$NEW_TASK_DEF" \
  --query 'taskDefinition.taskDefinitionArn' --output text)

echo "==> Nova task definition: $NEW_REVISION"

# Atualiza o service
aws ecs update-service --cluster $CLUSTER --service $SERVICE \
  --task-definition "$NEW_REVISION" --region $REGION > /dev/null

echo "==> Deploy iniciado. Task definition: $NEW_REVISION"
