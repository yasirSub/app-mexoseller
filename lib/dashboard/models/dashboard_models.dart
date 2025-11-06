class DashboardStats {
  final int totalOrders;
  final int totalProducts;
  final double totalRevenue;
  final int pendingOrders;
  final double todayRevenue;
  final List<OrderStatusCount> ordersByStatus;
  final List<TopProduct> topProducts;
  final List<RecentOrder> recentOrders;
  final List<MonthlyRevenue> monthlyRevenue;

  DashboardStats({
    required this.totalOrders,
    required this.totalProducts,
    required this.totalRevenue,
    required this.pendingOrders,
    required this.todayRevenue,
    required this.ordersByStatus,
    required this.topProducts,
    required this.recentOrders,
    required this.monthlyRevenue,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'] ?? {};
    final ordersByStatus = (json['orders_by_status'] as List<dynamic>? ?? [])
        .map((e) => OrderStatusCount.fromJson(e))
        .toList();
    final topProducts = (json['top_products'] as List<dynamic>? ?? [])
        .map((e) => TopProduct.fromJson(e))
        .toList();
    final recentOrders = (json['recent_orders'] as List<dynamic>? ?? [])
        .map((e) => RecentOrder.fromJson(e))
        .toList();
    final monthlyRevenue = (json['monthly_revenue'] as List<dynamic>? ?? [])
        .map((e) => MonthlyRevenue.fromJson(e))
        .toList();

    return DashboardStats(
      totalOrders: stats['total_orders'] ?? 0,
      totalProducts: stats['total_products'] ?? 0,
      totalRevenue: (stats['total_revenue'] ?? 0.0).toDouble(),
      pendingOrders: ordersByStatus
          .where((status) => status.status.toLowerCase() == 'pending')
          .fold(0, (sum, status) => sum + status.count),
      todayRevenue: 0.0, // This would need to be calculated separately
      ordersByStatus: ordersByStatus,
      topProducts: topProducts,
      recentOrders: recentOrders,
      monthlyRevenue: monthlyRevenue,
    );
  }
}

class OrderStatusCount {
  final String status;
  final int count;

  OrderStatusCount({required this.status, required this.count});

  factory OrderStatusCount.fromJson(Map<String, dynamic> json) {
    return OrderStatusCount(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class TopProduct {
  final int id;
  final String name;
  final int totalSold;
  final double totalRevenue;

  TopProduct({
    required this.id,
    required this.name,
    required this.totalSold,
    required this.totalRevenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      totalSold: json['total_sold'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0.0).toDouble(),
    );
  }
}

class RecentOrder {
  final int id;
  final double amount;
  final String status;
  final String createdAt;
  final List<OrderItem> items;

  RecentOrder({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    final items = (json['order_items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromJson(e))
        .toList();

    return RecentOrder(
      id: json['id'] ?? 0,
      amount: (json['total_amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      items: items,
    );
  }
}

class OrderItem {
  final int id;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      productName: json['product']?['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}

class MonthlyRevenue {
  final int month;
  final int year;
  final double revenue;

  MonthlyRevenue({
    required this.month,
    required this.year,
    required this.revenue,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
    );
  }
}
