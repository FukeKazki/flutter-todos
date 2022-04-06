import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_todo_sample/todo.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// widgetに固有のkeyを渡す必要がある
final addTodoKey = UniqueKey();
final activeFilterKey = UniqueKey();
final completedFilterKey = UniqueKey();
final allFilterKey = UniqueKey();

// ref -> Providerで管理してるstateへのref
final todoListProvider = StateNotifierProvider<TodoList, List<Todo>>((ref) {
  return TodoList(const [
    Todo(description: 'あは', id: 'ua'),
    Todo(description: 'ぽえ', id: 'dfs'),
    Todo(description: 'にゃん', id: 'fsdf'),
  ]);
});

enum TodoListFilter {
  all,
  active,
  completed,
}

// !completedをfilterしてlengthを返す
final uncompletedTodosCount = Provider<int>((ref) {
  return ref.watch(todoListProvider).where((todo) => !todo.completed).length;
});

// filterの状態をstateにする。初期値 all(すべて見る)
final todoListFilter = StateProvider((_) => TodoListFilter.all);

// filterが変更されたときにtodoをfilterする
final filterdTodo = Provider<List>((ref) {
  final filter = ref.watch(todoListFilter);
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoListFilter.completed:
      return todos.where((todo) => todo.completed).toList();
    case TodoListFilter.active:
      return todos.where((todo) => !todo.completed).toList();
    case TodoListFilter.all:
      return todos;
  }
});

void main() {
  // ProviderのRootを設定
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

// hooksを使ってrevierpodにアクセスできるコンポーネント
class Home extends HookConsumerWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filterdTodo);
    final newTodoController = useTextEditingController();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            children: [
              const Title(),
              TextField(
                key: addTodoKey,
                controller: newTodoController,
                decoration: const InputDecoration(
                  labelText: 'What needs to be done?',
                ),
                onSubmitted: (value) {
                  // readは変更検知必要ないのでnotifierが必要
                  // readは呼び出し。watchは反映の検知
                  ref.read(todoListProvider.notifier).add(value);
                  // テキストフィールドをクリアする
                  newTodoController.clear();
                },
              ),
              const SizedBox(height: 42),
              if (todos.isNotEmpty)
                const Divider(
                  height: 0,
                ),
              // for文で配列の要素を返すためにスプレッド使ってる
              // mapでもいいけど可読性が。。。
              for (var i = 0; i < todos.length; ++i) ...[
                if (i > 0)
                  const Divider(
                    height: 0,
                  ),
                Dismissible(
                  key: ValueKey(todos[i].id),
                  // スライドしたときの挙動
                  onDismissed: (_) {
                    ref.read(todoListProvider.notifier).remove(todos[i]);
                  },
                  child: ProviderScope(
                    // 通常はTodoItemからTodoListが見えちゃう=>よくない
                    // todos[i]だけを見れるようにオーバーライドする
                    // 一番近い親のoverrideが優先される。
                    overrides: [
                      _currentTodo.overrideWithValue(todos[i]),
                    ],
                    child: const TodoItem(),
                  ),
                )
              ]
            ]),
      ),
    );
  }
}

// Titleコンポーネント
class Title extends StatelessWidget {
  const Title({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'todos',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color.fromARGB(38, 47, 47, 247),
        fontSize: 100,
        fontWeight: FontWeight.w100,
        fontFamily: 'Helvetica Neue',
      ),
    );
  }
}

final _currentTodo = Provider<Todo>((ref) => throw UnimplementedError());

class TodoItem extends HookConsumerWidget {
  const TodoItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(_currentTodo);
    final itemFocusNode = useFocusNode();
    final itemIsFocused = useIsFocused(itemFocusNode);

    final textEditingController = useTextEditingController();
    final textFieldFocusNode = useFocusNode();

    return Material(
        color: Colors.white,
        elevation: 6,
        child: Focus(
          focusNode: itemFocusNode,
          onFocusChange: (focused) {
            if (focused) {
              textEditingController.text = todo.description;
            } else {
              ref
                  .read(todoListProvider.notifier)
                  .edit(id: todo.id, description: textEditingController.text);
            }
          },
          child: ListTile(
            onTap: () {
              itemFocusNode.requestFocus();
              textFieldFocusNode.requestFocus();
            },
            leading: Checkbox(
              value: todo.completed,
              onChanged: (value) =>
                  ref.read(todoListProvider.notifier).toggle(todo.id),
            ),
            title: itemIsFocused
                ? TextField(
                    autofocus: true,
                    focusNode: textFieldFocusNode,
                    controller: textEditingController,
                  )
                : Text(todo.description),
          ),
        ));
  }
}

// 自作hooks
bool useIsFocused(FocusNode node) {
  final isFocused = useState(node.hasFocus);

  useEffect(() {
    void listener() {
      isFocused.value = node.hasFocus;
    }

    node.addListener(listener);
    return () => node.removeListener(listener);
  }, [node]);

  return isFocused.value;
}
