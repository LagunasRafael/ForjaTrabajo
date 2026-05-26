export 'auth_state.dart';
export 'auth_notifier.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'auth_notifier.dart';

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());
