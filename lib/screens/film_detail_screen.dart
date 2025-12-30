import 'dart:math';

import 'package:flutter/material.dart';

import 'package:remoview_mobile/models/film_detail.dart';
import 'package:remoview_mobile/models/review.dart';
import 'package:remoview_mobile/screens/auth_screen.dart';
import 'package:remoview_mobile/services/film_service.dart';
import 'package:remoview_mobile/services/token_store.dart';

class FilmDetailScreen extends StatefulWidget {
  final int filmId;
  const FilmDetailScreen({super.key, required this.filmId});

  @override
  State<FilmDetailScreen> createState() => _FilmDetailScreenState();
}

class _FilmDetailScreenState extends State<FilmDetailScreen> {
  final FilmService _service = FilmService();
  late Future<FilmDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.getFilmDetail(widget.filmId);
  }

  Future<void> _refresh() async {
    setState(() {
      _detailFuture = _service.getFilmDetail(widget.filmId);
    });
  }

  // ---------------- AUTH GUARD ----------------

  Future<bool> _requireAuth() async {
    final store = TokenStore();
    final has = await store.isLoggedIn();
    if (has) return true;

    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen()));

    final hasAfter = await store.isLoggedIn();
    final ok = (result == true) || hasAfter;

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devam etmek için giriş yapmalısın.')),
      );
    }
    return ok;
  }

  // ---------------- UI ACTIONS ----------------

  void _openRateSheet(double currentAvg, int filmId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _RateBottomSheet(
        initial: _mapAvgTo5(currentAvg),
        onSubmit: (stars) async {
          // Swagger: { "value": 5 } => int 0..5
          final intValue = stars.round().clamp(0, 5);

          final authed = await _requireAuth();
          if (!authed) return;

          try {
            await _service.addRating(filmId: filmId, value: intValue);

            if (!mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Puan verildi: $intValue ★')),
            );

            _refresh();
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Puan verilemedi: $e')));
          }
        },
      ),
    );
  }

  void _openAddCommentSheet(int filmId) {
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    'Yorum yaz',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Yorumunu yaz...',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = ctrl.text.trim();
                    if (text.length < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yorum en az 3 karakter olmalı.'),
                        ),
                      );
                      return;
                    }

                    final authed = await _requireAuth();
                    if (!authed) return;

                    try {
                      await _service.addReview(filmId: filmId, comment: text);

                      if (!mounted) return;
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yorum eklendi ✅')),
                      );

                      _refresh();
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Yorum eklenemedi: $e')),
                      );
                    }
                  },
                  child: const Text(
                    'Gönder',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<FilmDetail>(
        future: _detailFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Hata:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final d = snap.data!;
          final cs = Theme.of(context).colorScheme;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.black,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.star_rounded),
                      onPressed: () => _openRateSheet(d.averageRating, d.id),
                      tooltip: 'Puan ver',
                    ),
                    IconButton(
                      icon: const Icon(Icons.mode_comment_outlined),
                      onPressed: () => _openAddCommentSheet(d.id),
                      tooltip: 'Yorum yaz',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(
                      left: 56,
                      right: 16,
                      bottom: 12,
                    ),
                    title: Text(
                      d.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _HeroPoster(title: d.title, posterUrl: d.posterUrl),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.80),
                                Colors.black.withOpacity(0.10),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 18,
                          child: Row(
                            children: [
                              _Pill(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      d.averageRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _Stars(
                                      ratingOutOf5: _mapAvgTo5(d.averageRating),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _Pill(
                                child: Text(
                                  d.genres.isNotEmpty
                                      ? d.genres.take(2).join(' • ')
                                      : 'Tür?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withOpacity(0.90),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (d.genres.isNotEmpty ? d.genres : ['Tür?'])
                          .map((g) => _Tag(text: g, accent: cs.primary))
                          .toList(),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Yorumlar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${d.reviews.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withOpacity(0.70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (d.reviews.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 30, 16, 30),
                      child: Center(
                        child: Text('Henüz yorum yok. İlk yorumu sen yaz!'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
                    sliver: SliverList.separated(
                      itemCount: d.reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = d.reviews[i];
                        final isRight = (i % 2 == 1); // sağ-sol hissi
                        return _ReviewBubble(review: r, alignRight: isRight);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --------------------- UI helpers ---------------------

class _HeroPoster extends StatelessWidget {
  final String title;
  final String? posterUrl;
  const _HeroPoster({required this.title, required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    if (posterUrl != null && posterUrl!.isNotEmpty) {
      return Image.network(
        posterUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (context, child, prog) {
          if (prog == null) return child;
          return _fallback(isLoading: true);
        },
      );
    }
    return _fallback();
  }

  Widget _fallback({bool isLoading = false}) {
    final seed = title.hashCode;
    final rnd = Random(seed);
    final a = 0.10 + rnd.nextDouble() * 0.10;
    final b = 0.02 + rnd.nextDouble() * 0.10;

    final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Container(
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
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
      ),
    );
  }
}

class _ReviewBubble extends StatelessWidget {
  final Review review;
  final bool alignRight;
  const _ReviewBubble({required this.review, required this.alignRight});

  @override
  Widget build(BuildContext context) {
    final bg = alignRight
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.06);
    final border = Colors.white.withOpacity(0.10);

    // ✅ Review modelinde sadece comment garanti diye burayı net tuttum
    final comment = review.comment;

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(alignRight ? 16 : 6),
              bottomRight: Radius.circular(alignRight ? 6 : 16),
            ),
          ),
          child: Text(
            comment.trim().isEmpty ? '(Boş yorum)' : comment,
            style: TextStyle(
              height: 1.25,
              color: Colors.white.withOpacity(0.90),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color accent;
  const _Tag({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: accent,
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

class _RateBottomSheet extends StatefulWidget {
  final double initial;
  final ValueChanged<double> onSubmit;

  const _RateBottomSheet({required this.initial, required this.onSubmit});

  @override
  State<_RateBottomSheet> createState() => _RateBottomSheetState();
}

class _RateBottomSheetState extends State<_RateBottomSheet> {
  late double _stars;

  @override
  void initState() {
    super.initState();
    _stars = widget.initial.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Puan ver',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                '${_stars.toStringAsFixed(1)}★',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: _stars,
            min: 0,
            max: 5,
            divisions: 10,
            label: _stars.toStringAsFixed(1),
            onChanged: (v) => setState(() => _stars = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(_stars),
              child: const Text(
                'Kaydet',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
