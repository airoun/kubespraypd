########################
# print help msg
# Arguments:
#   None
# Returns:
#   None
#########################
print_help_message() {
  printf "使用localrepo设置离线kubespray依赖的源\n"
  printf "./localrepo.sh {COMMAND}\n"
  printf "\n"

  printf "%-10s %-20s\n" "命令" "描述"
  printf "%-10s %-20s\n" "download" "下载离线数据, 需要连接互联网"
  printf "%-10s %-20s\n" "install" "安装离线软件源"
  printf "%-10s %-20s\n" "其他字符" "打印这个帮助页"

  printf "\n"

  printf "e.g.\n  ./localrepo.sh download\n  ./localrepo.sh install\n"

}