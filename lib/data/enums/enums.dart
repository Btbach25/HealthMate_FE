/// Barrel export cho toàn bộ enum của tầng data.
///
/// Dùng khi một file cần nhiều enum cùng lúc:
/// `import 'package:fe/data/enums/enums.dart';`
/// thay vì import lẻ từng file. Import lẻ vẫn hợp lệ và được ưu tiên khi chỉ
/// cần một enum.
///
/// Thêm enum mới vào thư mục này thì nhớ export thêm ở đây.
library;

export 'package:fe/data/enums/group_member_role.dart';
export 'package:fe/data/enums/group_member_status.dart';
export 'package:fe/data/enums/login_provider.dart';
export 'package:fe/data/enums/metric_status.dart';
export 'package:fe/data/enums/metric_type.dart';
export 'package:fe/data/enums/metric_type_extension.dart';
export 'package:fe/data/enums/notification_type.dart';
export 'package:fe/data/enums/relationship_type.dart';
export 'package:fe/data/enums/user_role.dart';
export 'package:fe/data/enums/user_status.dart';
