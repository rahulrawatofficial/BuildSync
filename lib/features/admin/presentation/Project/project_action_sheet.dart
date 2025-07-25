import 'package:flutter/material.dart';

class ProjectActionSheet extends StatelessWidget {
  final String projectId;
  final String projectName;
  final Function(String projectId) onEditProject;
  final Function(String projectId) onAddExpense;
  final Function(String projectId) onAddTask;
  final Function(String projectId) onGenerateQuote;

  const ProjectActionSheet({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.onEditProject,
    required this.onAddExpense,
    required this.onAddTask,
    required this.onGenerateQuote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              projectName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            _buildActionTile(
              theme: theme,
              icon: Icons.edit,
              iconColor: Colors.blueAccent,
              title: 'Edit Project',
              onTap: () {
                Navigator.pop(context);
                onEditProject(projectId);
              },
            ),
            _buildActionTile(
              theme: theme,
              icon: Icons.add_card,
              iconColor: Colors.green,
              title: 'Add Expense',
              onTap: () {
                Navigator.pop(context);
                onAddExpense(projectId);
              },
            ),
            _buildActionTile(
              theme: theme,
              icon: Icons.playlist_add,
              iconColor: Colors.orange,
              title: 'Add Task',
              onTap: () {
                Navigator.pop(context);
                onAddTask(projectId);
              },
            ),
            _buildActionTile(
              theme: theme,
              icon: Icons.request_quote_outlined,
              iconColor: Colors.purple,
              title: 'Generate Quote',
              onTap: () {
                Navigator.pop(context);
                onGenerateQuote(projectId);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: theme.colorScheme.surface,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.iconTheme.color,
        ),
        onTap: onTap,
      ),
    );
  }
}
