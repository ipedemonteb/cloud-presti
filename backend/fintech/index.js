'use strict';

const { randomUUID } = require('crypto');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: 'us-east-1' }));
const TABLE = process.env.DYNAMODB_FINTECH_TABLE;

const HEADERS = {
  'Content-Type':                 'application/json',
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};

function respond(statusCode, body) {
  return { statusCode, headers: HEADERS, body: JSON.stringify(body) };
}

exports.handler = async (event) => {
  // Cognito Post Confirmation trigger
  if (event.triggerSource === 'PostConfirmation_ConfirmSignUp') {
    const sub = event.request.userAttributes.sub;
    await ddb.send(new PutCommand({ TableName: TABLE, Item: { sub } }));
    return event;
  }

  // API Gateway
  try {
    const method = event.requestContext?.http?.method;
    const path   = event.requestContext?.http?.path;

    if (method === 'OPTIONS') {
      return { statusCode: 200, headers: HEADERS, body: '' };
    }

    const sub = event.requestContext?.authorizer?.jwt?.claims?.sub;
    if (!sub) return respond(401, { error: 'Unauthorized' });

    if (method === 'GET' && path === '/fintech') {
      const { Item } = await ddb.send(new GetCommand({
        TableName: TABLE,
        Key: { sub },
      }));
      if (!Item) return respond(404, { error: 'Fintech not found' });
      return respond(200, Item);
    }

    return respond(404, { error: 'Route not found' });

  } catch (err) {
    console.error('Internal error:', err);
    return respond(500, { error: 'Internal server error', message: err.message });
  }
};
