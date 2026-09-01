import json
import os


def handler(event, context):
    """Return a simple success payload for LocalStack API testing."""
    table_name = os.environ.get("TABLE_NAME", "users")

    payload = {
        "message": "Hello from Terraform + LocalStack!",
        "database_status": "User created successfully",
        "table_name": table_name,
        "event": str(event),
    }

    return {
        "statusCode": 200,
        "body": json.dumps(payload),
    }