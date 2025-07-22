import 'package:flutter/material.dart';
import 'package:maebanjumpen/model/member.dart';

class MemberProvider with ChangeNotifier {
  Member? _currentUser;

  Member? get currentUser => _currentUser;

  void setUser(Member user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateBalance(double newBalance) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(balance: newBalance);
      notifyListeners();
    }
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}