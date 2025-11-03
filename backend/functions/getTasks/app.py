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
    AWS Lambda handler to retrieve tasks for a user
    """
    
    # Handle CORS preflight requests
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': ''
        }
    
    logger.info(f"Received event: {json.dumps(event, default=str)}")
    
    try:
        # Extract user ID from event
        user_id = get_user_id(event)
        logger.info(f"Retrieving tasks for user: {user_id}")
        
        # Query parameters for filtering and pagination
        query_params = event.get('queryStringParameters') or {}
        status_filter = query_params.get('status')
        limit = int(query_params.get('limit', 100))
        
        # Build DynamoDB query
        query_kwargs = {
            'KeyConditionExpression': Key('userId').eq(user_id),
            'Limit': limit,
            'ScanIndexForward': False  # Latest first
        }
        
        # Add status filter if provided
        if status_filter:
            query_kwargs['FilterExpression'] = Key('status').eq(status_filter)
        
        # Execute query
        response = table.query(**query_kwargs)
        tasks = response.get('Items', [])
        
        logger.info(f"Retrieved {len(tasks)} tasks for user {user_id}")
        
        # Prepare response
        result = {
            'success': True,
            'tasks': tasks,
            'count': len(tasks),
            'userId': user_id,
            'timestamp': datetime.now(timezone.utc).isoformat()
        }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': json.dumps(result, default=str)
        }
        
    except Exception as e:
        logger.error(f"Error retrieving tasks: {str(e)}")
        
        error_response = {
            'success': False,
            'error': 'Failed to retrieve tasks',
            'message': str(e),
            'timestamp': datetime.now(timezone.utc).isoformat()
        }
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(error_response)
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
    return "test-user-123"
