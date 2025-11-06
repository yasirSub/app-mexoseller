import 'package:flutter/material.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/orders/pages/orders_page.dart';
import '../features/products/pages/products_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/products/pages/categories_page.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _sellerName = 'Mexo Seller';

  final List<Widget> _pages = [
    const DashboardPage(),
    const ProductsPage(),
    const CategoriesPage(),
    const OrdersPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSellerName();
  }

  Future<void> _loadSellerName() async {
    try {
      final result = await ProfileService.getProfile();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _sellerName = result['data']['name'] ?? 'Mexo Seller';
        });
      }
    } catch (e) {
      // Keep default name on error
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return _sellerName; // Dashboard - show seller name
      case 1:
        return 'Products';
      case 2:
        return 'Categories';
      case 3:
        return 'Orders';
      case 4:
        return 'Profile';
      default:
        return 'Mexo Seller';
    }
  }

  Widget _buildThemeToggle() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.notifier,
      builder: (context, themeMode, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final currentIsDark =
            themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return GestureDetector(
          onTap: () {
            ThemeService.setMode(
              currentIsDark ? ThemeMode.light : ThemeMode.dark,
            );
          },
          child: Container(
            width: 44,
            height: 24,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: currentIsDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.3),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: currentIsDark
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  currentIsDark ? Icons.dark_mode : Icons.light_mode,
                  size: 12,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.notifier,
      builder: (context, themeMode, _) {
        final isDark =
            themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(92),
            // Custom curved app bar - fixed size for all tabs
            child: Container(
              height: 92,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
                child: Container(
                  padding: const EdgeInsets.only(top: 18, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.deepPurple.shade700
                        : colorScheme.primary,
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.deepPurple.shade700,
                              Colors.deepPurple.shade800,
                            ],
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.deepPurple.shade900.withOpacity(0.5)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isDark ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                _getAppBarTitle(),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  shadows: isDark
                                      ? [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                        if (_selectedIndex == 0) ...[
                          // Dark/Light mode toggle - only on dashboard
                          const SizedBox(width: 8),
                          _buildThemeToggle(),
                          // Notification icon - only on dashboard
                          IconButton(
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              shadows: isDark
                                  ? [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            tooltip: 'Notifications',
                            onPressed: () {},
                          ),
                        ],
                        if (_selectedIndex == 4) ...[
                          // Settings icon - only on profile
                          IconButton(
                            icon: Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                              shadows: isDark
                                  ? [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            tooltip: 'Settings',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/settings');
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? Colors.deepPurple.shade700 : colorScheme.primary,
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.shade700,
                        Colors.deepPurple.shade800,
                      ],
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.deepPurple.shade900.withOpacity(0.5)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isDark ? 12 : 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipPath(
              clipper: CurvedBottomBarClipper(),
              child: Container(
                padding: const EdgeInsets.only(
                  bottom: 8,
                  top: 8,
                  left: 8,
                  right: 8,
                ),
                child: Stack(
                  children: [
                    // Animated indicator for selected item
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left:
                          (_selectedIndex *
                              (MediaQuery.of(context).size.width / 5)) +
                          8,
                      top: 0,
                      child: Container(
                        width: (MediaQuery.of(context).size.width / 5) - 16,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    // Bottom Navigation Bar
                    BottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: (index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent,
                      selectedItemColor: Colors.white,
                      unselectedItemColor: isDark
                          ? Colors.white.withOpacity(0.85)
                          : Colors.white.withOpacity(0.7),
                      selectedFontSize: 11,
                      unselectedFontSize: 10,
                      selectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white,
                        shadows: isDark
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withOpacity(0.85)
                            : Colors.white.withOpacity(0.7),
                        shadows: isDark
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      elevation: 0,
                      showUnselectedLabels: true,
                      items: [
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.dashboard_outlined,
                            size: 24,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          activeIcon: Icon(
                            Icons.dashboard,
                            size: 26,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          label: 'Dashboard',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.inventory_2_outlined,
                            size: 24,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          activeIcon: Icon(
                            Icons.inventory_2,
                            size: 26,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          label: 'Products',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.category_outlined,
                            size: 24,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          activeIcon: Icon(
                            Icons.category,
                            size: 26,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          label: 'Categories',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.shopping_bag_outlined,
                            size: 24,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          activeIcon: Icon(
                            Icons.shopping_bag,
                            size: 26,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          label: 'Orders',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.person_outlined,
                            size: 24,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          activeIcon: Icon(
                            Icons.person,
                            size: 26,
                            shadows: isDark
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom clipper for elegant curved bottom navigation bar with curves on both sides
class CurvedBottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final topCurve = 22.0; // Depth of the curve on top (matching top bar)
    final sideCurveWidth = 30.0; // Width of the curve on each side

    // Start from bottom left
    path.moveTo(0, size.height);

    // Bottom line (straight across)
    path.lineTo(size.width, size.height);

    // Right side: straight line up to where curve starts
    path.lineTo(size.width, topCurve);

    // Top right curve (curved inward, matching top bar style)
    path.quadraticBezierTo(size.width, 0, size.width - sideCurveWidth, 0);

    // Top line (straight across the middle)
    path.lineTo(sideCurveWidth, 0);

    // Top left curve (curved inward, matching top bar style)
    path.quadraticBezierTo(0, 0, 0, topCurve);

    // Left side: straight line down to bottom
    path.lineTo(0, size.height);

    // Close path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
