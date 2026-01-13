import 'package:flutter/material.dart';
import '../models.dart';
import '../services/music_player_service.dart';
import '../widgets/glassmorphism.dart';
import '../theme/glass_theme.dart';

class LLMChatPage extends StatefulWidget {
  const LLMChatPage({super.key});

  @override
  LLMChatPageState createState() => LLMChatPageState();
}

class LLMChatPageState extends State<LLMChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    // LLM 初始打招呼訊息
    _addBotMessage('嗨！我是你的音樂助手 🎵\n告訴我你現在的心情或想聽的音樂類型，我會為你推薦合適的歌曲！');
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {List<String>? songs}) {
    setState(() {
      messages.add(ChatMessage(
        text: text,
        isBot: true,
        songs: songs,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      messages.add(ChatMessage(
        text: text,
        isBot: false,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // 等待列表渲染完成後滾動到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 添加用戶訊息
    _addUserMessage(text);
    _controller.clear();

    // 模擬 LLM 回覆（延遲 1 秒）
    Future.delayed(Duration(seconds: 1), () {
      _generateBotResponse(text);
    });
  }

  void _generateBotResponse(String userMessage) {
    // 這裡是寫死的回覆邏輯，之後會替換成真正的 LLM API
    String response;
    List<String>? songs;

    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('sad') || 
        lowerMessage.contains('傷心') || 
        lowerMessage.contains('難過')) {
      response = '聽起來你需要一些療癒的音樂 🌙\n這些歌曲也許能陪伴你：';
      songs = [
        'Yiruma - River Flows in You',
        'Ludovico Einaudi - Nuvole Bianche',
        'Max Richter - On The Nature of Daylight',
      ];
    } else if (lowerMessage.contains('happy') || 
               lowerMessage.contains('開心') || 
               lowerMessage.contains('快樂')) {
      response = '太好了！來點輕快的音樂吧 🎉';
      songs = [
        'Pharrell Williams - Happy',
        'Mark Ronson - Uptown Funk',
        'Justin Timberlake - Can\'t Stop The Feeling',
      ];
    } else if (lowerMessage.contains('relax') || 
               lowerMessage.contains('放鬆') || 
               lowerMessage.contains('chill')) {
      response = '放鬆時刻到了 ☕ 試試這些：';
      songs = [
        'Bon Iver - Holocene',
        'Norah Jones - Don\'t Know Why',
        'Jack Johnson - Better Together',
      ];
    } else if (lowerMessage.contains('study') || 
               lowerMessage.contains('讀書') || 
               lowerMessage.contains('專注')) {
      response = '專注學習模式啟動 📚';
      songs = [
        'Lofi Hip Hop - Beats to Study',
        'Brian Eno - Music for Airports',
        'Ólafur Arnalds - Near Light',
      ];
    } else {
      response = '我為你找到了一些推薦歌曲 🎵';
      songs = [
        'The Beatles - Here Comes The Sun',
        'Fleetwood Mac - Dreams',
        'Tame Impala - The Less I Know The Better',
      ];
    }

    _addBotMessage(response, songs: songs);
  }

  @override
  Widget build(BuildContext context) {
    // 檢查播放器是否最小化
    final musicService = MusicPlayerService();
    final bool hasMinimizedPlayer = musicService.isMinimized && musicService.currentSong != null;
    final double bottomPadding = hasMinimizedPlayer ? 90.0 : 16.0; // 播放器高度約70px + 間距
    
    return Scaffold(
      resizeToAvoidBottomInset: true, // 鍵盤彈出時調整布局
      appBar: AppBar(
        title: Text('LLM chat',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: bottomPadding + 70, // 列表底部間距 = 輸入框高度 + 播放器間距
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          // 輸入框區域
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: bottomPadding + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GlassWithGlow(
                    borderRadius: BorderRadius.circular(25),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    opacity: 0.8,
                    glowBlur: Glow.inputBlur,
                    glowSpread: Glow.inputSpread,
                    glowAlpha: Glow.inputAlpha,
                    child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Input text',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: _handleSendMessage,
                  child: GlassWithGlow(
                    borderRadius: BorderRadius.circular(25),
                    padding: EdgeInsets.all(14),
                    glowColor: Color(0xFF9C27B0),
                    glowBlur: Glow.buttonBlur,
                    glowSpread: Glow.buttonSpread,
                    glowAlpha: Glow.buttonAlpha,
                    child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: GlassWithGlow(
        borderRadius: BorderRadius.circular(16),
        padding: EdgeInsets.all(12),
        glowColor: message.isBot
            ? Color(0xFF9C27B0)
            : Color(0xFFBA68C8),
        glowBlur: Glow.cardBlur,
        glowSpread: Glow.cardSpread,
        glowAlpha: Glow.cardAlpha,
        child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: TextStyle(color: Colors.white)),
            if (message.songs != null) ...[
              SizedBox(height: 10),
              ...message.songs!
                  .map((song) => GlassWithGlow(
                        borderRadius: BorderRadius.circular(8),
                        padding: EdgeInsets.all(8),
                        glowColor: Color(0xFF9C27B0),
                        opacity: 0.05,
                        glowBlur: Glow.cardBlur,
                        glowSpread: Glow.cardSpread,
                        glowAlpha: Glow.cardAlpha,
                        child: Container(
                        margin: EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Icon(Icons.music_note, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(child: Text(song, style: TextStyle(fontSize: 12))),
                          ],
                        ),
                        ),
                      ))
                  ,
            ],
          ],
        ),
        ),
      ),
    );
  }
}
