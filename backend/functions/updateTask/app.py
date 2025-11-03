import boto3
import json
import logging
import os
from datetime import datetime, timezone
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
    AWS Lambda handler to update an existing task
    """
    
    # Handle CORS preflight requests
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'PUT, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': ''
        }
    
    logger.info(f"Received event: {json.dumps(event, default=str)}")
    
    try:
        # Parse request body
        body = event.get('body', '{}')
        if isinstance(body, str):
            update_data = json.loads(body)
        else:
            update_data = body
        
        # Extract user ID and task ID
        user_id = get_user_id(event)
        task_id = update_data.get('taskId') or event.get('pathParameters', {}).get('taskId')
        
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
        
        existing_task = response['Item']
        
        # Build update expression
        update_expression = "SET updatedAt = :updated_at"
        expression_values = {
            ':updated_at': datetime.now(timezone.utc).isoformat()
        }
        
        # Update fields if provided
        if 'title' in update_data:
            update_expression += ", title = :title"
            expression_values[':title'] = update_data['title']
        
        if 'description' in update_data:
            update_expression += ", description = :description"
            expression_values[':description'] = update_data['description']
        
        if 'status' in update_data:
            update_expression += ", #status = :status"
            expression_values[':status'] = update_data['status']
        
        # Use ExpressionAttributeNames for status (reserved keyword)
        expression_names = {'#status': 'status'} if 'status' in update_data else None
        
        # Perform update
        update_kwargs = {
            'Key': {
                'userId': user_id,
                'taskId': task_id
            },
            'UpdateExpression': update_expression,
            'ExpressionAttributeValues': expression_values,
            'ReturnValues': 'ALL_NEW'
        }
        
        if expression_names:
            update_kwargs['ExpressionAttributeNames'] = expression_names
        
        response = table.update_item(**update_kwargs)
        updated_task = response['Attributes']
        
        logger.info(f"Updated task {task_id} for user {user_id}")
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'PUT, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': json.dumps({
                'success': True,
                'task': updated_task,
                'message': 'Task updated successfully'
            }, default=str)
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
        logger.error(f"Error updating task: {str(e)}")
        
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'success': False,
                'error': 'Failed to update task',
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
