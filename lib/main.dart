import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

void main() {
  runApp(const PokemonApp());
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokemon Infinite Scroll',
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      home: const PokemonPage(),
    );
  }
}

class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  static const int pageSize = 5;

  late final PagingController<int, Map<String, dynamic>> _pagingController;

  @override
  void initState() {
    super.initState();

    _pagingController = PagingController(
      getNextPageKey: (state) {
        if (state.lastPageIsEmpty) return null;
        return state.nextIntPageKey;
      },
      fetchPage: _fetchPage,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int pageKey) async {
    final offset = pageKey * pageSize;

    final response = await http.get(
      Uri.parse(
        'https://pokeapi.co/api/v2/pokemon?limit=$pageSize&offset=$offset',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cargar Pokémon');
    }

    final data = jsonDecode(response.body);
    final List results = data['results'];

    List<Map<String, dynamic>> pokemons = [];

    for (var pokemon in results) {
      final detailResponse = await http.get(Uri.parse(pokemon['url']));
      if (detailResponse.statusCode == 200) {
        pokemons.add(jsonDecode(detailResponse.body));
      }
    }

    return pokemons;
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Scroll Infinito'),
        centerTitle: true,
      ),
      body: PagingListener(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) {
          return PagedListView<int, Map<String, dynamic>>(
            state: state,
            fetchNextPage: fetchNextPage,
            builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
              itemBuilder: (context, pokemon, index) {
                final name = pokemon['name'];
                final image = pokemon['sprites']['front_default'];
                final id = pokemon['id'];
                final order = pokemon['order'];
                final height = pokemon['height'];
                final weight = pokemon['weight'];
                final baseExp = pokemon['base_experience'];
                final abilities = pokemon['abilities'] as List;
                final types = pokemon['types'] as List;
                final moves = pokemon['moves'] as List;
                final stats = pokemon['stats'] as List;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image.network(
                            image,
                            height: 120,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            name.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('ID: $id'),
                        Text('Orden: $order'),
                        Text('Altura: ${height / 10} m'),
                        Text('Peso: ${weight / 10} kg'),
                        Text('Experiencia base: $baseExp'),
                        Text('Número de movimientos: ${moves.length}'),
                        const SizedBox(height: 8),
                        const Text('Tipos:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...types.map((t) => Text(t['type']['name'])),
                        const SizedBox(height: 8),
                        const Text('Habilidades:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...abilities.map((a) => Text(a['ability']['name'])),
                        const SizedBox(height: 8),
                        const Text('Estadísticas base:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...stats.map((s) =>
                            Text('${s['stat']['name']}: ${s['base_stat']}')),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
