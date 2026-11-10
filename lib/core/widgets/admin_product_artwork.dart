import 'package:games_admin/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

/// Genius dynamic artwork generator for admin cards & thumbnails.
/// Displays high-definition category-themed artwork when external APIs
/// (e.g., Syria Card / Auto1Card) do not return an image URL.
class AdminProductArtworkWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String category;
  final String mainCategory;
  final String source;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AdminProductArtworkWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    this.category = '',
    this.mainCategory = 'games',
    this.source = '',
    this.width = 44,
    this.height = 44,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl.isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))
            ? AppNetworkImage(
                imageUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDynamicCanvas(),
              )
            : _buildDynamicCanvas(),
      ),
    );
  }

  Widget _buildDynamicCanvas() {
    final theme = _getArtworkTheme(title, category, mainCategory);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          theme.icon,
          size: width * 0.52,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }

  _ArtworkTheme _getArtworkTheme(String name, String cat, String mc) {
    final query = '$name $cat'.toLowerCase();

    if (query.contains('pubg') || query.contains('ببجي')) {
      return _ArtworkTheme(
        gradient: [const Color(0xFFF59E0B), const Color(0xFFB45309)],
        icon: Icons.military_tech_rounded,
      );
    }
    if (query.contains('free fire') || query.contains('فري فاير')) {
      return _ArtworkTheme(
        gradient: [const Color(0xFFEF4444), const Color(0xFFB91C1C)],
        icon: Icons.local_fire_department_rounded,
      );
    }
    if (query.contains('whatsapp') || query.contains('واتساب')) {
      return _ArtworkTheme(
        gradient: [const Color(0xFF22C55E), const Color(0xFF15803D)],
        icon: Icons.chat_rounded,
      );
    }
    if (query.contains('telegram') || query.contains('تليجرام')) {
      return _ArtworkTheme(
        gradient: [const Color(0xFF0EA5E9), const Color(0xFF0369A1)],
        icon: Icons.send_rounded,
      );
    }
    if (query.contains('tiktok') || query.contains('تيك توك')) {
      return _ArtworkTheme(
        gradient: [const Color(0xFF06B6D4), const Color(0xFFE11D48)],
        icon: Icons.music_note_rounded,
      );
    }
    if (query.contains('netflix') || query.contains('نتفلكس') || query.contains('نتفليكس')) {
      return _ArtworkTheme(
        gradient: [const Color(0xFFDC2626), const Color(0xFF450A0A)],
        icon: Icons.movie_filter_rounded,
      );
    }
    if (query.contains('syriatel') || query.contains('سيريتل')) {
      return _ArtworkTheme(
        gradient: [const Color(0xFFE11D48), const Color(0xFF881337)],
        icon: Icons.cell_tower_rounded,
      );
    }
    if (query.contains('mtn') || query.contains('ام تي ان')) {
      return _ArtworkTheme(
        gradient: [const Color(0xFFFBBF24), const Color(0xFF78350F)],
        icon: Icons.signal_cellular_alt_rounded,
      );
    }

    switch (mc.toLowerCase()) {
      case 'apps':
        return _ArtworkTheme(
          gradient: [const Color(0xFF10B981), const Color(0xFF047857)],
          icon: Icons.forum_rounded,
        );
      case 'social':
        return _ArtworkTheme(
          gradient: [const Color(0xFFEC4899), const Color(0xFFBE185D)],
          icon: Icons.share_rounded,
        );
      case 'subscriptions':
        return _ArtworkTheme(
          gradient: [const Color(0xFFFB7185), const Color(0xFF9F1239)],
          icon: Icons.subscriptions_rounded,
        );
      case 'numbers':
        return _ArtworkTheme(
          gradient: [const Color(0xFF0284C7), const Color(0xFF075985)],
          icon: Icons.dialpad_rounded,
        );
      case 'cards':
        return _ArtworkTheme(
          gradient: [const Color(0xFFF59E0B), const Color(0xFFB45309)],
          icon: Icons.credit_card_rounded,
        );
      case 'payment':
        return _ArtworkTheme(
          gradient: [const Color(0xFF8B5CF6), const Color(0xFF5B21B6)],
          icon: Icons.account_balance_wallet_rounded,
        );
      case 'games':
      default:
        return _ArtworkTheme(
          gradient: [const Color(0xFF0284C7), const Color(0xFF4338CA)],
          icon: Icons.sports_esports_rounded,
        );
    }
  }
}

class _ArtworkTheme {
  final List<Color> gradient;
  final IconData icon;

  const _ArtworkTheme({required this.gradient, required this.icon});
}
