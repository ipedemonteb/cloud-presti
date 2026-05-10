import json
import os
import boto3
import urllib.request
import urllib.error
from decimal import Decimal
from pathlib import Path

import pandas as pd
import numpy as np
import joblib
import tflite_runtime.interpreter as tflite

from src.preprocessing.load_data import features_desde_api
from src.model.predict import (
    FEATURE_COLUMNS, 
    _read_feature_columns, 
    _read_fill_values, 
    _build_features
)

dynamodb = boto3.resource('dynamodb', region_name=os.getenv('AWS_REGION', 'us-east-1'))
TABLE_NAME = os.getenv('DYNAMODB_TABLE_NAME', 'Simulations')

_INTERPRETER = None
_SCALER = None
_FEATURE_COLUMNS = None
_FILL_VALUES = None

def cargar_artefactos():
    global _INTERPRETER, _SCALER, _FEATURE_COLUMNS, _FILL_VALUES
    if _INTERPRETER is not None:
        return
        
    print("Cargando artefactos en memoria (Cold Start)...")
    artifacts_dir = Path(__file__).resolve().parent / "artifacts"
    
    _SCALER = joblib.load(artifacts_dir / "scaler.joblib")
    _INTERPRETER = tflite.Interpreter(model_path=str(artifacts_dir / "modelo_crediticio.tflite"))
    _INTERPRETER.allocate_tensors()
    _FEATURE_COLUMNS = _read_feature_columns(artifacts_dir / "feature_columns.json")
    _FILL_VALUES = _read_fill_values(artifacts_dir / "feature_fill_values.json")
    print("Artefactos cargados.")

def consultar_bcra(cuit: str) -> dict:
    url = f"https://api.bcra.gob.ar/centraldedeudores/v1/Deudas/Historicas/{cuit}"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            return data.get('results', {})
    except urllib.error.HTTPError as e:
        raise Exception(f"Error consultando BCRA: HTTP {e.code}")
    except Exception as e:
        raise Exception(f"Error de conexión con BCRA: {str(e)}")

def predecir_score(features_dict: dict) -> float:
    cargar_artefactos()
    
    if 'nro_id' not in features_dict:
        features_dict['nro_id'] = "temp_id"
        
    df = pd.DataFrame([features_dict], columns=["nro_id"] + FEATURE_COLUMNS)
    
    X, _ = _build_features(df)
    X = X.reindex(columns=_FEATURE_COLUMNS, fill_value=0)
    X = X.replace([np.inf, -np.inf], np.nan)
    
    if _FILL_VALUES:
        X = X.fillna(pd.Series(_FILL_VALUES))
    X = X.fillna(0.0)
    
    X_scaled = _SCALER.transform(X)
    
    input_details = _INTERPRETER.get_input_details()
    output_details = _INTERPRETER.get_output_details()
    
    _INTERPRETER.set_tensor(input_details[0]['index'], X_scaled.astype(np.float32))
    _INTERPRETER.invoke()
    preds = _INTERPRETER.get_tensor(output_details[0]['index']).reshape(-1)
    
    return float(preds[0])

def actualizar_estado(task_id: str, status: str, score: float = None, error: str = None):
    table = dynamodb.Table(TABLE_NAME)
    update_expr = "SET #st = :status"
    expr_attrs = {"#st": "status"}
    expr_vals = {":status": status}
    
    if score is not None:
        update_expr += ", score = :score"
        expr_vals[":score"] = Decimal(str(score))
        
    if error is not None:
        update_expr += ", error_msg = :error"
        expr_vals[":error"] = error
        
    table.update_item(
        Key={'task_id': task_id},
        UpdateExpression=update_expr,
        ExpressionAttributeNames=expr_attrs,
        ExpressionAttributeValues=expr_vals
    )

def lambda_handler(event, context):
    for record in event.get('Records', []):
        try:
            body = json.loads(record['body'])
            task_id = body.get('task_id')
            cuit = body.get('cuit')
            
            if not task_id or not cuit:
                print("Mensaje inválido, ignorando.")
                continue
                
            print(f"Procesando Task: {task_id} - CUIT: {cuit}")
            
            bcra_data = consultar_bcra(cuit)
            
            features = features_desde_api(bcra_data)
            if features is None:
                raise ValueError("No hay suficientes periodos en BCRA (min 7).")
                
            score = predecir_score(features)
            print(f"Score calculado: {score}")
            
            actualizar_estado(task_id, "COMPLETED", score=score)
            
        except Exception as e:
            print(f"Error procesando {task_id}: {str(e)}")
            if 'task_id' in locals() and task_id:
                actualizar_estado(task_id, "FAILED", error=str(e))
            raise e
            
    return {"statusCode": 200, "body": "OK"}
