import base64
import json

page1 = """
1 Mir Mohammad Helal Uddin (MP) 01713213678
2 Habibur Rashid (MP) 01677788880
3 Md. Rajib Ahsan (MP) 01711209155
4 Md. Abdul Bari (MP) 01789512368
5 Mir Shahe Alam (MP) 01711368609
6 Md. Junaid Abdur Rahim Saki (MP) 01715189545
7 Ishraque Hossain (MP) 01761815229
8 Farjana Sharmin (MP) 01888717434
9 Sheikh Faridul Islam (MP) 01711565151
10 A N M Ehsanul Hoque Milan (MP) 01711551942
11 Sardar Md. Sakhawat Hossain (MP) 01713250080
12 Fakir Mahbub Anam (MP) 01711556262
13 Sheikh Rabiul Alam (MP) 01728555417
14 Mirza Fakhrul Islam Alamgir (MP) 01726676306
15 Amir Khasru Mahmud Chowdhury (MP) 01750020320
16 Salahuddin Ahmed (MP) 01711402442
17 Iqbal Hasan Mahmud (MP) 01676660666
18 Hafiz Uddin Ahmed Bir Bikrom (MP) 01409302478
19 Abu Zafar Md. Zahid Hossain (MP) 01710193693
20 Dr. Khalilur Rahman (Technocrat) 01739196580
21 Abdul Awal Mintoo (MP) 01711531701
22 Kazi Shah Mofazzal Hossain Kaikobad (MP) 01711523361
23 Mizanur Rahman Minu (MP) 01720440157
24 Nitai Roy Chowdhury (MP) 01711145414
25 Khandaker Abdul Muktadir (MP) 01711804902
26 Ariful Haque Chowdhury (MP) 01733371800
27 Zahir Uddin Swapan (MP) 01713009797
28 Mohammad Amin Ur Rashid (Technocrat) 01763426386
29 Afroza Khanam (MP) 01711521001
30 Md. Shahid Uddin Chowdhury Annie (MP) 01749899595
31 Asadul Habib Dulu (MP) 01915617968
32 Md. Asaduzzaman (MP) 01911011887
33 Zakaria Taher (MP) 01333333000
34 Dipen Dewan (MP) 01818969582
"""

page2 = """
Ministry of Chittagong Hill Tracts Affairs
Ministry of Road Transport, Bridges, Railways & Shipping
Ministry of Road Transport, Bridges, Railways & Shipping
Ministry of Public Administration
Ministry of Local Govt, Rural Dev & Co-operatives
Ministry of Finance, Planning & Home Affairs
Ministry of Liberation War Affairs
Ministry of Women, Children Affairs & Social Welfare
Ministry of Environment, Religious & Law Affairs
Ministry of Education, Primary & Mass Education
Ministry of Health and Family Welfare
Ministry of Posts, Telecom & Science Technology
Ministry of Road Transport, Bridges, Railways & Shipping
Ministry of Local Govt, Rural Dev & Co-operatives
Ministry of Finance, Planning & Home Affairs
Ministry of Finance, Planning & Home Affairs
Ministry of Power, Energy and Mineral Resources
Ministry of Liberation War Affairs
Ministry of Women, Children Affairs & Social Welfare
Ministry of Foreign Affairs
Ministry of Environment, Forest and Climate Change
Ministry of Religious Affairs
Ministry of Land
Ministry of Cultural Affairs
Ministry of Commerce, Industries, Textiles & Jute
Ministry of Labour, Expatriates' Welfare
Ministry of Information and Broadcasting
Ministry of Agriculture, Fisheries & Food
Ministry of Civil Aviation and Tourism
Ministry of Water Resources
Ministry of Disaster Management and Relief
Ministry of Law, Justice & Parliamentary Affairs
Ministry of Housing and Public Works
Ministry of Chittagong Hill Tracts Affairs
"""

lines1 = [line.strip() for line in page1.strip().split('\n')]
lines2 = [line.strip() for line in page2.strip().split('\n')]

data = []
for i in range(len(lines1)):
    parts = lines1[i].split(' ')
    # The first is a number, the last is the contact
    contact = parts[-1]
    name = ' '.join(parts[1:-1])
    ministry = lines2[i]
    
    data.append({
        'name': name,
        'contact': contact,
        'ministry': ministry
    })

json_str = json.dumps(data)
encoded = base64.b64encode(json_str.encode('utf-8')).decode('utf-8')

dart_code = f"""import 'dart:convert';
import 'package:flutter/material.dart';

class InfoFeedPage extends StatefulWidget {{
  const InfoFeedPage({{super.key}});

  @override
  State<InfoFeedPage> createState() => _InfoFeedPageState();
}}

class _InfoFeedPageState extends State<InfoFeedPage> {{
  List<Map<String, dynamic>> infoCards = [];

  @override
  void initState() {{
    super.initState();
    _loadSecureData();
  }}

  void _loadSecureData() {{
    // Data is base64 encoded to prevent simple text searching in the binary
    // and is stored completely offline, never touching the database.
    const String securePayload = '{encoded}';
    
    final String decodedStr = utf8.decode(base64.decode(securePayload));
    final List<dynamic> parsedList = json.decode(decodedStr);
    
    setState(() {{
      infoCards = parsedList.cast<Map<String, dynamic>>();
    }});
  }}

  @override
  Widget build(BuildContext context) {{
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Confidential Info Feed'),
        backgroundColor: const Color(0xFFDD0004),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: infoCards.length,
        itemBuilder: (context, index) {{
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Contact: ${{info['contact']}}',
                              style: TextStyle(
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
        }},
      ),
    );
  }}

  Widget _buildActionButton(IconData icon, String label) {{
    return InkWell(
      onTap: () {{}},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }}
}}
"""

with open('e:/MSIc/lib/info_feed_page.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)

print("Done generating InfoFeedPage")
