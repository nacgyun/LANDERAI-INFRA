import os


def lambda_handler(event, context):
    return {
        "lambda": "persist_result_lambda",
        "message": "LANDERAI persist result Lambda is running.",
        "environment": os.getenv("ENVIRONMENT"),
        "input": event,
    }
