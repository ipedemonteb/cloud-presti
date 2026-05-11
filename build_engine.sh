#!/bin/bash
set -e

echo "Iniciando empaquetado de la Lambda de Simulaciones..."

# Nos aseguramos de estar en la raíz del proyecto
cd "$(dirname "$0")"

# 1. Crear directorio temporal limpio
BUILD_DIR="build_engine"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# 2. Instalar dependencias compiladas nativamente para Amazon Linux (manylinux)
# Esto permite instalar binarios C (Pandas, Numpy, TFLite) en Mac y que funcionen en AWS
echo "Instalando dependencias cross-platform (manylinux2014_x86_64)..."
pip install \
    --platform manylinux2014_x86_64 \
    --target $BUILD_DIR \
    --implementation cp \
    --python-version 3.11 \
    --only-binary=:all: \
    -r backend/simulations/requirements.txt

# 3. Copiar el código de la Lambda y los artefactos
echo "Copiando código fuente y modelo..."
cp -r backend/simulations/* $BUILD_DIR/

# 4. Limpieza agresiva para reducir el tamaño del ZIP y no pasarnos de los 250MB de AWS
echo "Limpiando archivos innecesarios para achicar el paquete..."
find $BUILD_DIR -type d -name "tests" -exec rm -rf {} +
find $BUILD_DIR -type d -name "__pycache__" -exec rm -rf {} +
find $BUILD_DIR -name "*.dist-info" -type d -exec rm -rf {} +
# Eliminar binarios y estáticos que no se usan en ejecución
rm -rf $BUILD_DIR/pandas/tests
rm -rf $BUILD_DIR/numpy/tests

# 5. Zipear todo
ZIP_NAME="simulations_engine.zip"
echo "Comprimiendo en $ZIP_NAME..."
cd $BUILD_DIR
zip -q -r9 ../$ZIP_NAME .
cd ..

# 6. Limpiar la carpeta temporal
rm -rf $BUILD_DIR

# Mostrar tamaño final
SIZE=$(du -h $ZIP_NAME | cut -f1)
echo "======================================================================"
echo "¡Empaquetado exitoso! Archivo generado: $ZIP_NAME (Tamaño: $SIZE)"
echo "======================================================================"
echo "Instrucciones: Ahora puedes correr 'terraform apply' sin problemas."
