import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bayt_alhikma/view_model/book_service.dart'; // Ensure this matches your file path

class HardCopyPage extends StatefulWidget {
  final String title;
  const HardCopyPage({super.key, required this.title});

  @override
  _HardCopyPageState createState() => _HardCopyPageState();
}

class _HardCopyPageState extends State<HardCopyPage> {
  bool loading = true;
  List<Map<String, dynamic>> results = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final data = await BookPriceService.searchHardCopy(widget.title);
    if (mounted) {
      setState(() {
        results = data;
        loading = false;
      });
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hard Copy Stores (Egypt)"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.search_off, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "No results found.\nTry refining your Google Search Engine settings.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final item = results[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: item["thumbnail"] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item["thumbnail"],
                              width: 50,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => const Icon(
                                Icons.book,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.book, color: Colors.grey),
                          ),
                    title: Text(
                      item["title"] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store Name
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item["store"] ?? "Web Result",
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Estimated Price
                          Row(
                            children: [
                              Icon(
                                Icons.price_change,
                                size: 14,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item["price"], // This is "EGP 100" or "Check Link"
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      if (item["link"] != null && item["link"].isNotEmpty) {
                        _launchURL(item["link"]);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
