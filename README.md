# taller_ceramica

A new Flutter project.

## Getting Started

Para cambiar el nombre de la app :
""
dart run change_app_package_name:main com.manuelnavarro.tallerdeceramica
""
seleccionar el icono :
""
dart run flutter_launcher_icons 
""

andriod AAB :
""
flutter build appbundle
""

user:
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

despliegue en web:
Remove-Item -Recurse -Force docs
flutter build web
mkdir docs    
cp -r build/web/* docs/
git add .
git commit -m "actualizando pagina webbb" 
git push

git add .
git commit -m "actualizando build Check" 
git push origin main