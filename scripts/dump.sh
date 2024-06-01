#!/bin/sh

curl  https://api.track.toggl.com/api/v9/organizations/${ORGANIZATION_ID}/workspaces/${WORKSPACE_ID}/workspace_users \
  -H "Content-Type: application/json" \
  -u $TOGGL_API_TOKEN:api_token
