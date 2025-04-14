import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveInfoScreen extends StatefulWidget {
  @override
  _LiveInfoScreenState createState() => _LiveInfoScreenState();
}

class _LiveInfoScreenState extends State<LiveInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Info")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('live_info').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(doc['message']),
                  subtitle: Text(doc['timestamp'].toDate().toString()),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}