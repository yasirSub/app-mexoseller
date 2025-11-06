// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../constants/endpoints.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: colorScheme.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                isScrollable: true,
                labelColor: colorScheme.onSurface,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                dividerColor: Colors.transparent,
                indicatorPadding: const EdgeInsets.all(4),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.primary.withOpacity(0.16),
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Shipped'),
                  Tab(text: 'Delivered'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OrderListTab(status: 'all'),
                _OrderListTab(status: 'pending'),
                _OrderListTab(status: 'shipped'),
                _OrderListTab(status: 'delivered'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderListTab extends StatefulWidget {
  final String status;
  const _OrderListTab({required this.status});

  @override
  State<_OrderListTab> createState() => _OrderListTabState();
}

class _OrderListTabState extends State<_OrderListTab> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final url = widget.status == 'all'
          ? Endpoints.orders
          : '${Endpoints.orders}?status=${widget.status}';
      final response = await ApiService.get(url);
      // Log response for debugging
      debugPrint('GET $url -> ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> orders = (data['data'] ?? []) as List<dynamic>;
          if (mounted) {
            setState(() {
              _orders = orders;
              _isLoading = false;
            });
          }
        } else {
          // Backend returned success=false with a message
          final msg = (data['message'] ?? 'Failed to load orders').toString();
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
          }
        }
      } else {
        // Non-200 status
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load orders: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'].toString();
    final customer = order['customer_name'] ?? 'Unknown';
    final amount = order['total_amount'] ?? 0;
    final status = order['status'] ?? 'pending';
    final itemsCount = order['items_count'] ?? 0;

    final statusDisplay = status[0].toUpperCase() + status.substring(1);
    Color statusColor = status == 'pending'
        ? Colors.orange
        : status == 'shipped'
        ? Colors.blue
        : Colors.green;
    final textTheme = Theme.of(context).textTheme;
    final primaryTextColor = textTheme.bodyLarge?.color ?? Colors.black;
    final secondaryTextColor =
        textTheme.bodyMedium?.color ?? Colors.black.withOpacity(0.7);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        collapsedIconColor: statusColor,
        iconColor: statusColor,
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        backgroundColor: Theme.of(context).colorScheme.surface,
        collapsedBackgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withOpacity(0.9),
        leading: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.shopping_bag, color: statusColor),
        ),
        title: Text(
          'Order #$orderId',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        subtitle: Text(
          '$customer • $itemsCount items',
          style: textTheme.bodyMedium?.copyWith(color: secondaryTextColor),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹$amount',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryTextColor,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusDisplay,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer: $customer',
                  style: textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                Text(
                  'Items: $itemsCount',
                  style: textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                Text(
                  'Total: ₹$amount',
                  style: textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                if (order['shipping_address'] != null)
                  Text(
                    'Address: ${order['shipping_address']}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('View details coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View'),
                      ),
                    ),
                    if (status == 'pending') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shipOrder(orderId),
                          icon: const Icon(Icons.local_shipping),
                          label: const Text('Ship'),
                        ),
                      ),
                    ],
                    if (status == 'shipped') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deliverOrder(orderId),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Deliver'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shipOrder(String orderId) async {
    try {
      final response = await ApiService.post(
        '${Endpoints.orders}/$orderId/ship',
        {},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as shipped')),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to ship order: $e')));
      }
    }
  }

  Future<void> _deliverOrder(String orderId) async {
    try {
      final response = await ApiService.post(
        '${Endpoints.orders}/$orderId/deliver',
        {},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as delivered')),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to deliver order: $e')));
      }
    }
  }
}
