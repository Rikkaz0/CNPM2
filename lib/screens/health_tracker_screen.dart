import 'package:flutter/material.dart';
import 'package:googleapis/fitness/v1.dart' as fitness;
import 'package:googleapis_auth/auth_io.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

final _scopes = [fitness.FitnessApi.fitnessActivityReadScope];

class HealthTrackerScreen extends StatefulWidget {
  @override
  _HealthTrackerScreenState createState() => _HealthTrackerScreenState();
}

class _HealthTrackerScreenState extends State<HealthTrackerScreen> {
  late fitness.FitnessApi _fitnessApi;
  String steps = 'N/A', heartRate = 'N/A', weight = 'N/A';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // Kiểm tra quyền truy cập
  Future<void> _requestPermissions() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _authenticateAndFetchData();
    }
  }

  // Mở URL để xác thực
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Không thể mở URL: $url';
    }
  }

  // Xác thực và lấy dữ liệu từ Google Fitness API
  Future<void> _authenticateAndFetchData() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      var client = await clientViaUserConsent(
        ClientId('792888586324-on246kh0pdelgvs6ctelvdghqn3hf0kd.apps.googleusercontent.com', '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'),
        _scopes,
        (url) {
          _launchURL(url); // Mở URL OAuth trong trình duyệt
        },
      );

      _fitnessApi = fitness.FitnessApi(client);

      // Lấy dữ liệu bước đi, nhịp tim và trọng lượng
      var stepsData = await _getStepsData();
      var heartRateData = await _getHeartRateData();
      var weightData = await _getWeightData();

      setState(() {
        steps = stepsData.toString();
        heartRate = heartRateData.toString();
        weight = weightData.toString();
      });
    } catch (e) {
      print("Lỗi: $e");
    }
  }

  // Lấy số bước đi từ Fitness API
  Future<int> _getStepsData() async {
    var dataset = await _fitnessApi.users.dataSources.datasets.get(
      'me',
      'derived:com.google.step_count.delta:com.google.android.gms:estimated_steps',
      'startTime-endTime',
    );
    return dataset.point?.first.value?.first.intVal ?? 0;
  }

  // Lấy nhịp tim từ Fitness API
  Future<int> _getHeartRateData() async {
    var dataset = await _fitnessApi.users.dataSources.datasets.get(
      'me',
      'derived:com.google.heart_rate.bpm:com.google.android.gms:heart_rate_bpm',
      'startTime-endTime',
    );
    return dataset.point?.first.value?.first.fpVal?.toInt() ?? 0;
  }

  // Lấy trọng lượng từ Fitness API
  Future<double> _getWeightData() async {
    var dataset = await _fitnessApi.users.dataSources.datasets.get(
      'me',
      'derived:com.google.weight:com.google.android.gms:body_weight',
      'startTime-endTime',
    );
    return dataset.point?.first.value?.first.fpVal ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Health Tracker")),
      body: Column(
        children: [
          Text('Steps: $steps'),
          Text('Heart Rate: $heartRate bpm'),
          Text('Weight: $weight kg'),
        ],
      ),
    );
  }
}
