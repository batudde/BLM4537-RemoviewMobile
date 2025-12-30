import 'dart:math';
import 'package:flutter/material.dart';

import 'package:remoview_mobile/services/api_client.dart';
import 'package:remoview_mobile/models/favorite_film.dart';

import 'package:remoview_mobile/screens/add_film_screen.dart';
import 'package:remoview_mobile/screens/film_detail_screen.dart';
import 'package:remoview_mobile/screens/profile_screen.dart';
import 'package:remoview_mobile/screens/auth_screen.dart';

import 'package:remoview_mobile/services/film_service.dart';
import 'package:remoview_mobile/services/token_store.dart';
import 'package:remoview_mobile/models/film.dart';

class RemoviewHomePage extends StatefulWidget {
  const RemoviewHomePage({super.key});

  @override
  State<RemoviewHomePage> createState() => _RemoviewHomePageState();
}

class _RemoviewHomePageState extends State<RemoviewHomePage> {
  final FilmService _filmService = FilmService();
  late Future<List<Film>> _filmsFuture;

  // ✅ Favoriler
  final ApiClient _api = ApiClient();
  Set<int> _favoriteIds = {};
  bool _favLoading = true; // ilk açılışta favorileri çekiyoruz

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGenre; // null => all

  final Map<int, _FilmMeta> _metaCache = {};
  Film? _featured;

