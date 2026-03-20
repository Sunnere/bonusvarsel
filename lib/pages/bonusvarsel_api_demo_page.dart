import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BonusvarselApiDemoPage extends StatefulWidget {
  const BonusvarselApiDemoPage({super.key});

  @override
  State<BonusvarselApiDemoPage> createState() => _BonusvarselApiDemoPageState();
}

class _BonusvarselApiDemoPageState extends State<BonusvarselApiDemoPage> {

  late Future<Map<String,dynamic>> meFuture;
  late Future<Map<String,dynamic>> prefsFuture;
  late Future<List> feedFuture;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    meFuture = ApiService.getMe();
    prefsFuture = ApiService.getPrefs();
    feedFuture = ApiService.getFeed();
  }

  Future refresh() async {
    setState(load);
  }

  Widget section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top:20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          child
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bonusvarsel API demo"),
        actions:[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh
          )
        ]
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'ApiService.baseUrl=${ApiService.baseUrl} | Uri.base=${Uri.base}',
                style: const TextStyle(fontSize: 12),
              ),
            ),

            section(
              "/v1/me",
              FutureBuilder(
                future: meFuture,
                builder:(context,s){
                  if(!s.hasData) return const CircularProgressIndicator();
                  return Text(s.data.toString());
                }
              )
            ),

            section(
              "/v1/prefs",
              FutureBuilder(
                future: prefsFuture,
                builder:(context,s){
                  if(!s.hasData) return const CircularProgressIndicator();
                  return Text(s.data.toString());
                }
              )
            ),

            section(
              "/v1/feed",
              FutureBuilder(
                future: feedFuture,
                builder:(context,s){
                  if(!s.hasData) return const CircularProgressIndicator();

                  final list = s.data as List;

                  return Column(
                    children: list.map((e){
                      return ListTile(
                        title: Text(e["store"] ?? ""),
                        subtitle: Text(e["rateText"] ?? "")
                      );
                    }).toList(),
                  );
                }
              )
            ),

          ],
        ),
      ),
    );
  }
}
