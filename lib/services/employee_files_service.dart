import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeFileItem {
  final String fileId;
  final String fileType;
  final String fileUrl;
  final String? uploadDate;

  EmployeeFileItem({
    required this.fileId,
    required this.fileType,
    required this.fileUrl,
    this.uploadDate,
  });

  factory EmployeeFileItem.fromJson(Map<String, dynamic> json) {
    return EmployeeFileItem(
      fileId: json['file_id']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      uploadDate: json['upload_date']?.toString(),
    );
  }
}

class EmployeeFilesService {
  static String buildEmployeeFileUrl(String fileUrl) {
    final trimmed = fileUrl.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final normalized = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '${AppConfig.apiBaseUrl}/uploads/$normalized';
  }

  static Future<bool> openEmployeeFile(String fileUrl) async {
    final url = buildEmployeeFileUrl(fileUrl);
    if (url.isEmpty) return false;

    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<List<EmployeeFileItem>> listMyFiles() async {
    final token = await AuthStorage.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/files/employee-files'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => EmployeeFileItem.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load files: ${response.statusCode}');
    }
  }

  static Future<String?> uploadFile({
    required String fileType,
    void Function(String fileName)? onFileName,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) return null;
    final result = await FilePicker.platform.pickFiles(withReadStream: true);
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;

    // Notify caller of file name
    if (onFileName != null) {
      onFileName(file.name);
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/files/upload/employee-file'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['file_type'] = fileType;
    if (file.readStream != null) {
      request.files.add(http.MultipartFile(
        'file',
        file.readStream!,
        file.size,
        filename: file.name,
      ));
    } else if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));
    } else {
      return null;
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['file_url']?.toString();
    }
    return null;
  }
}
