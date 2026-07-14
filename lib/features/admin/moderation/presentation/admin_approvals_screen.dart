import 'package:flutter/material.dart';

import 'payout_accounts_tab.dart';
import 'pending_packages_tab.dart';
import 'pending_posts_tab.dart';
import 'review_reports_tab.dart';

/// The four moderation queues behind one scrollable tab bar.
class AdminApprovalsScreen extends StatelessWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phê duyệt'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Gói tập'),
              Tab(text: 'Bài viết'),
              Tab(text: 'Tài khoản nhận tiền'),
              Tab(text: 'Báo cáo đánh giá'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              PendingPackagesTab(),
              PendingPostsTab(),
              PayoutAccountsTab(),
              ReviewReportsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
