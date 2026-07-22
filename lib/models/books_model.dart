import 'dart:convert';

List<Books> booksFromJson(String str) =>
    List<Books>.from(json.decode(str).map((x) => Books.fromJson(x)));

String booksToJson(List<Books> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Books {
  int? id;
  String? userid;
  String? author;
  String? title;
  String? genre;
  String? price;
  DateTime? publishDate;
  String? description;
  String? image;
  String? locationCoordinates;
  String? bookSort;

  Books({
    this.id,
    this.userid,
    this.author,
    this.title,
    this.genre,
    this.price,
    this.publishDate,
    this.description,
    this.image,
    this.locationCoordinates,
    this.bookSort,
  });

  factory Books.fromJson(Map<String, dynamic> json) => Books(
        id: int.parse(json["id"]),
        userid: json["userid"],
        author: json["author"],
        title: json["title"],
        genre: json["genre"],
        price: json["price"],
        publishDate: DateTime.parse(json["publishDate"]),
        description: json["description"],
        image: json["image"],
        locationCoordinates: json["locationCoordinates"],
        bookSort: json["booksort"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "userid": userid,
        "author": author,
        "title": title,
        "genre": genre,
        "price": price,
        "publishDate":
            "${publishDate?.year.toString().padLeft(4, '0')}-${publishDate?.month.toString().padLeft(2, '0')}-${publishDate?.day.toString().padLeft(2, '0')}",
        "description": description,
        "image": image,
        "locationCoordinates": locationCoordinates,
        "booksort": bookSort,
      };
}
