'use strict';

const { randomUUID } = require('crypto');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: 'us-east-1' }));
const TABLE = process.env.DYNAMODB_PRODUCTO_TABLE;

const HEADERS = {
  'Content-Type':                 'application/json',
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};

function respond(statusCode, body) {
  return { statusCode, headers: HEADERS, body: JSON.stringify(body) };
}

const REQUIRED_FIELDS = ['nombre', 'monto', 'cuotas', 'interes', 'plazo', 'min_sit_cred', 'max_sit_cred'];

exports.handler = async (event) => {
  if (event.requestContext?.http?.method === 'OPTIONS') {
    return { statusCode: 200, headers: HEADERS, body: '' };
  }

  const sub = event.requestContext?.authorizer?.jwt?.claims?.sub;
  if (!sub) return respond(401, { error: 'Unauthorized' });

  let body;
  try { body = JSON.parse(event.body || '{}'); }
  catch { return respond(400, { error: 'Invalid JSON body' }); }

  const missing = REQUIRED_FIELDS.filter(f => body[f] === undefined);
  if (missing.length > 0) return respond(400, { error: `Missing required fields: ${missing.join(', ')}` });

  try {
    const { nombre, monto, cuotas, interes, plazo, min_sit_cred, max_sit_cred } = body;
    const producto_id = randomUUID();
    const item = { sub, producto_id, nombre, monto, cuotas, interes, plazo, min_sit_cred, max_sit_cred };

    await ddb.send(new PutCommand({ TableName: TABLE, Item: item }));
    return respond(201, item);
  } catch (err) {
    console.error('Internal error:', err);
    return respond(500, { error: 'Internal server error', message: err.message });
  }
};
