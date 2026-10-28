import os


def lambda_handler(event, context):
    return {
        "lambda": "design_plan_lambda",
        "message": "LANDERAI design plan Lambda is running.",
        "environment": os.getenv("ENVIRONMENT"),
        "input": event,
    }
