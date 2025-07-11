import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import './widgets/client_performance_widget.dart';
import './widgets/collection_chart_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/metric_card_widget.dart';

class MonthlyReportsScreen extends StatefulWidget {
  const MonthlyReportsScreen({super.key});

  @override
  State<MonthlyReportsScreen> createState() => _MonthlyReportsScreenState();
}

class _MonthlyReportsScreenState extends State<MonthlyReportsScreen>
    with TickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  int selectedTabIndex = 2; // Reports tab active
  late TabController _tabController;

  // Mock data for reports
  final List<Map<String, dynamic>> monthlyMetrics = [
    {
      "title": "Total Collections",
      "amount": "₱125,450.00",
      "percentage": "+12.5%",
      "isPositive": true,
      "icon": "attach_money",
    },
    {
      "title": "Collection Rate",
      "amount": "87.3%",
      "percentage": "+5.2%",
      "isPositive": true,
      "icon": "trending_up",
    },
    {
      "title": "Client Visits",
      "amount": "156",
      "percentage": "-3.1%",
      "isPositive": false,
      "icon": "people",
    },
    {
      "title": "Outstanding Loans",
      "amount": "₱45,230.00",
      "percentage": "-8.7%",
      "isPositive": true,
      "icon": "account_balance_wallet",
    },
  ];

  final List<Map<String, dynamic>> chartData = [
    {"day": "Mon", "amount": 15000.0},
    {"day": "Tue", "amount": 18500.0},
    {"day": "Wed", "amount": 12300.0},
    {"day": "Thu", "amount": 22100.0},
    {"day": "Fri", "amount": 19800.0},
    {"day": "Sat", "amount": 25400.0},
    {"day": "Sun", "amount": 12350.0},
  ];

  final List<Map<String, dynamic>> topPerformers = [
    {
      "name": "Maria Santos",
      "loanAmount": "₱15,000.00",
      "collectionRate": "95%",
      "status": "Excellent",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
    },
    {
      "name": "Juan Dela Cruz",
      "loanAmount": "₱12,500.00",
      "collectionRate": "88%",
      "status": "Good",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
    },
    {
      "name": "Ana Rodriguez",
      "loanAmount": "₱18,200.00",
      "collectionRate": "92%",
      "status": "Excellent",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
    },
  ];

  final List<Map<String, dynamic>> challengingAccounts = [
    {
      "name": "Pedro Martinez",
      "loanAmount": "₱25,000.00",
      "collectionRate": "45%",
      "status": "At Risk",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
    },
    {
      "name": "Carmen Lopez",
      "loanAmount": "₱8,750.00",
      "collectionRate": "62%",
      "status": "Needs Attention",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: selectedTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoading = false;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        onApplyFilters: (filters) {
          // Handle filter application
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return DatePickerTheme(
          data: DatePickerThemeData(
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            headerBackgroundColor: AppTheme.lightTheme.primaryColor,
            headerForegroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.lightTheme.colorScheme.onPrimary;
              }
              return AppTheme.lightTheme.colorScheme.onSurface;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.lightTheme.primaryColor;
              }
              return Colors.transparent;
            }),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _exportReport() {
    // Show export options
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Export Report',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 24),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'picture_as_pdf',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              title: Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                // Handle PDF export
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'email',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: Text('Email Report'),
              onTap: () {
                Navigator.pop(context);
                // Handle email sharing
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'cloud_upload',
                color: AppTheme.lightTheme.colorScheme.tertiary,
                size: 24,
              ),
              title: Text('Save to Cloud'),
              onTap: () {
                Navigator.pop(context);
                // Handle cloud storage
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: CustomIconWidget(
                          iconName: 'arrow_back',
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Monthly Reports',
                          style: AppTheme.lightTheme.textTheme.titleLarge,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showFilterBottomSheet,
                        child: CustomIconWidget(
                          iconName: 'filter_list',
                          color: AppTheme.lightTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: _exportReport,
                        child: CustomIconWidget(
                          iconName: 'share',
                          color: AppTheme.lightTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showDatePicker,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color:
                                      AppTheme.lightTheme.colorScheme.outline),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'calendar_today',
                                  color: AppTheme.lightTheme.primaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${selectedDate.month}/${selectedDate.year}',
                                  style:
                                      AppTheme.lightTheme.textTheme.bodyMedium,
                                ),
                                Spacer(),
                                CustomIconWidget(
                                  iconName: 'keyboard_arrow_down',
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: AppTheme.lightTheme.primaryColor,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Key Metrics Cards
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: monthlyMetrics.length,
                        itemBuilder: (context, index) {
                          final metric = monthlyMetrics[index];
                          return MetricCardWidget(
                            title: metric["title"] as String,
                            amount: metric["amount"] as String,
                            percentage: metric["percentage"] as String,
                            isPositive: metric["isPositive"] as bool,
                            iconName: metric["icon"] as String,
                          );
                        },
                      ),

                      SizedBox(height: 24),

                      // Collection Trends Chart
                      Text(
                        'Collection Trends',
                        style: AppTheme.lightTheme.textTheme.titleMedium,
                      ),
                      SizedBox(height: 16),
                      CollectionChartWidget(
                        chartData: chartData,
                      ),

                      SizedBox(height: 24),

                      // Client Performance Section
                      Text(
                        'Client Performance',
                        style: AppTheme.lightTheme.textTheme.titleMedium,
                      ),
                      SizedBox(height: 16),

                      // Top Performers
                      ClientPerformanceWidget(
                        title: 'Top Performers',
                        clients: topPerformers,
                        isTopPerformers: true,
                      ),

                      SizedBox(height: 16),

                      // Challenging Accounts
                      ClientPerformanceWidget(
                        title: 'Challenging Accounts',
                        clients: challengingAccounts,
                        isTopPerformers: false,
                      ),

                      SizedBox(height: 24),

                      // Last Updated Info
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'info',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 100), // Bottom padding for tab bar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedTabIndex,
          onTap: (index) {
            setState(() {
              selectedTabIndex = index;
            });

            // Navigate to different screens based on tab
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/collector-dashboard');
                break;
              case 1:
                Navigator.pushNamed(context, '/collection-entry');
                break;
              case 2:
                // Already on reports screen
                break;
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'dashboard',
                color: selectedTabIndex == 0
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'add_circle',
                color: selectedTabIndex == 1
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              label: 'Collections',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName: 'bar_chart',
                color: selectedTabIndex == 2
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
