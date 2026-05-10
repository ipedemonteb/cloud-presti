FROM public.ecr.aws/lambda/python:3.11

COPY backend/simulations/requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt

COPY engine/artifacts/ ${LAMBDA_TASK_ROOT}/artifacts/
COPY engine/src/ ${LAMBDA_TASK_ROOT}/src/

COPY backend/simulations/lambda_function.py ${LAMBDA_TASK_ROOT}

CMD [ "lambda_function.lambda_handler" ]
