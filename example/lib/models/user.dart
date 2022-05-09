class User {
  int id;
  String name;
  String password;
  DateTime? createdAt;
  DateTime? updatedAt;
  User(
      {required this.id,
      required this.name,
      required this.password,
      this.createdAt,
      this.updatedAt});
}
