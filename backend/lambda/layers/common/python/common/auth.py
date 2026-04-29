def user_id(event):
    return event["requestContext"]["authorizer"]["claims"]["sub"]
