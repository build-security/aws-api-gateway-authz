# Simple authorization logic that:
# - receives a request object from AWS API Gateway
# - passes it to our Policy Decision Point (PDP)
# - receives a policy decision from the PDP, or an appropriate error message
# - converts the policy decision into an object that API Gateway can understand
# - returns the decision to AWS API Gateway
import os
import re
import requests

pdp_host = os.environ['PDP_HOST']
pdp_policy_path = os.environ['PDP_POLICY_PATH']
pdp_endpoint = 'http://{}:8181/v1/data/{}'.format(pdp_host, pdp_policy_path)

def lambda_handler(event, context):
    result = call_opa(event)
    
    response = {
        'policyDocument': {
            'Statement': {
                'Action': 'execute-api:Invoke',
                'Effect': 'Allow' if result['allow'] == True else 'Deny',
                'Resource': '*',
            }
        },
    }
    
    if not (result['allow'] == True):
        response['context'] = {
            'denyMessage': result['authz_error']
        }
            
    
    return response

def call_opa(pdp_input):
    print('Calling PDP endpoint', pdp_endpoint)
    print('PDP input:', pdp_input)
    
    r = requests.post(
        pdp_endpoint,
        json={
            "input": pdp_input,
        },
    )
    
    print('PDP Response Code', r.status_code)
    print('PDP Response JSON', r.json())
    
    return r.json()['result']
