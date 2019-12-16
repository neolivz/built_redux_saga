import 'package:built_redux_saga/built_redux_saga.dart';
import 'package:built_redux/built_redux.dart';
import 'actions.dart';
import 'state.dart';

main() async {

  Reducer<AppState, AppStateBuilder, dynamic> createAppReducer() {
    return (new ReducerBuilder<AppState, AppStateBuilder>()
    ).build();
  }


  Store<AppState, AppStateBuilder, AppActions> store = new Store(
      createAppReducer(), // build returns a reducer function
      new AppState(),
      new AppActions(),
      middleware:
      <Middleware<AppState, AppStateBuilder, AppActions>>[
        createSagaMiddleware<AppState, AppStateBuilder, AppActions>([]
          ..add(testSaga())
          ..add(delaySaga())
          ..add(logSaga())
        ),
      ]
  );

  while(true) {
    await Future.delayed(Duration(seconds: 1));
    store.actions.test("This is a test");
  }


}

Iterable<Runnable> logSaga() sync* {
  while (true) {
    Result result = Result();
    yield takeEverything(result);
    print("log ${result.value}");
  }
}

Iterable<Runnable> delaySaga() sync* {
  while (true) {
    Result<Action<String>> result = Result();
    yield take(AppActionsNames.test, result);
    print("taken ${result.value}");

    print("before delay test");
    yield delay(Duration(seconds: 1));
    print("after1 delay test");
    yield delay(Duration(seconds: 1));
    print("after2 delay test");
  }
}


Iterable<Runnable> testSaga() sync* {
  Result<Action<String>> result = Result();
  yield take(AppActionsNames.test, result);
  print("in test taken ${result.value}");
  
  yield all([reportedSaga(test1(), "test1 task"), reportedSaga(test2(), "test2 task")]);
  
  print("out test");
}


Iterable<Runnable> reportedSaga(Iterable<Runnable> saga, String label) sync* {

  print("start reported task ${label}");
  try {
    yield put(AppActionsNames.startTask, "before ${label}");
    yield* saga;
    yield put(AppActionsNames.endTask, "after ${label}");
  } catch(e) {
    yield put(AppActionsNames.error, e);
  }

  print("end reported task ${label}");
}

Iterable<Runnable> test1() sync* {

  print("entering test1");

    try {
      Result<Action<String>> action = Result();
      yield take(AppActionsNames.test,action);
      yield put(AppActionsNames.log, "dispatching: ${action.value}");

      Result<String> something = Result();
      yield call(getSomething(), something);
      yield put(AppActionsNames.log, "value: ${something.value}");

      Result result = Result();
      yield call(raiseError(), result);
      if(result.hasError) {
        yield put(AppActionsNames.log, "error: ${result.error}");
      }
    } catch (e) {
      yield put(AppActionsNames.error, e);
    }


  print("exiting test1");
}

Iterable<Runnable> test2() sync* {

  print("entering test2");
  yield take(AppActionsNames.test);
  for(int i=0;i<4;i++) {
    yield put(AppActionsNames.log, "from_iterator:${i}");
  }


  Result<AppState> appState = Result();
  yield select<AppState>(appState);
  if(appState.value != null) {
    yield put(AppActionsNames.log, "state: ${appState.value}");
  }

  Result<AppActions> actions = Result();
  yield select<AppActions>(actions);
  if(actions.hasValue) {
    yield put(AppActionsNames.log, "action: ${actions.value}");
  }

  yield put(AppActionsNames.log, "exiting test2");
}

Future<String> getSomething() {
  return Future.delayed(Duration(seconds: 2), () => "This is a delayed API response");
}


Future raiseError() async {
  await Future.delayed(Duration(seconds: 2));
  throw "this is an error.";
}