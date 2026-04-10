// ============================================================
// 投稿ステータス定数
// ============================================================

enum PostStatus {
  open,
  confirmed,
  done,
  cancelled,
}

PostStatus? postStatusFromInt(int i) {
  switch (i) {
    case 0:
      return PostStatus.open;
    case 1:
      return PostStatus.confirmed;
    case 2:
      return PostStatus.done;
    case 9:
      return PostStatus.cancelled;
  }
  return null;
}

int postStatusToInt(PostStatus e) {
  switch (e) {
    case PostStatus.open:
      return 0;
    case PostStatus.confirmed:
      return 1;
    case PostStatus.done:
      return 2;
    case PostStatus.cancelled:
      return 9;
  }
}
