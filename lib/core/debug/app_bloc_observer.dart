import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    print('Created ${bloc.toString()}');

    super.onCreate(bloc);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // print(change);
    print(
        '${bloc.toString()} previous state: ${change.currentState}, new current state: ${change.nextState}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    print(event);
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    print(transition);

    super.onTransition(bloc, transition);
  }

  @override
  void onClose(BlocBase bloc) {
    print('Closed ${bloc.toString()}');
    super.onClose(bloc);
  }
}
