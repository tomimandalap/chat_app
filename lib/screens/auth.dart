import 'dart:io';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chat_app/widgets/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  final _form = GlobalKey<FormState>();

  String _formEmail = '';
  String _formUsername = '';
  String _formPassword = '';
  File? _selectedImage;

  void onPressTextButton() {
    setState(() {
      _isLogin = !_isLogin;
      _form.currentState!.reset();
    });
  }

  void onSubmit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || !_isLogin && _selectedImage == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please added image'),
        ),
      );

      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isLoading = true;
      });

      if (_isLogin) {
        await _firebase.signInWithEmailAndPassword(
            email: _formEmail, password: _formPassword);
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
          email: _formEmail,
          password: _formPassword,
        );

        // Uploading image on firebase storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredential.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);

        // get image url
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _formUsername,
          'email': _formEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-alredy-in-use') {
        // ...
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed'),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  // METHOD VALIDATION
  String? onValidationEmail(String value) {
    if (value.trim().isEmpty || !value.contains('@')) {
      return 'Please enter a valid email';
    } else {
      return null;
    }
  }

  String? onValidationUsername(String value) {
    if (value.trim().isEmpty || value.trim().length < 4) {
      return 'Please enter at least 4 characters';
    } else {
      return null;
    }
  }

  String? onValidationPassword(String value) {
    if (value.trim().isEmpty || value.trim().length < 6) {
      return 'Password must be at least 6 character';
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget textButtonContent = const Text('Create an account');
    Widget elevatedButtonContent = const Text('Login');

    if (!_isLogin) {
      textButtonContent = const Text('I already have an account.');
      elevatedButtonContent = const Text('Singup');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(
                              onPickedImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) =>
                                onValidationEmail(value ?? ''),
                            onSaved: (value) {
                              _formEmail = value!;
                            },
                          ),
                          if (!_isLogin)
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Username',
                              ),
                              keyboardType: TextInputType.text,
                              enableSuggestions: false,
                              validator: (value) =>
                                  onValidationUsername(value ?? ''),
                              onSaved: (value) {
                                _formUsername = value!;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            validator: (value) =>
                                onValidationPassword(value ?? ''),
                            onSaved: (value) {
                              _formPassword = value!;
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          ElevatedButton(
                            onPressed: _isLoading ? null : onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            child: _isLoading
                                ? const Text('Loading')
                                : elevatedButtonContent,
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : onPressTextButton,
                            child: textButtonContent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
