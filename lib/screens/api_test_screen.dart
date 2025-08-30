import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final ApiService _apiService = ApiService();
  String _testResult = '';
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 连接测试'),
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
                      'API 配置信息',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('基础 URL: ${ApiConfig.baseUrl}'),
                    Text('备用 URL: ${ApiConfig.backupBaseUrl}'),
                    Text('超时设置: ${ApiConfig.connectionTimeout.inSeconds}秒'),
                    const SizedBox(height: 8),
                    const Text(
                      '注意：请确保您的后端服务器正在运行，并且设备能够访问上述 IP 地址',
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
              onPressed: _isTesting ? null : _testApiConnection,
              child: _isTesting 
                ? const CircularProgressIndicator()
                : const Text('测试 API 连接'),
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isTesting ? null : _testSearchPlaces,
              child: const Text('测试地图搜索功能'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = '开始测试...\n';
    });

    try {
      // 测试小红书 API
      _addTestResult('测试小红书热门帖子 API...');
      try {
        final xhsResponse = await _apiService.getXhsHot(limit: 1);
        _addTestResult('✅ 小红书 API 连接成功，获取到 ${xhsResponse.data.length} 个帖子');
      } catch (e) {
        _addTestResult('❌ 小红书 API 连接失败: $e');
      }

      // 测试百度地图地理编码 API
      _addTestResult('\n测试百度地图地理编码 API...');
      try {
        final geocodeResponse = await _apiService.geocode(address: '北京市朝阳区');
        _addTestResult('✅ 百度地图地理编码 API 连接成功');
      } catch (e) {
        _addTestResult('❌ 百度地图地理编码 API 连接失败: $e');
      }

      // 测试百度地图搜索 API
      _addTestResult('\n测试百度地图搜索 API...');
      try {
        final searchResponse = await _apiService.searchPlaces(
          q: '美食',
          location: '39.9042,116.4074',
          radius: 1000,
          limit: 1,
        );
        _addTestResult('✅ 百度地图搜索 API 连接成功，找到 ${searchResponse.results.length} 个结果');
      } catch (e) {
        _addTestResult('❌ 百度地图搜索 API 连接失败: $e');
      }

      _addTestResult('\n测试完成！');
    } catch (e) {
      _addTestResult('❌ 测试过程中发生错误: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testSearchPlaces() async {
    setState(() {
      _isTesting = true;
      _testResult = '开始测试地图搜索功能...\n';
    });

    try {
      _addTestResult('测试搜索"美食"...');
      final searchResponse = await _apiService.searchPlaces(
        q: '美食',
        location: '39.9042,116.4074',
        radius: 2000,
        limit: 5,
      );
      
      _addTestResult('✅ 搜索成功，找到 ${searchResponse.results.length} 个结果');
      
      if (searchResponse.results.isNotEmpty) {
        final firstPlace = searchResponse.results.first;
        _addTestResult('第一个结果: ${firstPlace.name}');
        _addTestResult('地址: ${firstPlace.address}');
        _addTestResult('评分: ${firstPlace.detailInfo.overallRating}');
        _addTestResult('距离: ${firstPlace.detailInfo.distance}m');
      }
      
    } catch (e) {
      _addTestResult('❌ 搜索测试失败: $e');
      _addTestResult('\n可能的原因:');
      _addTestResult('1. 后端服务器未启动');
      _addTestResult('2. 网络连接问题');
      _addTestResult('3. IP 地址配置错误');
      _addTestResult('4. 防火墙阻止连接');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _addTestResult(String result) {
    setState(() {
      _testResult += result + '\n';
    });
  }
}
