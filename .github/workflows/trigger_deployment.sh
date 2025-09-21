#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Required inputs from the GitHub Actions workflow.
# These variables are passed from the workflow into the script.
PAT="$1"
DEPLOYMENT_REPO="$2"
DEPLOYMENT_WORKFLOW="$3"
PIPELINE_NAME="$4"
BRANCH_NAME="$5"
IMAGE_URL="$6"

# A function to print to stderr and exit.
error_exit() {
  echo "$1" >&2
  exit 1
}

echo "Attempting to trigger deployment for repo: $DEPLOYMENT_REPO, workflow: $DEPLOYMENT_WORKFLOW"
echo "with image: $IMAGE_URL"

# Create a temporary file to store the API response body.
response_file=$(mktemp)

# Execute curl, writing the HTTP status code to a variable and the body to the temp file.
http_status_code=$(curl -s -w "%{http_code}" -L \
  -o "$response_file" \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $PAT" \
  "https://api.github.com/repos/$DEPLOYMENT_REPO/actions/workflows/$DEPLOYMENT_WORKFLOW.yml/dispatches" \
  -d "{\"ref\":\"$BRANCH_NAME\",\"inputs\":{\"pipeline_name\":\"$PIPELINE_NAME\", \"branch_name\":\"$BRANCH_NAME\", \"image_url\":\"$IMAGE_URL\"}}" \
)

echo "API response status code: $http_status_code"
echo "--- API Response Body ---"
cat "$response_file"
echo "-------------------------"

# Fail the script if the status code is not a success (2xx).
if [ "$http_status_code" -lt 200 ] || [ "$http_status_code" -ge 300 ]; then
  error_exit "Error: API call failed with status code $http_status_code"
fi

echo "Successfully triggered workflow. View runs at: https://github.com/$DEPLOYMENT_REPO/actions/workflows/$DEPLOYMENT_WORKFLOW.yml"

# Clean up the temporary file.
rm "$response_file"
