import 'package:flutter/material.dart';

class CategoryItemModel {
  final String id;
  final String key;
  final String title;
  final String subtitle;
  final String icon;
  final String color;
  final String imageUrl;
  final int sortOrder;
  final bool isCustom;
  final int productCount;
  final double? profitPercentage;

  const CategoryItemModel({
    required this.id,
    required this.key,
    required this.title,
    this.subtitle = '',
    this.icon = 'category_rounded',
    this.color = '#6366F1',
    this.imageUrl = '',
    this.sortOrder = 0,
    this.isCustom = true,
    this.productCount = 0,
    this.profitPercentage,
  });

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryItemModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'category_rounded',
      color: json['color']?.toString() ?? '#6366F1',
      imageUrl: json['imageUrl']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isCustom: json['isCustom'] == true,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      profitPercentage: (json['profitPercentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'color': color,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'isCustom': isCustom,
      'productCount': productCount,
      'profitPercentage': profitPercentage,
    };
  }

  Color get displayColor {
    try {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF0284C7);
  }

  IconData get displayIcon {
    switch (icon.toLowerCase()) {
      case 'sports_esports_rounded':
      case 'games':
      case 'game':
        return Icons.sports_esports_rounded;
      case 'gamepad_rounded':
        return Icons.gamepad_rounded;
      case 'casino_rounded':
        return Icons.casino_rounded;
      case 'emoji_events_rounded':
        return Icons.emoji_events_rounded;
      case 'credit_card_rounded':
      case 'cards':
        return Icons.credit_card_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'account_balance_wallet_rounded':
      case 'payment':
        return Icons.account_balance_wallet_rounded;
      case 'monetization_on_rounded':
        return Icons.monetization_on_rounded;
      case 'currency_exchange_rounded':
        return Icons.currency_exchange_rounded;
      case 'payments_rounded':
        return Icons.payments_rounded;
      case 'forum_rounded':
      case 'apps':
      case 'chat':
        return Icons.forum_rounded;
      case 'chat_bubble_rounded':
        return Icons.chat_bubble_rounded;
      case 'share_rounded':
      case 'social':
        return Icons.share_rounded;
      case 'groups_rounded':
        return Icons.groups_rounded;
      case 'thumb_up_rounded':
        return Icons.thumb_up_rounded;
      case 'subscriptions_rounded':
      case 'subscriptions':
      case 'tv':
        return Icons.subscriptions_rounded;
      case 'live_tv_rounded':
        return Icons.live_tv_rounded;
      case 'movie_rounded':
        return Icons.movie_rounded;
      case 'music_note_rounded':
        return Icons.music_note_rounded;
      case 'dialpad_rounded':
      case 'numbers':
      case 'phone':
        return Icons.dialpad_rounded;
      case 'phone_iphone_rounded':
        return Icons.phone_iphone_rounded;
      case 'sim_card_rounded':
        return Icons.sim_card_rounded;
      case 'wifi_rounded':
        return Icons.wifi_rounded;
      case 'language_rounded':
        return Icons.language_rounded;
      case 'shopping_bag_rounded':
      case 'shop':
        return Icons.shopping_bag_rounded;
      case 'shopping_cart_rounded':
        return Icons.shopping_cart_rounded;
      case 'local_offer_rounded':
      case 'offer':
        return Icons.local_offer_rounded;
      case 'loyalty_rounded':
        return Icons.loyalty_rounded;
      case 'star_rounded':
      case 'star':
        return Icons.star_rounded;
      case 'workspace_premium_rounded':
        return Icons.workspace_premium_rounded;
      case 'bolt_rounded':
        return Icons.bolt_rounded;
      case 'local_fire_department_rounded':
        return Icons.local_fire_department_rounded;
      case 'security_rounded':
        return Icons.security_rounded;
      case 'vpn_key_rounded':
        return Icons.vpn_key_rounded;
      case 'laptop_mac_rounded':
        return Icons.laptop_mac_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
