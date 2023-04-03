from src.authorizer import lambda_handler


def test_lambda_handler() -> None:
    event = {}
    # event["authorizationToken"] = "abc123"
    event["headers"] = {}
    event["headers"]["Authorization"] = "abc123"
    result = lambda_handler(event, context=None)
    expected = {
        "principalId": "abc123",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Resource": [
                        "arn:aws:execute-api:us-east-1:288195736164:1xzg485zja/*/*"
                    ],
                    "Effect": "Allow",
                }
            ],
        },
    }
    assert result == expected
