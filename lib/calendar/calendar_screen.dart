import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Map<String, List<Protest>> _protests = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadProtests();
  }

  void _loadProtests() {
    FirebaseFirestore.instance.collection('kalendar').snapshots().listen((snapshot) {
      setState(() {
        _protests.clear();
        for (var doc in snapshot.docs) {
          var data = doc.data();
          String protestDate = data['date']; // Format: 'YYYY-MM-DD'
          if (!_protests.containsKey(protestDate)) {
            _protests[protestDate] = [];
          }
          _protests[protestDate]!.add(Protest(
            title: data['title'],
            description: data['description'],
            id: doc.id,
            highlight: data['highlight'] ?? false, // Dodato
          ));
        }
      });
    });
  }

  List<Protest> _getProtestsForDay(DateTime day) {
    String dayKey = day.toIso8601String().split("T")[0];
    return _protests[dayKey] ?? [];
  }

  List<Widget> _buildAllProtestsList() {
    List<MapEntry<String, List<Protest>>> sortedEntries = _protests.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedEntries.expand((entry) {
      return entry.value.map((protest) {
        return ListTile(
          title: Text(protest.title, style: TextStyle(color: Colors.white)),
          subtitle: Text(
            '${protest.description}\nDatum: ${_simpleReformatDate(entry.key)}',
            style: TextStyle(color: Colors.white70),
          ),
          onTap: () => null,
        );
      });
    }).toList();
  }

  void _showProtestDetails(Protest protest) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Detalji protesta', style: TextStyle(color: Colors.white)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(' ${protest.title}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 8),
              Text(' ${protest.description}', style: TextStyle(color: Colors.white70)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Zatvori', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String _simpleReformatDate(String dateStr) {
    List<String> parts = dateStr.split('-'); // [YYYY, MM, DD]
    if (parts.length != 3) return dateStr;
    return '${parts[2]}-${parts[1]}-${parts[0]}'; // DD-MM-YYYY
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 01, 01),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => false,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              List<Protest> protests = _getProtestsForDay(selectedDay);
              if (protests.isNotEmpty) {
                for (var protest in protests) {
                  _showProtestDetails(protest);
                }
              }
            },
            eventLoader: _getProtestsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white70),
              outsideTextStyle: TextStyle(color: Colors.grey),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                String dateKey = date.toIso8601String().split("T")[0];
                List<Protest> protestsForDate = _protests[dateKey] ?? [];

                bool shouldHighlight = protestsForDate.any((p) => p.highlight);

                if (shouldHighlight) {
                  return Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },

            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Svi nadolazeći protesti:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
                ..._buildAllProtestsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Protest {
  final String title;
  final String description;
  final String id;
  final bool highlight; // Dodato

  Protest({
    required this.title,
    required this.description,
    required this.id,
    required this.highlight,
  });
}
