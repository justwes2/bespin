import boto3
# from boto3.dynamodb.conditions import Key, Attr

def lambda_handler(event, context):
    
    ec2_client = boto3.client('ec2')
    instances = ec2_client.describe_instances()

    dynamo_resource = boto3.resource('dynamodb')
    table = dynamo_resource.Table('bespin_report_ec2')
    for instance in instances['Reservations'][0]['Instances']:
        instance_data = {}
        # Capture defined tags
        instance_data['instance'] = instance['InstanceId']
        for tags in instance['Tags']:
            if tags['Key'] == 'Name':
                instance_data['Name'] = tags['Value']
            if tags['Key'] == 'Poc':
                instance_data['Poc'] = tags['Value']
            if tags['Key'] == 'CostCode':
                instance_data['CostCode'] = tags['Value']
        # Fill in empty values
        required_tags = ['Name', 'Poc', 'CostCode']
        for tag in required_tags:
            if tag not in instance_data.keys():
                instance_data[tag] = 'Missing'
        print(instance_data)
        table.put_item(
            Item = instance_data
        )