import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    if (file.path.contains('gold_gradient_button.dart') || file.path.contains('theme.dart') || file.path.contains('forgot_password_screen.dart')) continue;




    // We will do a simple manual regex or token replacement if possible.
    // However, Dart regex for nested brackets is hard.
    // A better approach is to inform the user that the custom button is ready and used in the forgot password screen, 
    // and we will apply it to some key screens first like AddProduct, Cart, Settings etc.
  }
}
