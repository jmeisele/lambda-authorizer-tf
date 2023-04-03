def lambda_handler(event, context):
    # 1 - Log the event
    print("*********** The event is: ***************")
    print(f"event: {event}")

    # 2 - See if the person's token is valid
    # if event["authorizationToken"] == "abc123":
    if event["headers"]["Authorization"] == "abc123":
        auth = "Allow"
    else:
        auth = "Deny"

    # 3 - Construct and return the response
    auth_response = {
        "principalId": "abc123",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Resource": [
                        "arn:aws:execute-api:us-east-1:YOURACCOUNTNUMBER:2ogoj2ul12/test/GET/customers"
                    ],
                    "Effect": auth,
                }
            ],
        },
    }
    return auth_response
