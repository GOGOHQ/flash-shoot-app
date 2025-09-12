import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "消息",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.people_alt_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.group_add_outlined),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top icon section
            _buildTopIcons(),
            // Separator
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            // Message list
            _buildMessageList(),
          ],
        ),
      ),
      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: "机位",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: "相机",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: "消息",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "我",
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTopIconItem(Icons.favorite_border, "赞和收藏"),
          _buildTopIconItem(Icons.person_add_alt_outlined, "新增关注"),
          _buildTopIconItem(Icons.comment_outlined, "评论和@"),
        ],
      ),
    );
  }

  Widget _buildTopIconItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(icon, size: 25, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMessageList() {
    return Column(
      children: [
        _buildMessageItem(
          avatar: "assets/user/消息/1.png",
          name: "water",
          message: "[笔记] 就是这个动作，解决你肩...",
          time: "09:09",
        ),
        _buildMessageItem(
          avatar: "assets/user/消息/2.png",
          name: "秋山",
          message: "所有舞蹈爱好者集结！瓜分一...",
          time: "星期五",
          unreadCount: 1,
        ),
        _buildMessageItem(
          avatar: "assets/user/消息/3.png",
          name: "陌生人消息",
          message: "姐妹，请问你这张图具体机位是在哪里呀！",
          time: "08-17",
        ),
        _buildMessageItem(
          avatar: "assets/user/消息/4.png",
          name: "Xuem.L",
          message: "好的哈",
          time: "08-16",
        ),
        _buildMessageItem(
          avatar: "assets/user/消息/5.png",
          name: "Share 成煜 z",
          message: "提前两天就可以",
          time: "08-15",
        ),
        _buildMessageItem(
          avatar: "assets/user/消息/6.png",
          name: "芸芸",
          message: "哈喽",
          time: "08-12",
        ),
        _buildMessageItem(
          avatar: "assets/user/消息/7.png",
          name: "三岁",
          message: "hello我也周五去云南",
          time: "08-12",
        ),
        _buildMessageItem(
          avatar: "assets/user/消息/8.png",
          name: "南风和煦",
          message: "姐妹~",
          time: "08-12",
        ),
        _buildMessageItem(
          avatar: "assets/user/消息/9.png",
          name: "西红柿",
          message: "[笔记] 男朋友和闺蜜为了这个吵起来了...",
          time: "08-12",
        ),
        _buildMessageItem(
          avatar: "assets/user/消息/10.png",
          name: "薯愿条",
          message: "滴滴",
          time: "08-12",
        ),
      ],
    );
  }

  Widget _buildMessageItem({
    required String avatar,
    required String name,
    required String message,
    required String time,
    int unreadCount = 0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(avatar),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}