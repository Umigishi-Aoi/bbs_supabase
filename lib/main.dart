import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://dmqdcvqerqzvhjwzflxo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRtcWRjdnFlcnF6dmhqd3pmbHhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTMzNTUzNjEsImV4cCI6MjAwODkzMTM2MX0.Gvt_9Bt9NQXgu4Eq5-auU_0L6Eobs4r9rDghFKEjzN0',
  );
  final supabase = Supabase.instance.client;
  runApp(
    MyApp(
      supabaseClient: supabase,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({required this.supabaseClient, super.key});

  final SupabaseClient supabaseClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: MyWidget(
        supabaseClient: supabaseClient,
      ),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({required this.supabaseClient, super.key});

  final SupabaseClient supabaseClient;

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  AuthChangeEvent event = AuthChangeEvent.signedOut;
  Session? session;
  @override
  void initState() {
    widget.supabaseClient.auth.onAuthStateChange.listen((data) {
      setState(() {
        event = data.event;
        if (event == AuthChangeEvent.signedIn) {
          session = data.session;
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (event != AuthChangeEvent.signedIn) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 300,
                height: 150,
                child: ElevatedButton(
                  onPressed: () async {
                    await widget.supabaseClient.auth.signInWithOAuth(
                      Provider.github,

                      /// When I add this, it work
                      // redirectTo:
                      //     'https://umigishi-aoi.github.io/bbs_supabase/',
                    );
                  },
                  child: const Text('GitHub Login'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return BbsPage(
        supabaseClient: widget.supabaseClient,
        session: session!,
      );
    }
  }
}

class BbsPage extends StatefulWidget {
  const BbsPage({
    required this.supabaseClient,
    required this.session,
    super.key,
  });

  final SupabaseClient supabaseClient;
  final Session session;

  @override
  State<BbsPage> createState() => _BbsPageState();
}

class _BbsPageState extends State<BbsPage> {
  late Future<List<dynamic>> data;

  @override
  void initState() {
    data = widget.supabaseClient.from('bbs').select();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              await widget.supabaseClient.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        title: const Text('BBS'),
      ),
      body: FutureBuilder(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.data == null) {
            return const Text('No data');
          }
          final list = snapshot.data!.reversed.toList();

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index] as Map<String, dynamic>;
              final date = DateTime.parse(
                item['created_at'].toString(),
              ).toLocal().toString();
              return Padding(
                padding: const EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border.all()),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 64),
                          child: ClipOval(
                            child: Image.network(
                              item['avatar_url'].toString(),
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['nickname'].toString()),
                                    Text(
                                      date.substring(0, date.length - 7),
                                    ),
                                  ],
                                ),
                              ),
                              Text(item['content'].toString()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<Widget>(
              builder: (context) => AddPage(
                supabaseClient: widget.supabaseClient,
                session: widget.session,
              ),
            ),
          );
          data = widget.supabaseClient.from('bbs').select();
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddPage extends StatefulWidget {
  const AddPage({
    required this.supabaseClient,
    required this.session,
    super.key,
  });

  final SupabaseClient supabaseClient;
  final Session session;

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextField(
                maxLength: 150,
                maxLines: 5,
                minLines: 1,
                controller: controller,
              ),
              ElevatedButton(
                onPressed: () async {
                  await widget.supabaseClient.from('bbs').insert({
                    'content': controller.text,
                    'uid': widget.supabaseClient.auth.currentUser!.id,
                    'nickname': widget.session.user.userMetadata!['user_name'],
                    'avatar_url':
                        widget.session.user.userMetadata!['avatar_url'],
                  });
                  if (!mounted) {
                    return;
                  }
                  Navigator.pop(context);
                },
                child: const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
