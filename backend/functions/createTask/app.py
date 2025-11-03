import boto3
import json
import logging
import os
import uuid
from datetime import datetime, timezone

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
    AWS Lambda handler to create a new task
    """
    
    # Handle CORS preflight requests
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': ''
        }
    
    logger.info(f"Received event: {json.dumps(event, default=str)}")
    
    try:
        # Parse request body
        body = event.get('body', '{}')
        if isinstance(body, str):
            task_data = json.loads(body)
        else:
            task_data = body
        
        # Extract user ID
        user_id = get_user_id(event)
        
        # Validate required fields
        title = task_data.get('title')
        if not title:
            return {
                'statusCode': 400,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'success': False,
                    'error': 'Missing required field: title'
                })
            }
        
        # Generate task ID and timestamp
        task_id = str(uuid.uuid4())
        created_at = datetime.now(timezone.utc).isoformat()
        
        # Create task item
        task_item = {
            'userId': user_id,
            'taskId': task_id,
            'title': title,
            'description': task_data.get('description', ''),
            'status': task_data.get('status', 'pending'),
            'createdAt': created_at,
            'updatedAt': created_at
        }
        
        # Save to DynamoDB
        table.put_item(Item=task_item)
        logger.info(f"Created task {task_id} for user {user_id}")
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': json.dumps({
                'success': True,
                'taskId': task_id,
                'title': title,
                'description': task_item['description'],
                'status': task_item['status'],
                'userId': user_id,
                'createdAt': created_at,
                'message': 'Task created successfully'
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
        logger.error(f"Error creating task: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'success': False,
                'error': 'Failed to create task',
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
