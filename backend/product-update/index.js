'use strict';

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: 'us-east-1' }));
const TABLE = process.env.DYNAMODB_PRODUCTO_TABLE;

function respond(statusCode, body) {
  return { statusCode, body: JSON.stringify(body) };
}

const REQUIRED_FIELDS = ['nombre', 'monto', 'cuotas', 'interes', 'plazo', 'min_sit_cred', 'max_sit_cred'];

exports.handler = async (event) => {

  const sub = event.requestContext?.authorizer?.jwt?.claims?.sub;
  if (!sub) return respond(401, { error: 'Unauthorized' });

  const producto_id = event.pathParameters?.id;
  if (!producto_id) return respond(400, { error: 'Invalid or missing path parameter: id' });

  let body;
  try { body = JSON.parse(event.body || '{}'); }
  catch { return respond(400, { error: 'Invalid JSON body' }); }

  const missing = REQUIRED_FIELDS.filter(f => body[f] === undefined);
  if (missing.length > 0) return respond(400, { error: `Missing required fields: ${missing.join(', ')}` });

  try {
    const { nombre, monto, cuotas, interes, plazo, min_sit_cred, max_sit_cred } = body;
    const { Attributes } = await ddb.send(new UpdateCommand({
      TableName: TABLE,
      Key: { sub, producto_id },
      UpdateExpression: 'SET nombre = :n, monto = :m, cuotas = :c, interes = :i, plazo = :p, min_sit_cred = :min, max_sit_cred = :max',
      ConditionExpression: 'attribute_exists(#sub)',
      ExpressionAttributeNames: { '#sub': 'sub' },
      ExpressionAttributeValues: {
        ':n': nombre, ':m': monto, ':c': cuotas, ':i': interes,
        ':p': plazo, ':min': min_sit_cred, ':max': max_sit_cred,
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
