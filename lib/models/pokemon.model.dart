class PokemonModel {
  String name;
  String url;

  PokemonModel({required this.name, required this.url});

  factory PokemonModel.fromMap(Map<String, dynamic> data) {
    return PokemonModel(name: data['name'], url: data['url']);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
    };
  }
}
