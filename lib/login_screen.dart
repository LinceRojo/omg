// login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'registration_screen.dart';
import 'qr_generator_screen.dart';
import 'mobile_scanner_screen.dart';
import 'user_verification_screen.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

// Función para registrar un nuevo usuario con email y contraseña
Future<UserCredential?> registerWithEmailPassword(String email, String password) async {
  try {
    final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  } on FirebaseAuthException catch (e) {
    print("Error al registrar usuario: $e");
    // Manejar los diferentes tipos de errores de Firebase Auth
    String errorMessage = "Error al registrar usuario.";
    if (e.code == 'weak-password') {
      errorMessage = 'La contraseña es demasiado débil.';
    } else if (e.code == 'email-already-in-use') {
      errorMessage = 'Ya existe una cuenta con este correo electrónico.';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'El correo electrónico no es válido.';
    }
    // Puedes mostrar este errorMessage al usuario a través de un SnackBar o AlertDialog
    return null;
  } catch (e) {
    print("Error desconocido al registrar usuario: $e");
    return null;
  }
}

// Función para iniciar sesión con email y contraseña
Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
  try {
    final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  } on FirebaseAuthException catch (e) {
    print("Error al iniciar sesión: $e");
    String errorMessage = "Error al iniciar sesión.";
    if (e.code == 'user-not-found') {
      errorMessage = 'No se encontró ningún usuario con ese correo electrónico.';
    } else if (e.code == 'wrong-password') {
      errorMessage = 'La contraseña es incorrecta.';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'El correo electrónico no es válido.';
    } else if (e.code == 'user-disabled') {
      errorMessage = 'Esta cuenta de usuario ha sido deshabilitada.';
    }
    // Puedes mostrar este errorMessage al usuario
    return null;
  } catch (e) {
    print("Error desconocido al iniciar sesión: $e");
    return null;
  }
}

Future<UserCredential?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null; // El usuario canceló el inicio de sesión
    }
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  } catch (e) {
    print("Error al iniciar sesión con Google: $e");
    return null;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim());
        if (userCredential.user != null) {
          print("Usuario autenticado con email y contraseña: ${userCredential.user!.uid}");
          // Navega a la siguiente pantalla
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserVerificationScreen(uid:userCredential.user?.uid)), // Reemplaza HomeScreen() con tu pantalla principal
          );
        }
      } on FirebaseAuthException catch (e) {
        print("Error al iniciar sesión con email y contraseña: ${e.message}");
        String errorMessage = 'Error al iniciar sesión.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No se encontró ningún usuario con ese correo electrónico.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'La contraseña proporcionada es incorrecta.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRegisterScreen() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => RegistrationScreen()),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Iniciar Sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Bienvenido a mi App',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduce tu correo electrónico.';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, introduce un correo electrónico válido.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, introduce tu contraseña.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Iniciar sesión'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    // Asegúrate de que signInWithGoogle esté implementado en algún lugar de tu código
                    UserCredential? userCredential = await signInWithGoogle();
                    if (userCredential?.user != null) {
                      print("Usuario autenticado con Google: ${userCredential!.user!.displayName}");
                      // Navega a la siguiente pantalla
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserVerificationScreen(uid:userCredential.user?.uid),
                          ),
                      );
                    } else {
                      print("Inicio de sesión con Google fallido.");
                      // Muestra un mensaje de error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al iniciar sesión con Google.')),
                      );
                    }
                  },
                  child: Text('Iniciar sesión con Google'),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: _navigateToRegisterScreen,
                  child: Text('¿No tienes una cuenta? Regístrate aquí'),
                ),
                // Otros métodos de inicio de sesión (si los tienes)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pantalla Principal'),
      ),
      body: Center(
        child: Text('¡Has iniciado sesión!'),
      ),
    );
  }
}