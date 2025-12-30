import 'package:flutter/material.dart';
import 'package:remoview_mobile/models/genre.dart';
import 'package:remoview_mobile/services/film_service.dart';
import 'package:remoview_mobile/services/genre_service.dart';

class AddFilmScreen extends StatefulWidget {
  const AddFilmScreen({super.key});

  @override
  State<AddFilmScreen> createState() => _AddFilmScreenState();
}

class _AddFilmScreenState extends State<AddFilmScreen> {
  final _filmService = FilmService();
  final _genreService = GenreService();

  final _titleCtrl = TextEditingController();
  final _posterCtrl = TextEditingController();

  late Future<List<Genre>> _genresFuture;
  final Set<int> _selectedGenreIds = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _genresFuture = _genreService.getGenres();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _posterCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final poster = _posterCtrl.text.trim();

    if (title.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık en az 2 karakter olmalı.')),
      );
      return;
    }
    if (_selectedGenreIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('En az 1 tür seçmelisin.')));
      return;
    }

    setState(() => _loading = true);
    try {
      await _filmService.createFilm(
        title: title,
        posterUrl: poster.isEmpty ? null : poster,
        genreIds: _selectedGenreIds.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Film eklendi ✅')));

      Navigator.pop(context, true); // home’a “yenile” sinyali
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Film eklenemedi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Film Ekle')),
      body: SafeArea(
        child: FutureBuilder<List<Genre>>(
          future: _genresFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Türler alınamadı.\n\nHata: ${snap.error}\n\n'
                    'Eğer backend’de /api/genres yoksa söyle, ona göre endpoint ekleyelim.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final genres = snap.data ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Field(
                  label: 'Film adı',
                  controller: _titleCtrl,
                  hint: 'Örn: Inception',
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Poster URL (opsiyonel)',
                  controller: _posterCtrl,
                  hint: 'https://...',
                ),
                const SizedBox(height: 16),
                Text(
                  'Türler',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.90),
                  ),
                ),
                const SizedBox(height: 10),

                if (genres.isEmpty)
                  Text(
                    'Hiç tür yok. Önce backend’e tür eklemen gerek.',
                    style: TextStyle(color: Colors.white.withOpacity(0.70)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres.map((g) {
                      final selected = _selectedGenreIds.contains(g.id);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedGenreIds.remove(g.id);
                            } else {
                              _selectedGenreIds.add(g.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected
                                  ? cs.primary.withOpacity(0.65)
                                  : Colors.white.withOpacity(0.10),
                            ),
                            color: selected
                                ? cs.primary.withOpacity(0.14)
                                : Colors.white.withOpacity(0.06),
                          ),
                          child: Text(
                            g.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: selected
                                  ? cs.primary
                                  : Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                    label: const Text(
                      'Filmi ekle',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.90),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
          ),
        ),
      ],
    );
  }
}
