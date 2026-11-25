# NextGen Motors móvil

Cliente Flutter del concesionario. Los clientes consultan citas y conversan con Dante. El personal accede al embudo y a los informes.

## Sesión y uso sin conexión

El login valida las credenciales con el backend y guarda una sesión de ocho horas en el almacén seguro del dispositivo. Al reabrir la app se comprueba el perfil con el servidor. Si falla la conexión, se puede consultar la caché de la cuenta mientras la credencial local esté vigente. Una respuesta 401 o 403 obliga a volver a entrar. Una instalación anterior que solo guardó el identificador del usuario también requiere un nuevo login.

El cierre borra la credencial del dispositivo y solicita su revocación en el servidor. Si el dispositivo está sin red, la credencial remota caduca en su plazo original. Las notificaciones son opcionales. Las citas guardadas muestran un aviso de modo sin conexión y la fecha de su última actualización.

## Terminal de Android

Desde PowerShell en esta carpeta, ejecuta `.\ejecutar-android.cmd`. Si tienes varios dispositivos, usa `.\ejecutar-android.cmd -d ID` con el identificador que muestra `flutter devices`. El lanzador filtra mensajes rutinarios del emulador, el teclado y las superficies de Android. Mantiene los avisos, los errores y la salida de Flutter. Para consultar la salida completa, usa `flutter run`.

En modo debug, busca `[Notificaciones]` para ver el resultado del registro del teléfono y la recepción de mensajes en primer plano.

## Verificación local

Con el SDK Flutter del proyecto y las dependencias ya instaladas, ejecuta `flutter analyze --no-pub` y `flutter test --no-pub`. Las pruebas usan almacenamiento simulado y respuestas HTTP locales.
