import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokAPI Pokemones',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  String regionSeleccionada = 'Kanto';

  Map<String, List<dynamic>> pokemonRegion = {
    'Kanto': [],
    'Johto': [],
    'Hoenn': [],
    'Sinnoh': [],
    'Unova': [],
    'Kalos': [],
    'Alola': [],
    'Galar': [],
    'Paldea': []
  };

  List<dynamic> listaFiltradaPokemon = [];

  @override
  void initState() {
    super.initState();
    fetchAllRegions();
  }

  Future<void> fetchAllRegions() async {
    await fetchPokemonList('Kanto', 151);
    await fetchPokemonList('Johto', 100, offset: 151);
    await fetchPokemonList('Hoenn', 135, offset: 251);
    await fetchPokemonList('Sinnoh', 107, offset: 386);
    await fetchPokemonList('Unova', 156, offset: 493);
    await fetchPokemonList('Kalos', 72, offset: 649);
    await fetchPokemonList('Alola', 88, offset: 721);
    await fetchPokemonList('Galar', 89, offset: 809);
    await fetchPokemonList('Paldea', 110, offset: 898);

    setState(() {
      listaFiltradaPokemon = pokemonRegion[regionSeleccionada]!;
      isLoading = false;
    });
  }

  Future<void> fetchPokemonList(String region, int limit,
      {int offset = 0}) async {
    final url = Uri.parse(
        'https://pokeapi.co/api/v2/pokemon?limit=$limit&offset=$offset');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        pokemonRegion[region] = data['results'];
      });
    } else {
      throw Exception('Error al cargar la lista de Pokémon');
    }
  }

  void _cambioRegion(String region) {
    setState(() {
      regionSeleccionada = region;
      listaFiltradaPokemon = pokemonRegion[regionSeleccionada]!;
    });
  }

  String pokemonImagenUrl(String url) {
    final id = url.split('/')[url.split('/').length - 2];
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PokeAPI Pokemones'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: pokemonRegion.keys.map((region) {
                        return GestureDetector(
                          onTap: () => _cambioRegion(region),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.0),
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: regionSeleccionada == region
                                  ? Colors.deepOrange
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              region,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: listaFiltradaPokemon.length,
                    itemBuilder: (context, index) {
                      final pokemon = listaFiltradaPokemon[index];
                      final imageUrl = pokemonImagenUrl(pokemon['url']);

                      return ListTile(
                        leading: Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.error, color: Colors.red),
                        ),
                        title: Text(
                          pokemon['name'].toString().toUpperCase(),
                          style: TextStyle(fontSize: 18),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PokemonDetailScreen(
                                name: pokemon['name'],
                                imageUrl: imageUrl,
                                url: pokemon['url'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class PokemonDetailScreen extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String url;

  PokemonDetailScreen({
    required this.name,
    required this.imageUrl,
    required this.url,
  });

  Future<List<String>> fetchPokemonAbilities() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['abilities'] as List)
          .map((ability) => ability['ability']['name'] as String)
          .toList();
    } else {
      throw Exception('Error al cargar habilidades del Pokémon');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name.toUpperCase()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              imageUrl,
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.error, color: Colors.red, size: 50),
            ),
            SizedBox(height: 20),
            Text(
              name.toUpperCase(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            FutureBuilder<List<String>>(
              future: fetchPokemonAbilities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error al cargar habilidades');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('Sin habilidades');
                } else {
                  return Column(
                    children: [
                      Text(
                        'Habilidades',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      for (var ability in snapshot.data!)
                        Text(
                          ability,
                          style: TextStyle(fontSize: 18),
                        ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
