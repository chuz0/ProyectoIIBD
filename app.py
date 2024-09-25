import pyodbc
from flask import Flask, render_template, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
1
# Configuración de la conexión a la base de datos
def get_db_connection():
    connection = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        #'SERVER=DESKTOP-HUTR52P;'
        'SERVER=ERICKPC;'
        'DATABASE=proyecto2;'
        'UID=hola;' 
        'PWD=12345678'
    )
    return connection

@app.route('/')
def index():
    return render_template('index.html')






if __name__ == '__main__':
    app.run(debug=True)