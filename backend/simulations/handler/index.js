const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');
const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { v4: uuidv4 } = require('uuid');

const sqsClient = new SQSClient({});
const dynamoClient = new DynamoDBClient({});

const QUEUE_URL = process.env.SQS_QUEUE_URL;
const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE_NAME;

exports.handler = async (event) => {
    try {
        console.log("Evento recibido:", JSON.stringify(event));

        // En API Gateway v2, el método está en requestContext.http.method
        const httpMethod = event.requestContext?.http?.method || event.httpMethod;
        const body = event.body;

        const headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "OPTIONS,POST"
        };

        if (httpMethod === 'OPTIONS') {
            return { statusCode: 200, headers, body: '' };
        }

        if (httpMethod === 'POST') {
            if (!body) {
                return { statusCode: 400, headers, body: JSON.stringify({ error: "Body is missing" }) };
            }

            let parsedBody;
            try {
                parsedBody = JSON.parse(body);
            } catch (parseError) {
                return { statusCode: 400, headers, body: JSON.stringify({ error: "Invalid JSON in request body" }) };
            }
            const cuit = parsedBody.cuit;
            const fintechId = parsedBody.fintech_id;

            if (!cuit || !fintechId) {
                return { 
                    statusCode: 400, 
                    headers, 
                    body: JSON.stringify({ error: "Missing 'cuit' or 'fintech_id' in request body" }) 
                };
            }

            const taskId = uuidv4();
            const timestamp = new Date().toISOString();

            if (DYNAMODB_TABLE) {
                try {
                    await dynamoClient.send(new PutItemCommand({
                        TableName: DYNAMODB_TABLE,
                        Item: {
                            pk: { S: `FINTECH#${fintechId}` },
                            sk: { S: `CUIT#${cuit}#TASK#${taskId}` },
                            
                            task_id: { S: taskId },
                            fintech_id: { S: fintechId },
                            cuit: { S: cuit },
                            status: { S: "PROCESSING" },
                            created_at: { S: timestamp }
                        }
                    }));
                    console.log(`Registro creado en DynamoDB para task_id: ${taskId}`);
                } catch (dbError) {
                    console.error("Error guardando en DynamoDB:", dbError);
                    return { statusCode: 500, headers, body: JSON.stringify({ error: "Error interno al inicializar simulación" }) };
                }
            } else {
                console.warn("DYNAMODB_TABLE_NAME no está definida.");
            }

            if (QUEUE_URL) {
                await sqsClient.send(new SendMessageCommand({
                    QueueUrl: QUEUE_URL,
                    MessageBody: JSON.stringify({
                        task_id: taskId,
                        cuit: cuit,
                        fintech_id: fintechId,
                        timestamp: timestamp
                    })
                }));
                console.log(`Mensaje enviado a SQS para task_id: ${taskId}`);
            } else {
                console.warn("SQS_QUEUE_URL no está definida en las variables de entorno.");
                return { statusCode: 500, headers, body: JSON.stringify({ error: "Configuración interna del servidor incompleta (SQS)" }) };
            }

            return {
                statusCode: 202,
                headers,
                body: JSON.stringify({
                    message: "Simulación iniciada",
                    task_id: taskId,
                    status: "PROCESSING"
                })
            };
        }

        return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: "Ruta no encontrada o método no permitido" })
        };

    } catch (error) {
        console.error("Error en la API:", error);
        return {
            statusCode: 500,
            headers: { "Access-Control-Allow-Origin": "*" },
            body: JSON.stringify({ 
                error: "Error interno del servidor",
                message: error.message,
                stack: error.stack
            })
        };
    }
};
