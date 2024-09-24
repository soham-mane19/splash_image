import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:search_image/HomeScreen.dart';
import 'package:search_image/Login.dart';

class Check extends StatefulWidget {
  const Check({super.key});

  @override
  State<Check> createState() => CheckState();
}

class CheckState extends State<Check> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(), 
      builder: (context, snapshot) {
        if(snapshot.connectionState ==ConnectionState.waiting){
        return   const  Center(
            child:  CircularProgressIndicator());

        }else if(snapshot.hasData){
          return const  Home();

        }else{
          return const Login();
        }
      },);
  }
}