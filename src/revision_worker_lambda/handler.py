def lambda_handler(event, context):
    return {
        "lambda": "revision_worker_lambda",
        "message": "LANDERAI revision worker Lambda is running.",
        "event": event,
    }
