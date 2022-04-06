import 'package:flutter/foundation.dart' show immutable; // immutableのみを使用
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// 変更不可なデータクラスを作成
@immutable
class Todo {
  const Todo({
    required this.description,
    required this.id,
    this.completed = false,
  });

  final String id;
  final String description;
  final bool completed;

  @override
  String toString() {
    return 'Todo(description: $description, completed:: $completed)';
  }
}

class TodoList extends StateNotifier<List<Todo>> {
  // TodoList({}) のときはインスタンスつくるときにTodoList({list: list})みたいにする必要がある
  // TodoList([])のときはTodoList(list, )のように命名がいらないが順番が重要になる
  TodoList([List<Todo>? initialTodos]) : super(initialTodos ?? []); // ? はnull許容

  void add(String description) {
    // stateは List<Todo>
    state = [
      ...state,
      Todo(
        id: _uuid.v4(),
        description: description,
      ),
    ];
  }

  void remove(Todo target) {
    state = state.where((todo) => todo.id != target.id).toList();
  }

  // descriptionだけ書き換え
  void edit({required String id, required String description}) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          Todo(
            id: todo.id,
            completed: todo.completed,
            description: description,
          )
        else
          todo,
    ];
  }

  // completedの書き換え
  void toggle(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          Todo(
            id: todo.id,
            completed: !todo.completed,
            description: todo.description,
          )
        else
          todo,
    ];
  }
}
