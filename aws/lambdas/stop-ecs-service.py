import boto3

def lambda_handler(event, context):
    # Set the name of the ECS cluster
    cluster_name = "cruddur"

    # Create an ECS client
    ecs = boto3.client('ecs')

    # Get a list of all services in the cluster
    services = ecs.list_services(cluster=cluster_name)

    # Loop through the services and update their desired count to 0
    for service_arn in services['serviceArns']:
        service_name = service_arn.split("/")[-1]
        ecs.update_service(cluster=cluster_name, service=service_name, desiredCount=0)
    
    return "All services stopped in ECS cluster: " + cluster_name