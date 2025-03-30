from PIL import Image, ImageOps

# Ruta de la imagen original
input_image_path = "C:/Users/Manuel/Desktop/Folder/taller_ceramica/assets/icon/image.png"
output_image_path = "icon_with_background_512x512.png"

# Abrir la imagen
input_image = Image.open(input_image_path)

# Crear un nuevo fondo más grande (512x512) con el mismo color de fondo
background_color = input_image.getpixel((0, 0))  # Asume que el color predominante está en el borde
new_image = Image.new("RGB", (512, 512), background_color)

# Redimensionar la imagen original para que sea más pequeña en relación al nuevo fondo
# scale_factor = 0.4  # Reduce el tamaño al 70%
# new_width = int(input_image.width * scale_factor)
# new_height = int(input_image.height * scale_factor)
# resized_image = input_image.resize((new_width, new_height), Image.LANCZOS)

# Pegar la imagen redimensionada en el centro del nuevo fondo
# paste_position = ((512 - new_width) // 2, (512 - new_height) // 2)
# new_image.paste(resized_image, paste_position)

# Guardar la nueva imagen con fondo ampliado
new_image.save(output_image_path, "PNG")
