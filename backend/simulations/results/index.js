const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, QueryCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE_NAME;

exports.handler = async (event) => {
    try {
        console.log("Evento recibido:", JSON.stringify(event));

        const headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "OPTIONS,GET"
        };

        const { queryStringParameters } = event;

        if (!queryStringParameters || !queryStringParameters.fintech_id) {
            return {
                statusCode: 400,
                headers,
                body: JSON.stringify({ error: "El parámetro 'fintech_id' es obligatorio" })
            };
        }

        const { fintech_id, cuit, task_id } = queryStringParameters;

        let queryParams = {
            TableName: DYNAMODB_TABLE,
            KeyConditionExpression: "pk = :pk",
            ExpressionAttributeValues: {
                ":pk": `FINTECH#${fintech_id}`
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
        console.error("Error consultando resultados:", error);
        return {
            statusCode: 500,
            headers: { "Access-Control-Allow-Origin": "*" },
            body: JSON.stringify({ error: "Error interno al consultar resultados" })
        };
    }
};
