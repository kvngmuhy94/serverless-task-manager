import boto3
import json
import logging
import os
from boto3.dynamodb.conditions import Key

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME', 'Tasks')
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

def lambda_handler(event, context):
    """
    AWS Lambda handler to delete a task
    """
    
    # Handle CORS preflight requests
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': ''
        }
    
    logger.info(f"Received event: {json.dumps(event, default=str)}")
    
    try:
        # Extract user ID and task ID
        user_id = get_user_id(event)
        
        # Get task ID from path parameters or body
        task_id = None
        if event.get('pathParameters') and event['pathParameters'].get('taskId'):
            task_id = event['pathParameters']['taskId']
        elif event.get('body'):
            body = event.get('body', '{}')
            if isinstance(body, str):
                body_data = json.loads(body)
            else:
                body_data = body
            task_id = body_data.get('taskId')
        
        if not task_id:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'success': False,
                    'error': 'Missing required field: taskId'
                })
            }
        
        # First, check if task exists and belongs to user
        response = table.get_item(
            Key={
                'userId': user_id,
                'taskId': task_id
            }
        )
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'success': False,
                    'error': 'Task not found'
                })
            }
        
        task_to_delete = response['Item']
        
        # Delete the task
        table.delete_item(
            Key={
                'userId': user_id,
                'taskId': task_id
            }
        )
        
        logger.info(f"Deleted task {task_id} for user {user_id}")
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': json.dumps({
                'success': True,
                'taskId': task_id,
                'deletedTask': {
                    'title': task_to_delete.get('title'),
                    'status': task_to_delete.get('status')
                },
                'message': 'Task deleted successfully'
            })
        }
        
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in request body: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'success': False,
                'error': 'Invalid JSON in request body'
            })
        }
        
    except Exception as e:
        logger.error(f"Error deleting task: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'success': False,
                'error': 'Failed to delete task',
                'message': str(e)
            })
        }

def get_user_id(event):
    """
    Extract user ID from the event context
    """
    # Try to get from Cognito authorizer
    if 'requestContext' in event:
        request_context = event['requestContext']
        if 'authorizer' in request_context:
            authorizer = request_context['authorizer']
            if 'claims' in authorizer and 'sub' in authorizer['claims']:
                return authorizer['claims']['sub']
    
    # Try to get from direct Lambda invocation
    if 'userId' in event:
        return event['userId']
    
    # Try to get from query parameters
    query_params = event.get('queryStringParameters') or {}
    if 'userId' in query_params:
        return query_params['userId']
    
    # Default test user for development
    logger.warning("No user ID found in event, using default test user")
    return "test-user"
