import json
import boto3

def lambda_handler(event, context):

    dynamo_resource = boto3.resource('dynamodb')
    table = dynamo_resource.Table('bespin_report_ec2')

    response = table.scan()
    instance_data = response['Items']

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps(instance_data)
    }
