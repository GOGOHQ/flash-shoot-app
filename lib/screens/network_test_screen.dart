import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../config/api_config.dart';

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({super.key});

  @override
  State<NetworkTestScreen> createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  String _testResult = '';
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网络连接测试'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '网络配置信息',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('主 URL: ${ApiConfig.baseUrl}'),
                    Text('备用 URL: ${ApiConfig.backupBaseUrl}'),
                    const SizedBox(height: 8),
                    const Text(
                      '请确保您的后端服务器正在运行',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isTesting ? null : _testNetworkConnection,
              child: _isTesting 
                ? const CircularProgressIndicator()
                : const Text('测试网络连接'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '测试结果',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testResult.isEmpty ? '点击上方按钮开始测试' : _testResult,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testNetworkConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = '开始网络连接测试...\n';
    });

    try {
      // 测试主 URL
      _addTestResult('测试主 URL: ${ApiConfig.baseUrl}');
      await _testUrl(ApiConfig.baseUrl);
      
      // 测试备用 URL
      _addTestResult('\n测试备用 URL: ${ApiConfig.backupBaseUrl}');
      await _testUrl(ApiConfig.backupBaseUrl);
      
      // 测试具体 API 端点
      _addTestResult('\n测试搜索 API 端点...');
      await _testApiEndpoint('/api/baidu-maps/search-places?q=测试&limit=1');
      
      _addTestResult('\n✅ 网络连接测试完成！');
    } catch (e) {
      _addTestResult('❌ 测试过程中发生错误: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testUrl(String baseUrl) async {
    try {
      final uri = Uri.parse(baseUrl);
      final socket = await Socket.connect(uri.host, uri.port, timeout: const Duration(seconds: 5));
      await socket.close();
      _addTestResult('✅ 连接成功');
    } catch (e) {
      _addTestResult('❌ 连接失败: $e');
    }
  }

  Future<void> _testApiEndpoint(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final socket = await Socket.connect(uri.host, uri.port, timeout: const Duration(seconds: 5));
      await socket.close();
      _addTestResult('✅ API 端点可访问');
    } catch (e) {
      _addTestResult('❌ API 端点测试失败: $e');
    }
  }

  void _addTestResult(String result) {
    setState(() {
      _testResult += result + '\n';
    });
  }
}
