import json
from typing import Any, Dict


def lambda_handler(event, context) -> Dict[str, Any]:
    print("Event: {}".format(event))
    print("Context: {}".format(context))
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps("Hello from Docker in lambda 🐋"),
    }
