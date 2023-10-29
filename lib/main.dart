import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('학교 급식 정보')),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 600) {
              // 대형 화면용 레이아웃
              return WideLayout();
            } else {
              // 일반 화면용 레이아웃
              return NarrowLayout();
            }
          },
        ),
      ),
    );
  }
}

class WideLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(),
        ),
        Expanded(
          flex: 2,
          child: MealInfo(),
        ),
        Expanded(
          flex: 1,
          child: Container(),
        ),
      ],
    );
  }
}

class NarrowLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MealInfo();
  }
}

class MealInfo extends StatefulWidget {
  _MealInfoState createState() => _MealInfoState();
}

class _MealInfoState extends State<MealInfo> {
  DateTime selectedDate = DateTime.now();
  String lunchInfo = '';
  String dinnerInfo = '';
  bool showLunchInfo = true; // 변수를 추가하여 어떤 정보를 보여줄지 결정

  Future<void> fetchMeals(DateTime date) async {
    var formattedDate = DateFormat('yyyyMMdd').format(date);
    bool dinnerExists = false; // dinnerExists 초기화

    final response = await http.get(Uri.parse(
        'https://open.neis.go.kr/hub/mealServiceDietInfo?KEY=d8f2dda2e17c4d2d96826001224f7491&Type=json&ATPT_OFCDC_SC_CODE=R10&SD_SCHUL_CODE=8750754&MLSV_YMD=$formattedDate'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['mealServiceDietInfo'] != null) {
        var meals = data['mealServiceDietInfo'][1]['row'];
        List<String> lunchList = [];
        List<String> dinnerList = [];

        for (var meal in meals) {
          if (meal['MLSV_YMD'] == formattedDate) {
            String cleanMealName = removeHtmlTags(meal['DDISH_NM']);
            if (meal['MMEAL_SC_NM'] == '중식') {
              lunchList.add(cleanMealName);
            } else if (meal['MMEAL_SC_NM'] == '석식') {
              dinnerList.add(cleanMealName);
              dinnerExists = true;
            }
          }
        }

        setState(() {
          lunchInfo = lunchList.join('\n');
          dinnerInfo = dinnerExists ? dinnerList.join('\n') : '석식 정보가 없습니다';
        });
      } else {
        setState(() {
          lunchInfo = '급식 정보가 없습니다.';
          dinnerInfo = '급식 정보가 없습니다.';
        });
      }
    } else {
      print('급식 정보를 불러오는 데 실패했습니다. 상태 코드:${response.statusCode}');

      setState(() {
        lunchInfo = '';
        dinnerInfo = '급식 정보를 불러오는데 실패했습니다. 상태 코드:${response.statusCode}';
      });
    }
  }

  String removeHtmlTags(String htmlText) {
    final RegExp regExp = RegExp('<[^>]*>', multiLine: true);
    return htmlText.replaceAll(regExp, '');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });

      fetchMeals(selectedDate);
    }
  }

  @override
  void initState() {
    super.initState();

    fetchMeals(selectedDate); // 현재 날짜의 급식 정보를 불러옴
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => _selectDate(context),
            child: Text(
              DateFormat('yyyy-MM-dd').format(selectedDate),
              style: TextStyle(fontSize: 24),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showLunchInfo = true;
                  });
                },
                child: Text('중식'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showLunchInfo = false;
                  });
                },
                child: Text('석식'),
              ),
            ],
          ),
          SizedBox(height: 20),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  showLunchInfo ? '중식 정보' : '석식 정보',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              Container(
                height: 150,
                padding: EdgeInsets.symmetric(vertical: 0.8),
                child: Text(
                  showLunchInfo ? lunchInfo : dinnerInfo,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
