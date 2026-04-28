#!/bin/bash

REGION="us-east-1"
TASK_FAMILY="task-def-bia"

ACTIVE_ARN=$(aws ecs describe-services --cluster cluster-bia --services service-bia \
  --region $REGION --query 'services[0].taskDefinition' --output text)

echo "==============================="
echo " VERSÕES PARA ROLLBACK"
echo "==============================="
printf "%-6s %-12s %s\n" "REV" "COMMIT" "STATUS"
echo "-------------------------------"

aws ecs list-task-definitions --family-prefix $TASK_FAMILY --region $REGION \
  --sort DESC --query 'taskDefinitionArns[]' --output text | tr '\t' '\n' | while read ARN; do

  REVISION=$(echo $ARN | grep -o ':[0-9]*$' | tr -d ':')
  IMAGE=$(aws ecs describe-task-definition --task-definition "$ARN" --region $REGION \
    --query 'taskDefinition.containerDefinitions[0].image' --output text)
  TAG=$(echo $IMAGE | cut -d: -f2)

  if [[ "$ARN" == "$ACTIVE_ARN" ]]; then
    STATUS="← ATIVO (não disponível para rollback)"
  else
    STATUS="./rollback.sh $TAG"
  fi

  printf "%-6s %-12s %s\n" "$REVISION" "$TAG" "$STATUS"
done