  @override
  void initState() {
    super.initState();
    _loadFavorites();

    _filmsFuture = _filmService.getFilms().then((films) {
      _metaCache.clear();
      for (final f in films) {
        _metaCache[f.id] = _FilmMeta(
          averageRating: f.averageRating,
          genres: f.genres,
          posterUrl: f.posterUrl,
        );
      }

      if (films.isNotEmpty) {
        _featured = films[Random().nextInt(films.length)];
      } else {
        _featured = null;
      }
      return films;
    });

    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  // ✅ Favorileri API’den çek (ilk açılış)
  Future<void> _loadFavorites() async {
    try {
      final favs = await _api.getFavorites(); // List<FavoriteFilm>
      setState(() {
        _favoriteIds = favs.map((f) => f.id).toSet();
        _favLoading = false;
      });
    } catch (_) {
      setState(() => _favLoading = false);
    }
  }

  // ✅ Kalbe basınca ekle/çıkar
  Future<void> _toggleFavorite(int filmId) async {
    final isFav = _favoriteIds.contains(filmId);

    // UI’ı anında değiştir (hızlı hissiyat)
    setState(() {
      if (isFav) {
        _favoriteIds.remove(filmId);
      } else {
        _favoriteIds.add(filmId);
      }
    });

    // API çağrısı
    final ok = isFav
        ? await _api.removeFavorite(filmId)
        : await _api.addFavorite(filmId);

    // API başarısızsa geri al
    if (!ok) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(filmId);
        } else {
          _favoriteIds.remove(filmId);
        }
      });
    }
  }

  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Film> _applyFilters(List<Film> films) {
    var filtered = films;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((f) => f.title.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (_selectedGenre != null) {
      filtered = filtered
          .where((f) => f.genres.contains(_selectedGenre))
          .toList();
    }

    return filtered;
  }

  List<String> _availableGenres(List<Film> films) {
    final set = <String>{};
    for (final f in films) {
      set.addAll(f.genres);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _openFilmDetailAndRefreshCache(int filmId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => FilmDetailScreen(filmId: filmId)));

    try {
      final detail = await _filmService.getFilmDetail(filmId);
      setState(() {
        _metaCache[filmId] = _FilmMeta(
          averageRating: detail.averageRating,
          genres: detail.genres,
          posterUrl: detail.posterUrl,
        );
      });
    } catch (_) {}
  }

  // ✅ Film ekleme ekranına git -> true dönerse listeyi yenile
  Future<void> _openAddFilmAndRefresh() async {
    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddFilmScreen()));

    if (ok == true) {
      setState(() {
        _filmsFuture = _filmService.getFilms().then((films) {
          _metaCache.clear();
          for (final f in films) {
            _metaCache[f.id] = _FilmMeta(
              averageRating: f.averageRating,
              genres: f.genres,
              posterUrl: f.posterUrl,
            );
          }

          if (films.isNotEmpty) {
            _featured = films[Random().nextInt(films.length)];
          } else {
            _featured = null;
          }

          return films;
        });
      });
    }
  }

  // ✅ Profil sayfasına git
  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  // ✅ Çıkış yap: token/email sil -> AuthScreen'e dön
  Future<void> _logout() async {
    await TokenStore().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const _CinematicBackground(),

          SafeArea(
            child: FutureBuilder<List<Film>>(
              future: _filmsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _HomeSkeleton();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Bir hata oluştu:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final films = snapshot.data ?? [];
                final filtered = _applyFilters(films);
                final genres = _availableGenres(films);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Remoview',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Spacer(),

                                // ✅ + ikon
                                InkWell(
                                  onTap: _openAddFilmAndRefresh,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.10),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // ✅ Profil + Çıkış menüsü
                                PopupMenuButton<String>(
                                  tooltip: 'Profil',
                                  color: const Color(0xFF171A21),
                                  onSelected: (v) {
                                    if (v == 'profile') _openProfile();
                                    if (v == 'logout') _logout();
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'profile',
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_rounded),
                                          SizedBox(width: 10),
                                          Text('Profil'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuDivider(),
                                    PopupMenuItem(
                                      value: 'logout',
                                      child: Row(
                                        children: [
                                          Icon(Icons.logout_rounded),
                                          SizedBox(width: 10),
                                          Text('Çıkış Yap'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.10),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),
                            Text(
                              'Keşfet • Puanla • Yorumları oku',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.72),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _SearchBar(
                              controller: _searchController,
                              onClear: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                            const SizedBox(height: 12),

                            if (_featured != null)
                              _FeaturedCard(
                                film: _featured!,
                                meta: _metaCache[_featured!.id],
                                onTap: () => _openFilmDetailAndRefreshCache(
                                  _featured!.id,
                                ),
                              ),

                            const SizedBox(height: 14),

                            _GenreChipsRow(
                              genres: genres,
                              selected: _selectedGenre,
                              onSelect: (g) =>
                                  setState(() => _selectedGenre = g),
                              onClear: () =>
                                  setState(() => _selectedGenre = null),
                            ),

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  _selectedGenre == null
                                      ? '${filtered.length} film'
                                      : '${filtered.length} film • $_selectedGenre',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.72),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedGenre != null ||
                                    _searchQuery.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedGenre = null;
                                      });
                                    },
                                    child: const Text('Sıfırla'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (films.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('Film bulunamadı.')),
                      )
                    else if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            _selectedGenre != null
                                ? 'Bu türe ait film yok.'
                                : 'Aramaya uygun film yok.',
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final film = filtered[index];

                            var posterUrl = film.posterUrl;
                            var filmGenres = film.genres;
                            var avg = film.averageRating;

                            final meta = _metaCache[film.id];
                            if (meta != null) {
                              posterUrl = meta.posterUrl ?? posterUrl;
                              if (meta.genres.isNotEmpty)
                                filmGenres = meta.genres;
                              avg = meta.averageRating;
                            }

                            return _FilmGridCard(
                              filmId: film.id,
                              title: film.title,
                              posterUrl: posterUrl,
                              averageRating: avg,
                              genres: filmGenres,
                              isFavorite: _favoriteIds.contains(film.id),
                              onFavoriteTap: () => _toggleFavorite(film.id),
                              onTap: () =>
                                  _openFilmDetailAndRefreshCache(film.id),
                            );
                          }, childCount: filtered.length),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // ✅ Sağ altta + butonu (Film ekleme)
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFilmAndRefresh,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FilmMeta {
  final double averageRating;
  final List<String> genres;
  final String? posterUrl;

  _FilmMeta({
    required this.averageRating,
    required this.genres,
    required this.posterUrl,
  });
}

// ---------------- Background ----------------

class _CinematicBackground extends StatelessWidget {
  const _CinematicBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF06070B), Color(0xFF12060A), Color(0xFF070A12)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB00020).withOpacity(0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.15,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.75),
                ],
                stops: const [0.0, 0.72, 1.0],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _BgNoisePainter(seed: 1337),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

