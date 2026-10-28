import json
import os


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps(
            {
                "lambda": "api_lambda",
                "message": "LANDERAI API Lambda is running.",
                "environment": os.getenv("ENVIRONMENT"),
            }
        ),
    }
