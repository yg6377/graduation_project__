import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void fetchData() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var snapshot = await firestore.collection('users').get();
  for (var doc in snapshot.docs) {
    print(doc.data());
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                }


                return ListView.builder(
                  itemBuilder: (context, index) {

                            ),
                        )
                  },
                );
              },
      ),

  }
}