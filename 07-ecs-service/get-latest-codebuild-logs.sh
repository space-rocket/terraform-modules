#!/bin/bash

# Configuration
LOG_GROUP="/dt/dev/api/ecs-service/codebuild/deploy"
REGION="us-west-2"
OUTPUT_FILE="codebuild-deploy-latest.log"

echo "🔍 Fetching latest log stream from $LOG_GROUP..."

# Get the most recent log stream name
STREAM_NAME=$(aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP" \
  --order-by LastEventTime \
  --descending \
  --limit 1 \
  --region "$REGION" \
  --query "logStreams[0].logStreamName" \
  --output text)

if [[ -z "$STREAM_NAME" || "$STREAM_NAME" == "None" ]]; then
  echo "❌ No log stream found in $LOG_GROUP"
  exit 1
fi

echo "📄 Downloading logs from stream: $STREAM_NAME..."

# Download the log events
aws logs get-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$STREAM_NAME" \
  --limit 1000 \
  --region "$REGION" \
  --query "events[*].message" \
  --output text > "$OUTPUT_FILE"

echo "✅ Logs saved to $OUTPUT_FILE"

echo "🔎 Searching for 502 errors or related messages..."
grep -Ei '502|Bad Gateway|Health check|failed|error' "$OUTPUT_FILE" || echo "ℹ️ No relevant errors found."
