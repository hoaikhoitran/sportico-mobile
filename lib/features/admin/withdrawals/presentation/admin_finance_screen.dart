import 'package:flutter/material.dart';

import '../../settings/presentation/admin_commission_screen.dart';
import 'admin_withdrawals_tab.dart';

/// Finance area: the withdrawal queue and the commission setting.
class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tài chính'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Yêu cầu rút tiền'),
              Tab(text: 'Hoa hồng'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              AdminWithdrawalsTab(),
              // Embedded (no AppBar) — the tab already provides the title.
              AdminCommissionView(),
            ],
          ),
        ),
      ),
    );
  }
}
