import 'package:isar/isar.dart';

part 'post.model.g.dart';

@Collection()
class Post {
  int id = Isar.autoIncrement;

  late String title;

  late DateTime date;
}