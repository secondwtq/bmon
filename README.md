
## 使用方法

`bmon` 是一个监视 bilibili 直播状态的工具，它会每隔一段时间检查指定直播间的状态，侦测到状态发生改变时触发特定动作。

要实现直播开始时下载视频流，需要结合下载工具，推荐 [you-get](https://github.com/soimort/you-get)。下载得到的视频流直接播放效果并不好，建议使用 ffmpeg 转码处理后储存。这部分流程由 `bmon_download.sh` 实现。

以下命令会监视 `ROOM_ID` 直播间，直播开始时在新建的 tmux pane 中下载，并在结束后转码为 MP4 (HEVC+AAC) 文件：

```shell
./bmon.exe ROOM_ID -e "tmux split-pane -h \"./bmon_download.sh -r ROOM_ID\""
```
