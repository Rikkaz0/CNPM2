import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:personal.health.manager/util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:personal.health.manager/screens/add_data_screen.dart';
import 'chart_screen.dart';

class HealthTrackerScreen extends StatefulWidget {
  @override
  _HealthTrackerScreenState createState() => _HealthTrackerScreenState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTHORIZED,
  AUTH_NOT_GRANTED,
  DATA_ADDED,
  DATA_DELETED,
  DATA_NOT_ADDED,
  DATA_NOT_DELETED,
  STEPS_READY,
  HEALTH_CONNECT_STATUS,
  PERMISSIONS_REVOKING,
  PERMISSIONS_REVOKED,
  PERMISSIONS_NOT_REVOKED,
}

class _HealthTrackerScreenState extends State<HealthTrackerScreen> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  int _nofSteps = 0;
  List<RecordingMethod> recordingMethodsToFilter = [];
  // All types available depending on platform (iOS ot Android).
  List<HealthDataType> get types => (Platform.isAndroid)
      ? dataTypesAndroid
      : (Platform.isIOS)
          ? dataTypesIOS
          : [];


  List<HealthDataAccess> get permissions => types
      .map((type) =>
          // can only request READ permissions to the following list of types on iOS
          [
            HealthDataType.WALKING_HEART_RATE,
            HealthDataType.ELECTROCARDIOGRAM,
            HealthDataType.HIGH_HEART_RATE_EVENT,
            HealthDataType.LOW_HEART_RATE_EVENT,
            HealthDataType.IRREGULAR_HEART_RATE_EVENT,
            HealthDataType.EXERCISE_TIME,
          ].contains(type)
              ? HealthDataAccess.READ
              : HealthDataAccess.READ_WRITE)
      .toList();

  @override
  void initState() {
    // configure the health plugin before use and check the Health Connect status
    Health().configure();
    Health().getHealthConnectSdkStatus();

    super.initState();
  }

  /// Install Google Health Connect on this phone.
  Future<void> installHealthConnect() async =>
      await Health().installHealthConnect();

  /// Authorize, i.e. get permissions to access relevant health data.
  Future<void> authorize() async {
    
    await Permission.activityRecognition.request();
    await Permission.location.request();

    // Check if we have health permissions
    bool? hasPermissions =
        await Health().hasPermissions(types, permissions: permissions);

    // hasPermissions = false because the hasPermission cannot disclose if WRITE access exists.
    // Hence, we have to request with WRITE as well.
    hasPermissions = false;

    bool authorized = false;
    if (!hasPermissions) {
      // requesting access to the data types before reading them
      try {
        authorized = await Health()
            .requestAuthorization(types, permissions: permissions);
      } catch (error) {
        debugPrint("Exception in authorize: $error");
      }
    }

    setState(() => _state =
        (authorized) ? AppState.AUTHORIZED : AppState.AUTH_NOT_GRANTED);
  }

  /// Gets the Health Connect status on Android.
  Future<void> getHealthConnectSdkStatus() async {
    assert(Platform.isAndroid, "This is only available on Android");

    final status = await Health().getHealthConnectSdkStatus();

    setState(() {
      _contentHealthConnectStatus =
          Text('Health Connect Status: ${status?.name.toUpperCase()}');
      _state = AppState.HEALTH_CONNECT_STATUS;
    });
  }

  /// Fetch data points from the health plugin and show them in the app.
  Future<void> fetchData() async {
    setState(() => _state = AppState.FETCHING_DATA);

    // get data within the last 24 hours
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    // Clear old data points
    _healthDataList.clear();

    try {
      // fetch health data
      List<HealthDataPoint> healthData = await Health().getHealthDataFromTypes(
        types: types,
        startTime: yesterday,
        endTime: now,
        recordingMethodsToFilter: recordingMethodsToFilter,
      );

      debugPrint('Total number of data points: ${healthData.length}. '
          '${healthData.length > 100 ? 'Only showing the first 100.' : ''}');

      // sort the data points by date
      healthData.sort((a, b) => b.dateTo.compareTo(a.dateTo));

      // save all the new data points (only the first 100)
      _healthDataList.addAll(
          (healthData.length < 100) ? healthData : healthData.sublist(0, 100));
    } catch (error) {
      debugPrint("Exception in getHealthDataFromTypes: $error");
    }

    // filter out duplicates
    _healthDataList = Health().removeDuplicates(_healthDataList);

    _healthDataList.forEach((data) => debugPrint(toJsonString(data)));

    // update the UI to display the results
    setState(() {
      _state = _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
    });
  }

  
