import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:search_image/Login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  FirebaseAuth auth = FirebaseAuth.instance;
  GoogleSignIn googleSignIn = GoogleSignIn();
  List<dynamic> imageUrls = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMoreImages = true;
  TextEditingController searchCon = TextEditingController();
  List<String> searchHistory = [];
  bool showhistory= false;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

 Future<void> fetchImages() async {
 
  if (isLoading || !hasMoreImages) return;

  setState(() {
    isLoading = true;
   
  });

  final response = await http.get(Uri.parse(
      'https://api.unsplash.com/photos?page=$currentPage&per_page=10&client_id=e-QtE1mUAutDN7R91luG6PtAZhd8c75yKSXNrqaklQw'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    setState(() {
      if (data.isEmpty) {
        hasMoreImages = false; 
      } else {
       
        imageUrls.addAll(data.map((e) => e['urls']['regular'] as String).toList());
        currentPage++;
      }
    });
  } else {
    print('Error fetching images: ${response.statusCode}');
  }

  setState(() {
    isLoading = false;
  });
}


  Future<void> fetchSearchHistory() async {
    final snapshot = await FirebaseFirestore.instance.collection('search_history').get();
    setState(() {
      searchHistory = snapshot.docs.map((doc) => doc['query'] as String).toList();
   showhistory = true;
    });
  
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
        actions: [
          IconButton(
              onPressed: () {
                loggedOut();
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: searchCon,
              onTap: fetchSearchHistory, 
              decoration: InputDecoration(
                suffixIcon: IconButton(
                    onPressed: () {
                      saveSearchQuery(searchCon.text);
                      searchImages(searchCon.text);
                      searchCon.clear();
                    setState(() {
                      showhistory =false;
                    });
                    },
                    icon: const Icon(Icons.search)),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(20),
                ),
                hintText: 'Search images',
              ),
            ),
          ),
          
          if (searchHistory.isNotEmpty && showhistory) 
            Container(
              color: Colors.grey[200],
              child: ListView.builder(
                shrinkWrap: true,
                physics:const  NeverScrollableScrollPhysics(),
                itemCount: searchHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(searchHistory[index]),
                    onTap: () {
                      searchImages(searchHistory[index]);
                      searchCon.text = searchHistory[index]; 
                      searchHistory.clear(); 
                    },
                  );
                },
              ),
            ),
          if (imageUrls.isNotEmpty)
            Expanded(
              child: CarouselSlider.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index, _) {
                  print(index);
                  print(imageUrls.length);
                  if (index == imageUrls.length - 1) {
                    fetchImages(); 
                  }
                  return Image.network(imageUrls[index], fit: BoxFit.cover);
                },
                options: CarouselOptions(
                  height: 400,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  
                ),
              ),
            ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void loggedOut() async {
    await auth.signOut();
    await googleSignIn.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
      return const Login();
    }));
  }

  Future<void> searchImages(String query) async {
    final response = await http.get(Uri.parse(
        'https://api.unsplash.com/search/photos?page=1&query=$query&client_id=e-QtE1mUAutDN7R91luG6PtAZhd8c75yKSXNrqaklQw'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['results'];
      setState(() {
        imageUrls = data.map((e) => e['urls']['regular']).toList();
      });
    } else {
      // Handle error
      print('Error searching images: ${response.statusCode}');
    }
  }

  Future<void> saveSearchQuery(String query) async {
    await FirebaseFirestore.instance.collection('search_history').add({
      'query': query,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
