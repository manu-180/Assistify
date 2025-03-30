from moviepy import VideoFileClip

# Ruta al video original
input_video_path = r"C:\\Users\\Manuel\\Desktop\\Folder\\taller_ceramica\\ssets\\images\\WhatsApp Video 2025-02-02 at 4.12.38 PM.mp4"
output_video_path = r"C:\\Users\\Manuel\\Desktop\\Folder\\taller_ceramica\\assets\\videos\\resized_video.mp4"

# Nuevas dimensiones
new_width = 886
new_height = 1920

# Cargar el video
clip = VideoFileClip(input_video_path)

# Redimensionar el video
resized_clip = clip.resize(newsize=(new_width, new_height))

# Guardar el video redimensionado
resized_clip.write_videofile(output_video_path, codec="libx264", audio_codec="aac")