class _BgNoisePainter extends CustomPainter {
  final int seed;
  _BgNoisePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.018);

    final count = (size.width * size.height / 1400).clamp(180, 520).toInt();
    for (int i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = 0.6 + rnd.nextDouble() * 1.2;
      canvas.drawCircle(Offset(dx, dy), r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BgNoisePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

// ---------------- UI PIECES ----------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Film ara...',
                  border: InputBorder.none,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close_rounded, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GenreChipsRow extends StatelessWidget {
  final List<String> genres;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final VoidCallback onClear;

  const _GenreChipsRow({
    required this.genres,
    required this.selected,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          const SizedBox(width: 2),
          _Chip(
            text: 'Tümü',
            selected: selected == null,
            accent: cs.primary,
            onTap: onClear,
          ),
          const SizedBox(width: 8),
          ...genres.map((g) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                text: g,
                selected: selected == g,
                accent: cs.primary,
                onTap: () => onSelect(g),
              ),
            );
          }),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _Chip({
    required this.text,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent.withOpacity(0.65)
                : Colors.white.withOpacity(0.10),
          ),
          color: selected
              ? accent.withOpacity(0.14)
              : Colors.white.withOpacity(0.06),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? accent : Colors.white.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Film film;
  final _FilmMeta? meta;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.film,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final posterUrl = meta?.posterUrl ?? film.posterUrl;
    final genres = (meta?.genres.isNotEmpty ?? false)
        ? meta!.genres
        : film.genres;
    final avg = meta?.averageRating ?? film.averageRating;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.35),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PosterFancy(title: film.title, posterUrl: posterUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.black.withOpacity(0.72),
                      Colors.black.withOpacity(0.10),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: cs.primary.withOpacity(0.22),
                        border: Border.all(color: cs.primary.withOpacity(0.35)),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      film.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Stars(ratingOutOf5: _mapAvgTo5(avg)),
                        const SizedBox(width: 8),
                        Text(
                          avg.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withOpacity(0.90),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: cs.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (genres.isNotEmpty ? genres.take(3) : ['Tür?'])
                          .map((g) => _MiniTag(text: g))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilmGridCard extends StatelessWidget {
  final int filmId;
  final String title;
  final String? posterUrl;
  final double averageRating;
  final List<String> genres;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _FilmGridCard({
    required this.filmId,
    required this.title,
    required this.posterUrl,
    required this.averageRating,
    required this.genres,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          color: Colors.white.withOpacity(0.06),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _PosterFancy(title: title, posterUrl: posterUrl),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: InkWell(
                        onTap: onFavoriteTap,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isFavorite ? "❤️" : "🤍",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 10,
                      bottom: 10,
                      right: 10,
                      child: Row(
                        children: [
                          _Pill(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.play_circle_fill_rounded,
                            size: 26,
                            color: cs.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Stars(
                          ratingOutOf5: _mapAvgTo5(averageRating),
                          size: 16,
                        ),
                        const Spacer(),
                        Text(
                          genres.isNotEmpty ? genres.first : 'Tür?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.72),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.10),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white.withOpacity(0.90),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: child,
    );
  }
}

double _mapAvgTo5(double avg) {
  if (avg <= 5) return avg.clamp(0, 5);
  return (avg / 2).clamp(0, 5);
}

class _Stars extends StatelessWidget {
  final double ratingOutOf5;
  final double size;

  const _Stars({required this.ratingOutOf5, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final full = ratingOutOf5.floor();
    final half = (ratingOutOf5 - full) >= 0.5 ? 1 : 0;
    final empty = 5 - full - half;

    final icons = <Widget>[
      for (int i = 0; i < full; i++) Icon(Icons.star_rounded, size: size),
      if (half == 1) Icon(Icons.star_half_rounded, size: size),
      for (int i = 0; i < empty; i++)
        Icon(
          Icons.star_outline_rounded,
          size: size,
          color: Colors.white.withOpacity(0.70),
        ),
    ];

    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }
}

class _PosterFancy extends StatelessWidget {
  final String title;
  final String? posterUrl;

  const _PosterFancy({required this.title, required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    if (posterUrl != null && posterUrl!.isNotEmpty) {
      return Image.network(
        posterUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _fallback(isLoading: true);
        },
      );
    }
    return _fallback();
  }

  Widget _fallback({bool isLoading = false}) {
    final seed = title.hashCode;
    final rnd = Random(seed);

    final a = 0.10 + rnd.nextDouble() * 0.12;
    final b = 0.02 + rnd.nextDouble() * 0.10;

    final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return CustomPaint(
      painter: _NoisePainter(seed: seed),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(a), Colors.white.withOpacity(b)],
          ),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Text(
                  letter,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  final int seed;
  _NoisePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final paint = Paint()..color = Colors.white.withOpacity(0.035);

    final count = (size.width * size.height / 260).clamp(120, 420).toInt();
    for (int i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = 0.6 + rnd.nextDouble() * 1.6;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

// ---------------- Skeleton loading ----------------

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkelBox(width: 180, height: 34),
                const SizedBox(height: 10),
                _SkelBox(width: 210, height: 14),
                const SizedBox(height: 14),
                _SkelBox(width: double.infinity, height: 46, radius: 16),
                const SizedBox(height: 14),
                _SkelBox(width: double.infinity, height: 170, radius: 22),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, __) =>
                        const _SkelBox(width: 84, height: 42, radius: 999),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _SkelGridCard(),
              childCount: 6,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkelGridCard extends StatelessWidget {
  const _SkelGridCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          color: Colors.white.withOpacity(0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: _SkelBox(width: double.infinity, height: double.infinity),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkelBox(width: 120, height: 14),
                  SizedBox(height: 8),
                  _SkelBox(width: 90, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkelBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkelBox({required this.width, required this.height, this.radius = 12});

  const _SkelBox.infinite({required this.height, this.radius = 12})
    : width = double.infinity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withOpacity(0.08),
      ),
    );
  }
}
