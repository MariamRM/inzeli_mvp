import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../state.dart';
import '../api_room.dart';
import '../config.dart';

class MatchPage extends StatefulWidget {
  final AppState app;
  final Map<String, dynamic>? room; // {id, code, gameId, ...} from backend
  const MatchPage({super.key, required this.app, this.room});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // wrapper helps analyzer & allows future transforms
  Future<List<Map<String, dynamic>>> _fetchPlayers(String roomId) {
    return getPlayers(roomId);
  }

  @override
  Widget build(BuildContext context) {
    final code   = (widget.room?['code'] ?? widget.app.roomCode ?? '').toString();
    final game   = (widget.room?['gameId'] ?? widget.app.selectedGame ?? 'لعبة').toString();
    final roomId = (widget.room?['id']   ?? '').toString();

    // production QR (HTTP path on your domain)
    final httpsLink = 'https://inzeli.app/join/$code';
    // local dev (optional, opens browser to call API):
    // final devLink  = 'http://10.0.2.2:3000/api/rooms/join?userId=$guestUserId&code=$code';

    return Scaffold(
      appBar: AppBar(title: Text('مباراة $game — كود: ${code.isEmpty ? "—" : code}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (code.isNotEmpty) ...[
            Center(
              child: QrImageView(
                data: httpsLink, // change to devLink during local QR tests if you prefer
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText('كود الروم: $code', textAlign: TextAlign.center),
          ] else
            const Text('لا يوجد كود — ارجع وأنشئ روم من “انزلي”.'),

          const SizedBox(height: 20),

          // join by code (manual)
          const Text('انضم بالكود (اختبار بدون سكان)'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: 'اكتب كود الروم'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  final inputCode = _codeCtrl.text.trim();
                  if (inputCode.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اكتب الكود')),
                    );
                    return;
                  }
                  try {
                    await joinByCode(code: inputCode, userId: guestUserId);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Joined ✅')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e')),
                    );
                  }
                },
                child: const Text('انضم'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // players list (requires roomId from backend room)
          if (roomId.isNotEmpty) ...[
            const Text('اللاعبون:'),
            const SizedBox(height: 6),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchPlayers(roomId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Text('…');
                }
                if (snap.hasError) {
                  return Text('خطأ: ${snap.error}');
                }
                final rows = snap.data ?? const [];
                if (rows.isEmpty) return const Text('لاعب واحد (أنت)');
                return Wrap(
                  spacing: 6,
                  children: rows.map((r) {
                    final user = r['user'] as Map<String, dynamic>?;
                    final name = user?['fullName'] ?? user?['email'] ?? r['userId'];
                    return Chip(label: Text(name.toString()));
                  }).toList(),
                );
              },
            ),
          ] else
            const Text('لا يوجد roomId — تأكد أنك مرّرت room من API عند فتح الصفحة.'),
        ],
      ),
    );
  }
}