Future<void> addData({
  required HealthDataType type,
  required dynamic value,
  required DateTime startTime,
  DateTime? endTime,
  RecordingMethod recordingMethod = RecordingMethod.manual,
}) async {
  await addDataToHealthConnect(
    type: type,
    value: value,
    startTime: startTime,
    endTime: endTime,
    recordingMethod: recordingMethod,
  );
}

Future<void> addDataToHealthConnect({
  required HealthDataType type,
  required dynamic value,
  required DateTime startTime,
  DateTime? endTime,
  RecordingMethod recordingMethod = RecordingMethod.manual,
}) async {
  bool success = true;

  try {
    switch (type) {
      case HealthDataType.HEIGHT:
        success &= await Health().writeHealthData(
              value: value as double,
              type: type,
              startTime: startTime,
              endTime: endTime,
              recordingMethod: recordingMethod,
            );
        break;
      case HealthDataType.WEIGHT:
        success &= await Health().writeHealthData(
              value: value as double,
              type: type,
              startTime: startTime,
              endTime: endTime,
              recordingMethod: recordingMethod,
            );
        break;
      case HealthDataType.HEART_RATE:
        success &= await Health().writeHealthData(
              value: value as double,
              type: type,
              startTime: startTime,
              endTime: endTime,
              recordingMethod: recordingMethod,
            );
        break;
      // Thêm các trường hợp khác tùy thuộc vào HealthDataType bạn muốn hỗ trợ
      default:
        throw UnsupportedError('Unsupported HealthDataType: $type');
    }

    setState(() {
      _state = success ? AppState.DATA_ADDED : AppState.DATA_NOT_ADDED;
    });
  } catch (e) {
    setState(() {
      _state = AppState.DATA_NOT_ADDED;
    });
    print('Error writing health data: $e');
  }
}


  /// Delete some random health data.
  Future<void> deleteData() async {
    final now = DateTime.now();
    final earlier = now.subtract(const Duration(hours: 24));

    bool success = true;
    for (HealthDataType type in types) {
      success &= await Health().delete(
        type: type,
        startTime: earlier,
        endTime: now,
      );
    }

    setState(() {
      _state = success ? AppState.DATA_DELETED : AppState.DATA_NOT_DELETED;
    });
  }

  /// Fetch steps from the health plugin and show them in the app.
  Future<void> fetchStepData() async {
    int? steps;

    // get steps for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool stepsPermission =
        await Health().hasPermissions([HealthDataType.STEPS]) ?? false;
    if (!stepsPermission) {
      stepsPermission =
          await Health().requestAuthorization([HealthDataType.STEPS]);
    }

    if (stepsPermission) {
      try {
        steps = await Health().getTotalStepsInInterval(midnight, now,
            includeManualEntry:
                !recordingMethodsToFilter.contains(RecordingMethod.manual));
      } catch (error) {
        debugPrint("Exception in getTotalStepsInInterval: $error");
      }

      debugPrint('Total number of steps: $steps');

      setState(() {
        _nofSteps = (steps == null) ? 0 : steps;
        _state = (steps == null) ? AppState.NO_DATA : AppState.STEPS_READY;
      });
    } else {
      debugPrint("Authorization not granted - error in authorization");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  /// Revoke access to health data. Note, this only has an effect on Android.
  Future<void> revokeAccess() async {
    setState(() => _state = AppState.PERMISSIONS_REVOKING);

    bool success = false;

    try {
      await Health().revokePermissions();
      success = true;
    } catch (error) {
      debugPrint("Exception in revokeAccess: $error");
    }

    setState(() {
      _state = success
          ? AppState.PERMISSIONS_REVOKED
          : AppState.PERMISSIONS_NOT_REVOKED;
    });
  }

  // UI building below

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Health Tracker'),
        ),
        body: Column(
          children: [
            Wrap(
              spacing: 10,
              children: [
                if (Platform.isAndroid)
                  TextButton(
                      onPressed: getHealthConnectSdkStatus,
                      style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                      child: const Text("Check Health Connect Status",
                          style: TextStyle(color: Colors.white))),
                if (Platform.isAndroid &&
                    Health().healthConnectSdkStatus !=
                        HealthConnectSdkStatus.sdkAvailable)
                  TextButton(
                      onPressed: installHealthConnect,
                      style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                      child: const Text("Install Health Connect",
                          style: TextStyle(color: Colors.white))),
                if (Platform.isIOS ||
                    Platform.isAndroid &&
                        Health().healthConnectSdkStatus ==
                            HealthConnectSdkStatus.sdkAvailable)
                  Wrap(spacing: 10, children: [
                    TextButton(
                        onPressed: authorize,
                        style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Authenticate",
                            style: TextStyle(color: Colors.white))),
                    TextButton(
                        onPressed: fetchData,
                        style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Fetch Data",
                            style: TextStyle(color: Colors.white))),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddDataPage(
                                onDataAdded: (HealthDataType type, dynamic value, DateTime startTime, DateTime? endTime, RecordingMethod method) {
                                  addData(
                                    type: type,
                                    value: value,
                                    startTime: startTime,
                                    endTime: endTime,
                                    recordingMethod: method,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.blue),
                        ),
                        child: const Text(
                          "Add Data",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChartPage(healthDataList: _healthDataList),
                          ),
                        );
                      },
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.blue),
                      ),
                      child: const Text(
                        "Chart",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                

                    TextButton(
                        onPressed: deleteData,
                        style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Delete Data",
                            style: TextStyle(color: Colors.white))),
                    TextButton(
                        onPressed: fetchStepData,
                        style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Fetch Step Data",
                            style: TextStyle(color: Colors.white))),
                    TextButton(
                        onPressed: revokeAccess,
                        style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Revoke Access",
                            style: TextStyle(color: Colors.white))),
                  ]),
              ],
            ),
            const Divider(thickness: 3),
            if (_state == AppState.DATA_READY) _dataFiltration,
            if (_state == AppState.STEPS_READY) _stepsFiltration,
            Expanded(child: Center(child: _content))
          ],
        ),
      ),
    );
  }

  Widget get _dataFiltration => Column(
        children: [
          Wrap(
            children: [
              for (final method in Platform.isAndroid
                  ? [
                      RecordingMethod.manual,
                      RecordingMethod.automatic,
                      RecordingMethod.active,
                      RecordingMethod.unknown,
                    ]
                  : [
                      RecordingMethod.automatic,
                      RecordingMethod.manual,
                    ])
                SizedBox(
                  width: 150,
                  child: CheckboxListTile(
                    title: Text(
                        '${method.name[0].toUpperCase()}${method.name.substring(1)} entries'),
                    value: !recordingMethodsToFilter.contains(method),
                    onChanged: (value) {
                      setState(() {
                        if (value!) {
                          recordingMethodsToFilter.remove(method);
                        } else {
                          recordingMethodsToFilter.add(method);
                        }
                        fetchData();
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              // Add other entries here if needed
            ],
          ),
          const Divider(thickness: 3),
        ],
      );

  Widget get _stepsFiltration => Column(
        children: [
          Wrap(
            children: [
              for (final method in [
                RecordingMethod.manual,
              ])
                SizedBox(
                  width: 150,
                  child: CheckboxListTile(
                    title: Text(
                        '${method.name[0].toUpperCase()}${method.name.substring(1)} entries'),
                    value: !recordingMethodsToFilter.contains(method),
                    onChanged: (value) {
                      setState(() {
                        if (value!) {
                          recordingMethodsToFilter.remove(method);
                        } else {
                          recordingMethodsToFilter.add(method);
                        }
                        fetchStepData();
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              // Add other entries here if needed
            ],
          ),
          const Divider(thickness: 3),
        ],
      );

  Widget get _permissionsRevoking => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              padding: const EdgeInsets.all(20),
              child: const CircularProgressIndicator(
                strokeWidth: 10,
              )),
          const Text('Revoking permissions...')
        ],
      );

  Widget get _permissionsRevoked => const Text('Permissions revoked.');

  Widget get _permissionsNotRevoked =>
      const Text('Failed to revoke permissions');

  Widget get _contentFetchingData => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              padding: const EdgeInsets.all(20),
              child: const CircularProgressIndicator(
                strokeWidth: 10,
              )),
          const Text('Fetching data...')
        ],
      );

  Widget get _contentDataReady => ListView.builder(
      itemCount: _healthDataList.length,
      itemBuilder: (_, index) {
        // filter out manual entires if not wanted
        if (recordingMethodsToFilter
            .contains(_healthDataList[index].recordingMethod)) {
          return Container();
        }

        HealthDataPoint p = _healthDataList[index];
        if (p.value is AudiogramHealthValue) {
          return ListTile(
            title: Text("${p.typeString}: ${p.value}"),
            trailing: Text('${p.unitString}'),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}\n${p.recordingMethod}'),
          );
        }
        if (p.value is WorkoutHealthValue) {
          return ListTile(
            title: Text(
                "${p.typeString}: ${(p.value as WorkoutHealthValue).totalEnergyBurned} ${(p.value as WorkoutHealthValue).totalEnergyBurnedUnit?.name}"),
            trailing: Text(
                '${(p.value as WorkoutHealthValue).workoutActivityType.name}'),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}\n${p.recordingMethod}'),
          );
        }
        if (p.value is NutritionHealthValue) {
          return ListTile(
            title: Text(
                "${p.typeString} ${(p.value as NutritionHealthValue).mealType}: ${(p.value as NutritionHealthValue).name}"),
            trailing:
                Text('${(p.value as NutritionHealthValue).calories} kcal'),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}\n${p.recordingMethod}'),
          );
        }
        return ListTile(
          title: Text("${p.typeString}: ${p.value}"),
          trailing: Text('${p.unitString}'),
          subtitle: Text('${p.dateFrom} - ${p.dateTo}\n${p.recordingMethod}'),
        );
      });

  Widget _contentNoData = const Text('No Data to show');

  Widget _contentNotFetched =
      const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text("Press 'Auth' to get permissions to access health data."),
    const Text("Press 'Fetch Dat' to get health data."),
    const Text("Press 'Add Data' to add some random health data."),
    const Text("Press 'Delete Data' to remove some random health data."),
  ]);

  Widget _authorized = const Text('Authorization granted!');

  Widget _authorizationNotGranted = const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('Authorization not given.'),
      const Text(
          'For Google Health Connect please check if you have added the right permissions and services to the manifest file.'),
      const Text('For Apple Health check your permissions in Apple Health.'),
    ],
  );

  Widget _contentHealthConnectStatus = const Text(
      'No status, click getHealthConnectSdkStatus to get the status.');

  Widget _dataAdded = const Text('Data points inserted successfully.');

  Widget _dataDeleted = const Text('Data points deleted successfully.');

  Widget get _stepsFetched => Text('Total number of steps: $_nofSteps.');

  Widget _dataNotAdded =
      const Text('Failed to add data.\nDo you have permissions to add data?');

  Widget _dataNotDeleted = const Text('Failed to delete data');

  Widget get _content => switch (_state) {
        AppState.DATA_READY => _contentDataReady,
        AppState.DATA_NOT_FETCHED => _contentNotFetched,
        AppState.FETCHING_DATA => _contentFetchingData,
        AppState.NO_DATA => _contentNoData,
        AppState.AUTHORIZED => _authorized,
        AppState.AUTH_NOT_GRANTED => _authorizationNotGranted,
        AppState.DATA_ADDED => _dataAdded,
        AppState.DATA_DELETED => _dataDeleted,
        AppState.DATA_NOT_ADDED => _dataNotAdded,
        AppState.DATA_NOT_DELETED => _dataNotDeleted,
        AppState.STEPS_READY => _stepsFetched,
        AppState.HEALTH_CONNECT_STATUS => _contentHealthConnectStatus,
        AppState.PERMISSIONS_REVOKING => _permissionsRevoking,
        AppState.PERMISSIONS_REVOKED => _permissionsRevoked,
        AppState.PERMISSIONS_NOT_REVOKED => _permissionsNotRevoked,
      };
}