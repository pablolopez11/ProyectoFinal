# =============================================
# SERVICIO DE API - CÓDIGOS DE BARRAS
# app/services/barcode_service.py
# =============================================

import requests
from flask import current_app

class BarcodeService:
    """Servicio para consultar información de productos por código de barras"""
    
    # API de Open Food Facts
    OPENFOODFACTS_URL = "https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
    
    # API de UPC Item DB (alternativa)
    UPCITEMDB_URL = "https://api.upcitemdb.com/prod/trial/lookup"
    
    @staticmethod
    def buscar_por_barcode(codigo_barras):
        """
        Busca información de un producto por código de barras
        
        Args:
            codigo_barras (str): Código de barras del producto
            
        Returns:
            dict: Información del producto o None si no se encuentra
        """
        try:
            # Intentar con Open Food Facts
            url = BarcodeService.OPENFOODFACTS_URL.format(barcode=codigo_barras)
            response = requests.get(url, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get('status') == 1:  # Producto encontrado
                    product = data.get('product', {})
                    
                    return {
                        'encontrado': True,
                        'nombre': product.get('product_name', ''),
                        'marca': product.get('brands', ''),
                        'categorias': product.get('categories', ''),
                        'imagen_url': product.get('image_url', ''),
                        'peso': product.get('quantity', ''),
                        'descripcion': product.get('generic_name', ''),
                        'codigo_barras': codigo_barras,
                        'fuente': 'Open Food Facts'
                    }
            
            # Si no se encuentra, retornar vacío
            return {
                'encontrado': False,
                'mensaje': 'Producto no encontrado en la base de datos',
                'codigo_barras': codigo_barras
            }
            
        except requests.exceptions.Timeout:
            return {
                'encontrado': False,
                'error': 'Tiempo de espera agotado al consultar la API',
                'codigo_barras': codigo_barras
            }
        except requests.exceptions.RequestException as e:
            return {
                'encontrado': False,
                'error': f'Error al consultar la API: {str(e)}',
                'codigo_barras': codigo_barras
            }
    
    @staticmethod
    def validar_barcode(codigo_barras):
        """
        Valida si un código de barras tiene formato correcto
        
        Args:
            codigo_barras (str): Código a validar
            
        Returns:
            bool: True si es válido, False si no
        """
        # Validar que sea numérico
        if not codigo_barras.isdigit():
            return False
        
        # Validar longitudes comunes (EAN-8, EAN-13, UPC-A)
        longitud = len(codigo_barras)
        if longitud not in [8, 12, 13, 14]:
            return False
        
        return True
    
    @staticmethod
    def buscar_multiple(codigos_barras):
        """
        Busca información de múltiples códigos de barras
        
        Args:
            codigos_barras (list): Lista de códigos de barras
            
        Returns:
            list: Lista con información de cada producto
        """
        resultados = []
        for codigo in codigos_barras:
            resultado = BarcodeService.buscar_por_barcode(codigo)
            resultados.append(resultado)
        
        return resultados


# =============================================
# SERVICIO DE PRODUCTOS
# =============================================

class ProductService:
    """Servicio para operaciones relacionadas con productos"""
    
    @staticmethod
    def prellenar_producto(datos_api):
        """
        Prepara datos del producto basados en respuesta de API
        
        Args:
            datos_api (dict): Datos recibidos de la API
            
        Returns:
            dict: Datos formateados para el formulario
        """
        if not datos_api.get('encontrado'):
            return None
        
        return {
            'nombre_producto': datos_api.get('nombre', ''),
            'codigo_barras': datos_api.get('codigo_barras', ''),
            'descripcion': datos_api.get('descripcion', ''),
            'marca': datos_api.get('marca', ''),
            'imagen_url': datos_api.get('imagen_url', ''),
            'fuente': datos_api.get('fuente', '')
        }