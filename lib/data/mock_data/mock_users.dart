import 'package:fe/data/enums/login_provider.dart';
import 'package:fe/data/enums/user_role.dart';
import 'package:fe/data/enums/user_status.dart';
import 'package:fe/data/models/user/user.dart';

/// Danh bạ người dùng giả dùng cho **chế độ DEMO** (`DEMO_MODE=true`).
///
/// Mọi mock service khác đều lấy user từ đây để id/tên/email luôn khớp nhau
/// (ví dụ: chủ nhóm gia đình phải trùng id với user đang đăng nhập thì UI mới
/// hiện đúng quyền chủ nhóm).
///
/// **Muốn đổi dữ liệu demo?** Sửa các getter trong class này:
/// - [demoEmail] / [demoPassword] / [demoOtp]: thông tin đăng nhập demo.
/// - [demoUser]: hồ sơ của chính người đang dùng app.
/// - [members]: những người xuất hiện trong nhóm gia đình.
/// - [invitables]: người chưa vào nhóm, dùng cho lời mời/đề nghị tham gia.
class MockUsers {
  const MockUsers._();

  // ---------- Tài khoản đăng nhập demo ----------

  /// Email của tài khoản demo (so sánh không phân biệt hoa thường).
  static const String demoEmail = 'demo@healthmate.vn';

  /// Mật khẩu của tài khoản demo.
  static const String demoPassword = 'demo1234';

  /// Mã OTP cố định trong demo (mọi luồng xác thực đều nhận mã này).
  static const String demoOtp = '123456';

  // ---------- Id người dùng ----------

  static const String demoUserId = 'demo-user-0001';
  static const String hoaId = 'demo-user-0002';
  static const String hungId = 'demo-user-0003';
  static const String minhAnhId = 'demo-user-0004';
  static const String baoLongId = 'demo-user-0005';
  static const String thuMaiId = 'demo-user-0006';
  static const String quocDatId = 'demo-user-0007';
  static const String thanhLanId = 'demo-user-0008';

  /// Thời điểm gốc để mọi mốc thời gian "tương đối" so với hiện tại.
  static DateTime get _now => DateTime.now();

  static User _build({
    required String id,
    required String email,
    required String name,
    String? phone,
    String? gender,
    String? birthday,
    double? weight,
    double? height,
    String? bloodGroup,
    String? address,
    List<String> allergies = const [],
    int createdDaysAgo = 200,
    LoginProvider provider = LoginProvider.email,
  }) {
    final now = _now;
    return User(
      id: id,
      email: email,
      name: name,
      picture: null,
      role: UserRole.user,
      status: UserStatus.verified,
      provider: provider,
      googleId: provider == LoginProvider.google ? 'google-$id' : null,
      passwordHash: null,
      phone: phone,
      address: address,
      gender: gender,
      birthday: birthday,
      weight: weight,
      height: height,
      bloodGroup: bloodGroup,
      timezone: 'Asia/Ho_Chi_Minh',
      allergies: allergies,
      createdAt: now.subtract(Duration(days: createdDaysAgo)),
      updatedAt: now.subtract(const Duration(hours: 3)),
    );
  }

  /// Hồ sơ của người đang đăng nhập trong demo.
  static User get demoUser => _build(
    id: demoUserId,
    email: demoEmail,
    name: 'Nguyễn Văn Minh',
    phone: '0901 234 567',
    gender: 'male',
    birthday: '1988-04-12',
    weight: 68.5,
    height: 172.0,
    bloodGroup: 'O+',
    address: '12 Nguyễn Trãi, Thanh Xuân, Hà Nội',
    allergies: const ['Hải sản', 'Penicillin'],
    createdDaysAgo: 420,
  );

  /// Vợ — thành viên nhóm "Gia đình nhà mình".
  static User get hoa => _build(
    id: hoaId,
    email: 'hoa.tran@healthmate.vn',
    name: 'Trần Thị Hoa',
    phone: '0902 345 678',
    gender: 'female',
    birthday: '1990-09-02',
    weight: 55.0,
    height: 160.0,
    bloodGroup: 'A+',
    address: '12 Nguyễn Trãi, Thanh Xuân, Hà Nội',
    createdDaysAgo: 380,
  );

  /// Bố — chủ nhóm "Ông bà & các cháu".
  static User get hung => _build(
    id: hungId,
    email: 'hung.nguyen@healthmate.vn',
    name: 'Nguyễn Văn Hùng',
    phone: '0903 456 789',
    gender: 'male',
    birthday: '1958-01-20',
    weight: 66.0,
    height: 168.0,
    bloodGroup: 'B+',
    address: '45 Lê Lợi, Hà Đông, Hà Nội',
    allergies: const ['Aspirin'],
    createdDaysAgo: 365,
  );

  /// Con gái.
  static User get minhAnh => _build(
    id: minhAnhId,
    email: 'minhanh.nguyen@healthmate.vn',
    name: 'Nguyễn Minh Anh',
    phone: '0904 567 890',
    gender: 'female',
    birthday: '2010-06-15',
    weight: 42.0,
    height: 150.0,
    bloodGroup: 'O+',
    createdDaysAgo: 300,
  );

  /// Em trai.
  static User get baoLong => _build(
    id: baoLongId,
    email: 'baolong.nguyen@healthmate.vn',
    name: 'Nguyễn Bảo Long',
    phone: '0905 678 901',
    gender: 'male',
    birthday: '1995-11-30',
    weight: 70.0,
    height: 175.0,
    bloodGroup: 'AB+',
    createdDaysAgo: 260,
  );

  /// Chị gái — người gửi lời mời đang chờ user demo xử lý.
  static User get thuMai => _build(
    id: thuMaiId,
    email: 'thumai.le@healthmate.vn',
    name: 'Lê Thị Thu Mai',
    phone: '0906 789 012',
    gender: 'female',
    birthday: '1985-03-08',
    weight: 57.0,
    height: 162.0,
    bloodGroup: 'A+',
    createdDaysAgo: 240,
    provider: LoginProvider.google,
  );

  /// Người đã được user demo mời, đang chờ phản hồi.
  static User get quocDat => _build(
    id: quocDatId,
    email: 'quocdat.pham@healthmate.vn',
    name: 'Phạm Quốc Đạt',
    phone: '0907 890 123',
    gender: 'male',
    birthday: '1992-07-19',
    weight: 72.0,
    height: 176.0,
    bloodGroup: 'O-',
    createdDaysAgo: 120,
  );

  /// Người đã đồng ý lời mời, đang chờ chủ nhóm duyệt.
  static User get thanhLan => _build(
    id: thanhLanId,
    email: 'thanhlan.vu@healthmate.vn',
    name: 'Vũ Thị Thanh Lan',
    phone: '0908 901 234',
    gender: 'female',
    birthday: '1993-12-05',
    weight: 53.0,
    height: 158.0,
    bloodGroup: 'B-',
    createdDaysAgo: 90,
  );

  /// Những người đã ở trong nhóm gia đình của user demo.
  static List<User> get members => [hoa, hung, minhAnh, baoLong, thuMai];

  /// Những người chưa vào nhóm — dùng cho tìm kiếm/mời thành viên.
  static List<User> get invitables => [quocDat, thanhLan];

  /// Toàn bộ danh bạ demo (dùng cho `UserService.listUsers`).
  static List<User> get all => [demoUser, ...members, ...invitables];

  /// Tra cứu user theo id; trả về [demoUser] nếu không tìm thấy để UI không vỡ.
  static User byId(String id) {
    for (final u in all) {
      if (u.id == id) return u;
    }
    return demoUser;
  }
}
