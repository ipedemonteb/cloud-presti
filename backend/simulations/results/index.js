const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, QueryCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE_NAME;

exports.handler = async (event) => {
    try {
        console.log("Event received:", JSON.stringify(event));

        const headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "OPTIONS,GET"
        };

        const sub = event.requestContext?.authorizer?.jwt?.claims?.sub;
        if (!sub) {
            return { statusCode: 401, headers, body: JSON.stringify({ error: "No se pudo obtener el sub del token" }) };
        }

        const { queryStringParameters } = event;
        const { cuit, task_id } = queryStringParameters || {};

        let queryParams = {
            TableName: DYNAMODB_TABLE,
            KeyConditionExpression: "#sub = :sub",
            ExpressionAttributeNames: { "#sub": "sub" },
            ExpressionAttributeValues: {
                ":sub": sub
            }
        };

        if (cuit && !task_id) {
            queryParams.KeyConditionExpression += " AND begins_with(sk, :sk_prefix)";
            queryParams.ExpressionAttributeValues[":sk_prefix"] = `CUIT#${cuit}`;
        } 
        else if (task_id) {
            queryParams.FilterExpression = "task_id = :tid";
            queryParams.ExpressionAttributeValues[":tid"] = task_id;
        }

        const data = await docClient.send(new QueryCommand(queryParams));

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                results: data.Items
            })
        };

    } catch (error) {
        console.error("Error querying results:", error);
        return {
            statusCode: 500,
            headers: { "Access-Control-Allow-Origin": "*" },
            body: JSON.stringify({ error: "Error interno al consultar resultados" })
        };
    }
};
