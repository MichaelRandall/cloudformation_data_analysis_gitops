#!/bin/bash

PROFILE="mran_admin"
STACK_NAME="my-postgres-test-stack"
TEMPLATE_FILE="postgresql_ec2_cloudformation.yaml"
PARAMS_FILE="params.json"

# 1. Ask for passwords (masks input)
read -sp "Enter DB Admin Password: " ADMIN_PASS
echo ""
read -sp "Enter App User Password: " APP_PASS
echo -e "\n----------------------------"


# 2. Prepare parameters from JSON
# This converts your JSON list into the Key=Value Key=Value format AWS expects
JSON_PARAMS=$(jq -r '.[] | "\(.ParameterKey)=\(.ParameterValue)"' "$PARAMS_FILE" | tr '\n' ' ')

# 2. Run deploy
# We pass the file AND the individual overrides. 
# The overrides will fill in the passwords you just typed.
echo "Starting deployment of $STACK_NAME..."
aws cloudformation deploy \
  --profile "$PROFILE" \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --parameter-overrides \
    $JSON_PARAMS \
    DBAdminPassword="$ADMIN_PASS" \
    AppPassword="$APP_PASS" \
  --capabilities CAPABILITY_IAM

echo "Waiting for stack outputs..."

# 4. Fetch the connection command
CONNECTION_CMD=$(aws cloudformation describe-stacks \
  --profile "$PROFILE" \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='PostgresLoginCommand'].OutputValue" \
  --output text)

echo -e "\n=========================================="
echo "DEPLOYMENT COMPLETE!"
echo "To connect to your database, run:"
echo "$CONNECTION_CMD"
echo "=========================================="

# 5. NEW: Optional Cleanup Step
echo ""
read -p "Would you like to DELETE this stack now? (y/N): " DELETE_CONFIRM
if [[ "$DELETE_CONFIRM" =~ ^[yY](es)?$ ]]; then
    echo "Deleting stack $STACK_NAME..."
    aws cloudformation delete-stack --profile "$PROFILE" --stack-name "$STACK_NAME"
    echo "Waiting for deletion to finish..."
    aws cloudformation wait stack-delete-complete --profile "$PROFILE" --stack-name "$STACK_NAME"
    echo "Stack deleted successfully. No further charges will accrue."
else
    echo "Keeping stack active. Remember to delete it later via the console or CLI to avoid charges."
fi