import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:once_isar_flutt/model/post.model.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  final isar = await Isar.open(schemas: [PostSchema], directory: dir.path);
  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  final Isar isar;
  const MyApp({Key? key, required this.isar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'Flutter Isar',
        isar: isar,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Isar isar;
  const MyHomePage({Key? key, required this.title, required this.isar})
      : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoading = false;

  final TextEditingController _controller = TextEditingController();

  Future<List<Post>> execQuery() {
    return widget.isar.posts.where().findAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: execQuery(),
        builder: (BuildContext context, AsyncSnapshot<List<Post>?> data) {
          if (data.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (data.hasData) {
            if (data.data!.isEmpty) {
              return const Center(child: Text("Add Content"));
            }
            return isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount: data.data!.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(data.data![index].title),
                        subtitle: Text(data.data![index].date.toString()),
                        onTap: () async {
                          await widget.isar.writeTxn((isar) async {
                            await isar.posts.delete(data.data![index].id);
                          });
                          setState(() {});
                        },
                      );
                    },
                  );
          }
          return Container();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialogSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  showDialogSheet() {
    showDialog(
      context: context,
      builder: (_) {
        return SimpleDialog(
          title: const Text("Add Title"),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_controller.text.isEmpty) {
                    return;
                  }
                  addPost(_controller.text);
                  _controller.clear();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Submit",
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  addPost(String nameAdd) async {
    setState(() {
      isLoading = true;
    });
    try {
      final newPost = Post()
        ..title = nameAdd
        ..date = DateTime.now();
      await widget.isar.writeTxn((isar) async {
        await isar.posts.put(newPost);
      });
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      e.toString();
      setState(() {
        isLoading = false;
      });
    }
  }
}
