#!/usr/bin/bash
pushd "$(cd "$(dirname "$0")" && pwd)" > /dev/null
source ec2.config.sh

# ---------- EC2操作関数 ----------
desc() {
  AWS_PROFILE="$profile" aws ec2 describe-instances \
    --region "$1" --instance-ids "$2" \
    --query 'Reservations[].Instances[].State.Name'
}

start() {
  AWS_PROFILE="$profile" aws ec2 start-instances \
    --region "$1" --instance-ids "$2"
}

stop() {
  AWS_PROFILE="$profile" aws ec2 stop-instances \
    --region "$1" --instance-ids "$2"
}

# ---------- メイン処理 ----------
key="${1:-0}"
flag="${2:-0}"

[ -n "$(get_config "$key")" ] && target="$key"
[ -z "$target" ] && { select target in "${targets[@]}"; do break; done; }
if [ -n "$target" ]; then
  IFS='|' read -r region instance_id < <(get_config "$target")
  echo "対象リージョン: ${region}"
  echo "対象インスタンス: ${instance_id}"
  if [ "$flag" -eq "0" ]; then
    printf '操作を選んでください (0:状態確認, 1:開始, 2:停止): '
    read -r flag
  fi
  # 引数にかかわらずまずインスタンスの状態をみる
  echo "現在の状態:"
  desc "$region" "$instance_id"
  if [ $? -ne 0 ]; then
    # 状態がみられなかったらログイン
    echo "セッションが無効のためログインします..."
    aws sso login --profile $profile
    desc "$region" "$instance_id"
  fi
  case "$flag" in
    1)
      echo "インスタンスを開始します:"
      start "$region" "$instance_id" ;;
    2)
      echo "インスタンスを停止します:"
      stop "$region" "$instance_id" ;;
  esac
fi
popd > /dev/null
