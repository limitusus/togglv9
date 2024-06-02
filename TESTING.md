# Testing togglv9 gem

Prepare empty workspace for testing.
**WARNING: This workspace can be emptied. You should not use the production workspace for testing.**

Set environment variables like below (`.envrc` for direnv)

```sh
# Togglv9 Test data
export TOGGL_API_TOKEN=ADMIN_USER_API_TOKEN
export TOGGL_EMAIL=admin@example.com
export TOGGL_USERNAME=dummy1
export TOGGL_PASSWORD=dummy_password_admin
export TOGGL_USER_ID=11000000
export OTHER_EMAIL=dummy@example.com
export OTHER_USERNAME=dummy2
export OTHER_USER_ID=1000001

# For dump info
export ORGANIZATION_ID=987654321
export WORKSPACE_ID=12345678
```

- `TOGGL_*` user should be an administrator of the workspace
- `OTHER_*` user can either administrator or normal user

Some user information can be dumped with `scripts/dump.sh`.
