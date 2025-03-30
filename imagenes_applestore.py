from PIL import Image

# Reinitialize paths due to session reset
input_paths = [
    "C:\\Users\\Manuel\\Desktop\\Folder\\taller_ceramica\\assets\\images\\WhatsApp Video 2025-02-02 at 4.12.38 PM.mp4",
   
]


# Resize dimensions (width, height)
resize_dimensions = (1320, 2868)

# Resizing and saving
output_paths = []
for i, input_path in enumerate(input_paths):
    with Image.open(input_path) as img:
        resized_img = img.resize(resize_dimensions)
        output_path = f"C:/Users/Manuel/Desktop/Folder/taller_ceramica/resized_image_{i + 1}.jpeg"
        resized_img.save(output_path)
        output_paths.append(output_path)

output_paths
