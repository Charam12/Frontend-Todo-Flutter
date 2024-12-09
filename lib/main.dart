import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> with SingleTickerProviderStateMixin {
  List<dynamic> todoList = [];
  bool isLoading = false;
  bool isTopButtonVisible = false;
  int offset = 0;
  final int limit = 10;
  String currentStatus = 'TODO';
  TabController? _tabController;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchTodoList(currentStatus, offset, limit);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (!isLoading) {
          fetchTodoList(currentStatus, offset, limit);
        }
      }

      if (_scrollController.offset > 300) {
        setState(() {
          isTopButtonVisible = true;
        });
      } else {
        setState(() {
          isTopButtonVisible = false;
        });
      }
    });
  }

  Future<void> fetchTodoList(String status, int offsetInput, int limit) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        'https://todo-list-api-mfchjooefq-as.a.run.app/todo-list?status=$status&offset=$offsetInput&limit=$limit&sortBy=createdAt&isAsc=true');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        offset += 1;
        if (data is Map) {
          setState(() {
            todoList.addAll(data['tasks']);
            isLoading = false;
          });
        }
      } else {
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, List<dynamic>> groupByDate(List<dynamic> todos) {
    Map<String, List<dynamic>> grouped = {};
    for (var todo in todos) {
      String formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(todo['createdAt']));
      if (grouped[formattedDate] == null) {
        grouped[formattedDate] = [];
      }
      grouped[formattedDate]?.add(todo);
    }
    return grouped;
  }

  

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<dynamic>> groupedTodos = groupByDate(todoList);

    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'TODO'),
            Tab(text: 'DOING'),
            Tab(text: 'DONE'),
          ],
          onTap: (index) {
            setState(() {
              currentStatus = ['TODO', 'DOING', 'DONE'][index];
              todoList.clear();
              offset = 0;
              fetchTodoList(currentStatus, offset, limit);
            });
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: groupedTodos.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < groupedTodos.length) {
                  String dateKey = groupedTodos.keys.elementAt(index);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          dateKey,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...groupedTodos[dateKey]!.map((todo) {
                        int todoIndex = groupedTodos[dateKey]!.indexOf(todo);
                        return ListTile(
                          title: Text(todo['title']),
                          subtitle: Text(todo['description']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(DateFormat('HH:mm').format(DateTime.parse(todo['createdAt']))),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                      setState(() {
                                        todoList.removeAt(index);

                                        groupedTodos[dateKey]?.removeAt(index);

                                        if (groupedTodos[dateKey]?.isEmpty ?? false) {
                                          groupedTodos.remove(dateKey);
                                        }
                                      });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                } else if (isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                return SizedBox.shrink();
              },
            ),
          ),

          if (isTopButtonVisible)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _scrollToTop,
                child: Icon(Icons.arrow_upward),
              ),
            ),
        ],
      ),
    );
  }
}
