import os


def lambda_handler(event, context):
    return {
        "lambda": "embedding_lambda",
        "message": "LANDERAI embedding Lambda is running.",
        "environment": os.getenv("ENVIRONMENT"),
        "input": event,
    }
