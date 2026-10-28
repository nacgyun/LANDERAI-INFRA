import os


def lambda_handler(event, context):
    return {
        "lambda": "landing_page_variant_lambda",
        "message": "LANDERAI landing page variant Lambda is running.",
        "environment": os.getenv("ENVIRONMENT"),
        "input": event,
    }
