import 'package:bloc/bloc.dart';
import 'package:dayflow/injection.dart';
import 'package:dayflow/presentation/features/bottom_nav_layout_manager.dart/widgets/BottomNavLayoutResources/page_stack.dart';
import 'package:injectable/injectable.dart';

@injectable
class BottomNavbarCubit extends Cubit<int> {
  BottomNavbarCubit() : super(-1);
  final myPageStack = getIt<ReorderToFrontPageStack>();

  bottomNavBarPushJourneyTab() {
    myPageStack.push(1);
    emit(-1);
    emit(1);
  }

  bottomNavBarPushHomeTab() {
    myPageStack.push(0);
    emit(-1);
    emit(1);
  }

  bottomNavBarPushSharingTab() {
    myPageStack.push(2);
    emit(-1);
    emit(1);
  }
}
