import 'package:flutter/material.dart';
import 'package:remoview_mobile/screens/auth_screen.dart';
import 'package:remoview_mobile/services/token_store.dart';
import 'package:remoview_mobile/services/api_client.dart';
import 'package:remoview_mobile/models/favorite_film.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _store = TokenStore();
  final _api = ApiClient();

  // ✅ Favoriler yatay liste için controller (scrollbar göstereceğiz)
  final ScrollController _favScroll = ScrollController();

  String? _email;

  // ✅ Favorileri sürekli tekrar çekip “git-gel” yapmasın diye tek Future
  late Future<List<FavoriteFilm>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadEmail();
    _favoritesFuture = _api.getFavorites(); // ✅ tek sefer
  }

  @override
  void dispose() {
    _favScroll.dispose();
    super.dispose();
  }

  Future<void> _loadEmail() async {
    final e = await _store.getEmail();
    if (!mounted) return;
    setState(() => _email = e);
  }

  void _refreshFavorites() {
    setState(() {
      _favoritesFuture = _api.getFavorites(); // ✅ sadece future yenilenir
    });
  }

  Future<void> _logout() async {
    await _store.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _email ?? '—';
    final letter = (email.isNotEmpty && email != '—')
        ? email.trim()[0].toUpperCase()
        : '?';

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      Center(
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withOpacity(0.55),
                                Colors.white.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withOpacity(0.06),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white.withOpacity(0.80),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Favori filmlerinizi ana sayfadan detaylı inceleyebilirsiniz.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Favoriler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          IconButton(
                            onPressed: _refreshFavorites,
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Yenile',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      FutureBuilder<List<FavoriteFilm>>(
                        future: _favoritesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              'Favoriler yükleniyor...',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.70),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                snapshot.error.toString(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.90),
                                ),
                              ),
                            );
                          }

                          final favs = snapshot.data ?? [];
                          if (favs.isEmpty) {
                            return Text(
                              'Henüz favorin yok.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.70),
                              ),
                            );
                          }

                          // ✅ Asıl fix: mobilde “4 tane var sandıran” şey scroll ipucu yokluğu.
                          // Scrollbar ile anlaşılır hale geliyor.
                          return SizedBox(
                            height: 160,
                            child: Scrollbar(
                              controller: _favScroll,
                              thumbVisibility: true,
                              child: ListView.separated(
                                controller: _favScroll,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: favs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final f = favs[i];
                                  return _FavoritePosterCard(
                                    title: f.title,
                                    posterUrl: f.posterUrl,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Çıkış Yap',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritePosterCard extends StatelessWidget {
  final String title;
  final String? posterUrl;

  const _FavoritePosterCard({required this.title, required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: (posterUrl == null || posterUrl!.trim().isEmpty)
                ? Container(
                    color: Colors.white.withOpacity(0.06),
                    child: Center(
                      child: Text(
                        title.isNotEmpty ? title[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                    ),
                  )
                : Image.network(
                    posterUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white.withOpacity(0.06),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
