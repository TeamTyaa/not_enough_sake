// TODO: クラス名コメント修正
// ============================================================
// 飲み会投稿データモデル
// ============================================================

enum PostStatus { open, confirmed, done, cancelled }

PostStatus postStatusFromString(String s) {
  switch (s) {
    case 'confirmed':
      return PostStatus.confirmed;
    case 'done':
      return PostStatus.done;
    case 'cancelled':
      return PostStatus.cancelled;
    default:
      return PostStatus.open;
  }
}

String postStatusToString(PostStatus s) {
  switch (s) {
    case PostStatus.confirmed:
      return 'confirmed';
    case PostStatus.done:
      return 'done';
    case PostStatus.cancelled:
      return 'cancelled';
    default:
      return 'open';
  }
}
