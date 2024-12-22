import 'package:flutter/material.dart';
import 'package:health/health.dart';

class AddDataPage extends StatefulWidget {
  final Function(HealthDataType, dynamic, DateTime, DateTime?, RecordingMethod) onDataAdded;

  const AddDataPage({Key? key, required this.onDataAdded}) : super(key: key);

  @override
  _AddDataPageState createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  final _formKey = GlobalKey<FormState>();

  HealthDataType? _selectedType;
  String _value = '';
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  RecordingMethod _recordingMethod = RecordingMethod.manual;

  // Danh sách các loại dữ liệu hỗ trợ
  final List<HealthDataType> _dataTypes = [
    HealthDataType.HEIGHT,
    HealthDataType.WEIGHT,
    HealthDataType.HEART_RATE,
    // Thêm các loại dữ liệu khác nếu cần
  ];

  // Hàm để hiển thị trình chọn ngày và giờ
  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : (_endTime ?? _startTime),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : (_endTime ?? _startTime)),
      );

      if (pickedTime != null) {
        setState(() {
          DateTime newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          if (isStart) {
            _startTime = newDateTime;
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng chọn loại dữ liệu')),
        );
        return;
      }

      _formKey.currentState!.save();

      dynamic parsedValue;
      try {
        switch (_selectedType) {
          case HealthDataType.HEIGHT:
            parsedValue = double.parse(_value);
            break;
          case HealthDataType.WEIGHT:
            parsedValue = double.parse(_value);
            break;
          case HealthDataType.HEART_RATE:
            parsedValue = double.parse(_value);
            break;
          // Thêm các loại dữ liệu khác và kiểu dữ liệu tương ứng
          default:
            parsedValue = _value;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giá trị nhập không hợp lệ')),
        );
        return;
      }

      // Gọi callback để truyền dữ liệu trở lại trang chính
      widget.onDataAdded(
        _selectedType!,
        parsedValue,
        _startTime,
        _endTime,
        _recordingMethod,
      );

      // Quay lại trang trước
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhập Dữ Liệu Sức Khỏe'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView( // Đảm bảo trang có thể cuộn nếu cần
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chọn loại dữ liệu
                DropdownButtonFormField<HealthDataType>(
                  decoration: InputDecoration(labelText: 'Loại Dữ Liệu'),
                  items: _dataTypes.map((HealthDataType type) {
                    return DropdownMenuItem<HealthDataType>(
                      value: type,
                      child: Text(type.toString().split('.').last.replaceAll('_', ' ')),
                    );
                  }).toList(),
                  onChanged: (HealthDataType? newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Vui lòng chọn loại dữ liệu' : null,
                ),
                SizedBox(height: 16.0),

                // Nhập giá trị dữ liệu
                TextFormField(
                  decoration: InputDecoration(labelText: 'Giá Trị'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập giá trị';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _value = value!;
                  },
                ),
                SizedBox(height: 16.0),

                // Chọn thời gian bắt đầu
                Row(
                  children: [
                    Expanded(
                      child: Text('Thời gian bắt đầu: ${_startTime.toLocal()}'),
                    ),
                    TextButton(
                      onPressed: () => _selectDateTime(context, true),
                      child: Text('Chọn'),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),

                // Chọn thời gian kết thúc (nếu cần)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _endTime != null
                            ? 'Thời gian kết thúc: ${_endTime!.toLocal()}'
                            : 'Chưa có thời gian kết thúc',
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectDateTime(context, false),
                      child: Text('Chọn'),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),

                // Chọn phương thức ghi
                DropdownButtonFormField<RecordingMethod>(
                  decoration: InputDecoration(labelText: 'Phương Thức Ghi'),
                  value: _recordingMethod,
                  items: RecordingMethod.values.map((RecordingMethod method) {
                    return DropdownMenuItem<RecordingMethod>(
                      value: method,
                      child: Text(method.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (RecordingMethod? newValue) {
                    setState(() {
                      _recordingMethod = newValue ?? RecordingMethod.manual;
                    });
                  },
                ),
                SizedBox(height: 24.0),

                // Nút submit
                Center(
                  child: ElevatedButton(
                    onPressed: _submitData,
                    child: Text('Thêm Dữ Liệu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
