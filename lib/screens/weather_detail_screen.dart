import 'package:flutter/material.dart';
import '../models/api_models.dart';

class WeatherDetailScreen extends StatelessWidget {
  final WeatherResponse weatherData;
  final Location location;

  const WeatherDetailScreen({
    super.key,
    required this.weatherData,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('天气预报'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWeatherCard(),
            const SizedBox(height: 16),
            _buildLocationInfo(),
            const SizedBox(height: 16),
            _buildLifeIndexes(),
            const SizedBox(height: 16),
            _buildWeatherDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final now = weatherData.result.now;
    final location = weatherData.result.location;
    
    debugPrint('天气详情页面 - 当前天气数据:');
    debugPrint('  温度: ${now.temp}°C');
    debugPrint('  天气: ${now.text}');
    debugPrint('  湿度: ${now.rh}%');
    debugPrint('  风速: ${now.windClass}');
    debugPrint('  风向: ${now.windDir}');
    debugPrint('  体感温度: ${now.feelsLike}°C');
    debugPrint('  空气质量: ${now.aqi}');

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      now.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${location.city} ${location.name}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Icon(
                  _getWeatherIcon(now.text),
                  size: 64,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${now.temp}°',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'C',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo('湿度', '${now.rh}%', Icons.water_drop),
                _buildWeatherInfo('风速', now.windClass, Icons.air),
                _buildWeatherInfo('风向', now.windDir, Icons.compass_calibration),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前位置',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '纬度: ${location.lat.toStringAsFixed(4)}, 经度: ${location.lng.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifeIndexes() {
    final indexes = weatherData.result.indexes;
    
    if (indexes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '生活指数',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...indexes.take(6).map((index) => _buildIndexItem(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexItem(WeatherIndex index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              index.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              index.brief,
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    final forecasts = weatherData.result.forecasts;
    
    debugPrint('天气详情页面 - 预报数据: $forecasts');
    debugPrint('天气详情页面 - 预报数据长度: ${forecasts.length}');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '未来天气预报',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (forecasts.isNotEmpty)
              ...forecasts.take(7).map((day) => _buildForecastItem(day))
            else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '暂无预报数据',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(WeatherForecast day) {
    final date = day.date;
    final weather = day.text;
    final high = day.high;
    final low = day.low;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(_getWeatherIcon(weather), size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(weather),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$low° - $high°',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String weather) {
    if (weather.contains('晴')) return Icons.wb_sunny;
    if (weather.contains('多云')) return Icons.cloud;
    if (weather.contains('阴')) return Icons.cloud_queue;
    if (weather.contains('雨')) return Icons.umbrella;
    if (weather.contains('雪')) return Icons.ac_unit;
    if (weather.contains('雾')) return Icons.cloud;
    return Icons.wb_sunny;
  }
}
