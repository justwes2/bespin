import boto3
from boto3.dynamodb.conditions import Key, Attr
from pprint import pprint

def lambda_handler(event, context):
    
    ec2_client = boto3.client('ec2')

    instances = ec2_client.describe_instances()

    pprint(instances['Reservations'][0]['Instances'])



    # return {
    #     'statusCode': 200,
    #     'headers': {
    #         'Content-Type': 'text/html; charset=utf-8'
    #     },
    #     'body': '<p>Bonjour au monde</p>'
    # }

# For local testing
lambda_handler("", "")