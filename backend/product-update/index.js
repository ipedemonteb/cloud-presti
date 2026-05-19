'use strict';

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: 'us-east-1' }));
const TABLE = process.env.DYNAMODB_PRODUCT_TABLE;

function respond(statusCode, body) {
  return { statusCode, body: JSON.stringify(body) };
}

const REQUIRED_FIELDS = ['name', 'amount', 'installments', 'interest', 'min_score', 'max_score', 'priority'];

exports.handler = async (event) => {

  const sub = event.requestContext?.authorizer?.jwt?.claims?.sub;
  if (!sub) return respond(401, { error: 'Unauthorized' });

  const product_id = event.pathParameters?.id;
  if (!product_id) return respond(400, { error: 'Invalid or missing path parameter: id' });

  let body;
  try { body = JSON.parse(event.body || '{}'); }
  catch { return respond(400, { error: 'Invalid JSON body' }); }

  const missing = REQUIRED_FIELDS.filter(f => body[f] === undefined);
  if (missing.length > 0) return respond(400, { error: `Missing required fields: ${missing.join(', ')}` });

  try {
    const { name, amount, installments, interest, min_score, max_score, priority } = body;

    if (min_score > max_score) {
      return respond(400, { error: 'min_score cannot be greater than max_score' });
    }

    if (!Number.isInteger(priority) || priority < 1 || priority > 10) {
      return respond(400, { error: 'priority must be an integer between 1 and 10' });
    }

    const term = body.term !== undefined ? body.term : installments;
    const { Attributes } = await ddb.send(new UpdateCommand({
      TableName: TABLE,
      Key: { sub, product_id },
      UpdateExpression: 'SET #name = :n, amount = :m, installments = :c, interest = :i, term = :p, min_score = :min, max_score = :max, priority = :pri',
      ConditionExpression: 'attribute_exists(#sub)',
      ExpressionAttributeNames: { '#sub': 'sub', '#name': 'name' },
      ExpressionAttributeValues: {
        ':n': name, ':m': amount, ':c': installments, ':i': interest,
        ':p': term, ':min': min_score, ':max': max_score, ':pri': priority,
      },
      ReturnValues: 'ALL_NEW',
    }));
    return respond(200, Attributes);
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      return respond(404, { error: 'Product not found' });
    }
    console.error('Internal error:', err);
    return respond(500, { error: 'Internal server error', message: err.message });
  }
};
