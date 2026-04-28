#!/bin/bash
set -e

REGION="us-east-1"
CLUSTER="cluster-bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"

COMMIT_HASH="$1"

if [[ -z "$COMMIT_HASH" ]]; then
  echo "Uso: $0 <commit-hash>"
  echo "Use ./rollback-list.sh para ver as versões disponíveis."
  exit 1
fi

# Busca a task definition que contém o commit hash na imagem
TARGET_ARN=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY \
  --region $REGION --query 'taskDefinitionArns[]' --output text | tr '\t' '\n' | while read ARN; do
  IMAGE=$(aws ecs describe-task-definition --task-definition "$ARN" --region $REGION \
    --query 'taskDefinition.containerDefinitions[0].image' --output text)
  if echo "$IMAGE" | grep -q ":$COMMIT_HASH$"; then
    echo "$ARN"
    break
  fi
done)

if [[ -z "$TARGET_ARN" ]]; then
  echo "Nenhuma task definition encontrada para o commit '$COMMIT_HASH'."
  exit 1
fi

REVISION=$(echo $TARGET_ARN | grep -o ':[0-9]*$' | tr -d ':')

echo "Revertendo para task-def-bia:$REVISION (commit: $COMMIT_HASH)..."

aws ecs update-service --cluster $CLUSTER --service $SERVICE \
  --task-definition "$TARGET_ARN" --region $REGION > /dev/null

echo "Rollback iniciado. Task definition ativa: $TARGET_ARN"
