import 'package:hive/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 2)
class Income extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  Income({required this.title, required this.amount, required this.date});
}
