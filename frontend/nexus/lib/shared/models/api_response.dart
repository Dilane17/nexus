/// Modèle standard de réponse API du backend NestJS.
/// Format : { success: bool, data: T, message: String }
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) dataFromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? dataFromJson(json['data']) : null,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
    };
  }
}

/// Réponse paginée standard du backend.
/// Format : { items, total, page, limit, totalPages }
class ApiPage<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const ApiPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ApiPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return ApiPage<T>(
      items: rawItems
          .map((item) => itemFromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? rawItems.length,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}
