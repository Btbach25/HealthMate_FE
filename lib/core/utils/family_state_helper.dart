import 'package:fe/presentation/family/bloc/family_bloc.dart';

/// Quy đổi `FamilyState` → "màn hình Gia đình nên vẽ gì lúc này".
///
/// Gom về một chỗ để mọi widget con của tab Gia đình cùng dựa trên một quy
/// tắc, thay vì mỗi chỗ tự viết một chuỗi if-else khác nhau.
///
/// Thứ tự kiểm tra ở phía gọi phải là loading → lỗi → nội dung:
///
/// ```dart
/// if (FamilyStateHelper.shouldShowLoading(state)) return const LoadingWidget();
/// if (FamilyStateHelper.shouldShowErrorScreen(state)) return ErrorDisplayWidget(...);
/// if (FamilyStateHelper.shouldShowContent(state)) return _buildContent(state);
/// ```
class FamilyStateHelper {
  /// Chỉ hiện loading toàn màn ở lần tải đầu tiên.
  ///
  /// `FamilyStatus.loading` của các lần tải lại CỐ Ý không tính ở đây: lúc đó
  /// đã có dữ liệu cũ trên màn, thay bằng vòng quay sẽ làm màn hình nhấp nháy.
  static bool shouldShowLoading(FamilyState state) {
    return state.status == FamilyStatus.initial;
  }

  /// Chỉ chiếm cả màn bằng lỗi khi lỗi VÀ không có gì để hiển thị.
  ///
  /// Lỗi mà vẫn còn dữ liệu cũ thì giữ nội dung và báo lỗi bằng toast /
  /// inline message, đỡ mất ngữ cảnh của người dùng.
  static bool shouldShowErrorScreen(FamilyState state) {
    return state.status == FamilyStatus.error &&
        state.summary.groups.isEmpty &&
        state.incomingInvitations.isEmpty &&
        state.outgoingInvitations.isEmpty;
  }

  /// Có dữ liệu để vẽ, hoặc đang ở một status "bình thường".
  ///
  /// Danh sách status bên dưới cần được bổ sung mỗi khi thêm giá trị mới vào
  /// `FamilyStatus` — quên thì màn hình sẽ trắng ngay sau thao tác đó.
  static bool shouldShowContent(FamilyState state) {
    if (state.summary.groups.isNotEmpty ||
        state.incomingInvitations.isNotEmpty ||
        state.outgoingInvitations.isNotEmpty) {
      return true;
    }

    final contentStates = {
      FamilyStatus.loaded,
      FamilyStatus.creatingGroup,
      FamilyStatus.groupCreated,
      FamilyStatus.groupDetailsLoaded,
      FamilyStatus.memberInvited,
      FamilyStatus.memberRemoved,
      FamilyStatus.groupUpdated,
      FamilyStatus.ownershipTransferred,
      FamilyStatus.groupLeft,
      FamilyStatus.invitationsLoaded,
      FamilyStatus.invitationAccepted,
      FamilyStatus.invitationDeclined,
      FamilyStatus.loading,
    };

    return contentStates.contains(state.status);
  }
}
