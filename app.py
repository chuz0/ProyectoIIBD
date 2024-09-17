import pyodbc
from flask import Flask, render_template, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Configuración de la conexión a la base de datos
def get_db_connection():
    connection = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=DESKTOP-HUTR52P;'
        'DATABASE=proyecto2;'
        'UID=hola;'
        'PWD=12345678'
    )
    return connection

@app.route('/')
def index():
    return render_template('index.html')
