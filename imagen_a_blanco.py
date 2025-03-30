from PIL import Image

def cambiar_fondo_a_blanco(imagen_entrada, imagen_salida):
    # Abrir la imagen
    imagen = Image.open(imagen_entrada).convert("RGBA")
    
    # Crear una nueva imagen con fondo blanco
    fondo_blanco = Image.new("RGBA", imagen.size, (255, 255, 255, 255))
    
    # Pegar la imagen sobre el fondo blanco (reemplaza transparencia por blanco)
    fondo_blanco.paste(imagen, (0, 0), mask=imagen)
    
    # Convertir a modo RGB para guardar sin canal alfa
    imagen_final = fondo_blanco.convert("RGB")
    
    # Guardar la imagen con el fondo blanco
    imagen_final.save(imagen_salida)
    print(f"Imagen guardada con fondo blanco en: {imagen_salida}")

# Ruta de entrada y salida
imagen_entrada = "C:/Users/Manuel/Desktop/Folder/taller_ceramica/assets/icon/image.png"
imagen_salida = "C:/Users/Manuel/Desktop/Folder/taller_ceramica/image_con_fondo_blanco.jpg"

# Ejecutar la función
cambiar_fondo_a_blanco(imagen_entrada, imagen_salida)
