// lib/chart_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:health/health.dart';

class ChartPage extends StatefulWidget {
  final List<HealthDataPoint> healthDataList;

  const ChartPage({Key? key, required this.healthDataList}) : super(key: key);

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  String _selectedChartType = 'Height';
  final List<String> chartTypes = ['Height', 'Weight', 'Heart Rate'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Data Charts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedChartType,
              items: chartTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedChartType = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    List<HealthDataPoint> filteredData = widget.healthDataList.where((data) {
      switch (_selectedChartType) {
        case 'Height':
          return data.type == HealthDataType.HEIGHT;
        case 'Weight':
          return data.type == HealthDataType.WEIGHT;
        case 'Heart Rate':
          return data.type == HealthDataType.HEART_RATE;
        default:
          return false;
      }
    }).toList();

    // Sắp xếp dữ liệu theo thời gian
    filteredData.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    // Tạo danh sách các điểm dữ liệu cho biểu đồ
    List<FlSpot> spots = [];
    for (int i = 0; i < filteredData.length; i++) {
      double yValue;
      if (filteredData[i].value is int) {
        yValue = (filteredData[i].value as int).toDouble();
      } else if (filteredData[i].value is double) {
        yValue = filteredData[i].value as double;
      } else {
        // Nếu giá trị không phải là int hoặc double, bỏ qua điểm này
        continue;
      }
      spots.add(FlSpot(i.toDouble(), yValue));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No data available for selected chart type.'));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= filteredData.length) return Container();
                DateTime date = filteredData[index].dateFrom;
                String formattedDate = DateFormat('MM/dd').format(date);
                return Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getInterval(),
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            color: Colors.blue,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: _getMinY(),
        maxY: _getMaxY(),
      ),
    );
  }

  double _getInterval() {
    // Xác định khoảng cách giữa các điểm trên trục Y dựa trên loại biểu đồ
    switch (_selectedChartType) {
      case 'Height':
        return 10;
      case 'Weight':
        return 5;
      case 'Heart Rate':
        return 20;
      default:
        return 10;
    }
  }

  double _getMinY() {
    // Tính giá trị Y nhỏ nhất cho biểu đồ
    double minY = double.infinity;
    for (var spot in _buildChartSpots()) {
      if (spot.y < minY) {
        minY = spot.y;
      }
    }
    return minY.isFinite ? minY - (_getInterval()) : 0;
  }

  double _getMaxY() {
    // Tính giá trị Y lớn nhất cho biểu đồ
    double maxY = double.negativeInfinity;
    for (var spot in _buildChartSpots()) {
      if (spot.y > maxY) {
        maxY = spot.y;
      }
    }
    return maxY.isFinite ? maxY + (_getInterval()) : 100;
  }

  List<FlSpot> _buildChartSpots() {
    List<HealthDataPoint> filteredData = widget.healthDataList.where((data) {
      switch (_selectedChartType) {
        case 'Height':
          return data.type == HealthDataType.HEIGHT;
        case 'Weight':
          return data.type == HealthDataType.WEIGHT;
        case 'Heart Rate':
          return data.type == HealthDataType.HEART_RATE;
        default:
          return false;
      }
    }).toList();

    filteredData.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    List<FlSpot> spots = [];
    for (int i = 0; i < filteredData.length; i++) {
      double yValue;
      if (filteredData[i].value is int) {
        yValue = (filteredData[i].value as int).toDouble();
      } else if (filteredData[i].value is double) {
        yValue = filteredData[i].value as double;
      } else {
        continue;
      }
      spots.add(FlSpot(i.toDouble(), yValue));
    }
    return spots;
  }
}
