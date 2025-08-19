import 'package:flutter/foundation.dart';
import 'package:maebanjumpen/model/member.dart';
import 'package:maebanjumpen/model/party_role.dart'; // ✅ Import class PartyRole

class MemberProvider with ChangeNotifier {
  // ✅ เปลี่ยนประเภทตัวแปรจาก Member เป็น PartyRole เพื่อให้ยืดหยุ่นมากขึ้น
  PartyRole? _currentUser;

  // ✅ เปลี่ยนประเภท getter จาก Member เป็น PartyRole
  PartyRole? get currentUser => _currentUser;

  // ✅ แก้ไขพารามิเตอร์ของเมธอดให้รับ PartyRole
  void setUser(PartyRole user) {
    _currentUser = user;
    notifyListeners();
  }

  // เมธอดสำหรับอัปเดตยอดเงินของผู้ใช้
  // 💡 ข้อควรระวัง: เมธอดนี้จะทำงานได้เฉพาะเมื่อ currentUser เป็นประเภท Member
  void updateBalance(double newBalance) {
    if (_currentUser != null && _currentUser is Member) {
      final memberUser = _currentUser as Member;
      _currentUser = memberUser.copyWith(balance: newBalance);
      notifyListeners();
    }
  }

  // เมธอดสำหรับล้างข้อมูลผู้ใช้เมื่อออกจากระบบ
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}