import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'services/api_service.dart';

class InfoFeedPage extends StatefulWidget {
  const InfoFeedPage({super.key});

  @override
  State<InfoFeedPage> createState() => _InfoFeedPageState();
}

class _InfoFeedPageState extends State<InfoFeedPage> {
  List<Map<String, dynamic>> infoCards = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAndDecryptData();
  }

  Future<void> _fetchAndDecryptData() async {
    try {
      final encryptedData = await ApiService.fetchInfoFeed();
      
      // Decryption setup
      final key = enc.Key.fromUtf8('msic_secret_encryption_key_32_ch');
      final iv = enc.IV.fromUtf8('1234567890123456');
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      String decryptField(String encryptedText) {
        try {
          return encrypter.decrypt64(encryptedText, iv: iv);
        } catch (e) {
          return 'Decryption Error';
        }
      }

      final List<Map<String, dynamic>> decryptedCards = [];
      for (var item in encryptedData) {
        decryptedCards.add({
          'name': decryptField(item['name']),
          'contact': decryptField(item['contact']),
          'ministry': decryptField(item['ministry']),
        });
      }

      if (mounted) {
        setState(() {
          infoCards = decryptedCards;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Confidential Info Feed'),
        backgroundColor: const Color(0xFFDD0004),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDD0004)));
    }
    
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    
    if (infoCards.isEmpty) {
      return const Center(child: Text('No data found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: infoCards.length,
      itemBuilder: (context, index) {
        final info = infoCards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        info['name'][0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info['name'],
                            style: const TextStyle(
                              fontFamily: 'RobotoSlab',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Contact: ${info['contact']}',
                            style: TextStyle(
                              fontFamily: 'RobotoSlab',
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_balance, size: 20, color: Color(0xFFDD0004)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          info['ministry'],
                          style: const TextStyle(
                            fontFamily: 'RobotoSlab',
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.thumb_up_alt_outlined, 'Like'),
                    _buildActionButton(Icons.comment_outlined, 'Comment'),
                    _buildActionButton(Icons.share_outlined, 'Share'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'RobotoSlab',
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
