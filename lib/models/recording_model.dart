import 'package:hive/hive.dart';

part 'recording_model.g.dart'; 

@HiveType(typeId: 1)
class Recording {
  @HiveField(0)
  final String type; 

  @HiveField(1)
  final String filePath;

  Recording({required this.type, required this.filePath});
}
