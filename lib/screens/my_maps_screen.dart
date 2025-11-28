import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/guide_book_service.dart';

/// My Maps screen - manage downloaded maps and guide books
class MyMapsScreen extends StatelessWidget {
  const MyMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Maps'),
        centerTitle: true,
      ),
      body: Consumer<GuideBookService>(
        builder: (context, guideBookService, child) {
          final guideBooks = guideBookService.guideBooks;

          if (guideBooks.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: guideBooks.length,
            itemBuilder: (context, index) {
              final guide = guideBooks[index];
              final isActive = guideBookService.activeGuideBook?.id == guide.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.map,
                      size: 32,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  title: Text(
                    guide.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${guide.city}, ${guide.country}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${guide.waypointCount} waypoints',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          _showGuideOptions(context, guide);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isActive) {
                      guideBookService.setActiveGuideBook(guide);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No maps yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Import a guide book to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showGuideOptions(BuildContext context, guide) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Set as Active'),
              onTap: () {
                context.read<GuideBookService>().setActiveGuideBook(guide);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Guide'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, guide);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, guide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Guide'),
        content: Text('Are you sure you want to delete "${guide.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<GuideBookService>().deleteGuideBook(guide);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
