import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.dashboard, size: 24),
            SizedBox(width: 8),
            Text(AppStrings.dashboard),
          ],
        ),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Theme Toggle Button
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () {
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              themeProvider.toggleTheme();
            },
          ),
          // Notifications Button
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Implement notifications
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          // Logout Button
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
      drawer: _buildModernDrawer(),
      body: _buildModernBody(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.electric, AppColors.navy],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // TODO: Implement add functionality
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildModernDrawer() {
    return SizedBox(
      width: 280,
      child: Drawer(
        child: Column(
          children: [
            // Drawer Header
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, AppColors.electric],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'مرحباً بك',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'مدير النظام',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: AppStrings.dashboard,
                    onTap: () {
                      Navigator.pop(context);
                    },
                    isSelected: true,
                  ),
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: AppStrings.customers,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppConstants.customersRoute);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.inventory,
                    title: AppStrings.products,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppConstants.productsRoute);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.payment,
                    title: AppStrings.installments,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppConstants.installmentsRoute,
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt,
                    title: AppStrings.payments,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppConstants.paymentsRoute);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bar_chart,
                    title: AppStrings.reports,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppConstants.reportsRoute);
                    },
                  ),
                  Divider(height: 32),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: AppStrings.settings,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppConstants.settingsRoute);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? AppColors.electric.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.electric : AppColors.textSecondary,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.electric : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildModernBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navy, AppColors.electric],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.waving_hand, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً بك في مرساة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'إدارة الأقساط والديون بسهولة',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Stats Cards - بدون نسب مئوية
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  title: AppStrings.totalCustomers,
                  value: '156',
                  icon: Icons.people,
                  color: AppColors.electric,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildModernStatCard(
                  title: AppStrings.activeInstallments,
                  value: '89',
                  icon: Icons.payment,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  title: AppStrings.todayPayments,
                  value: '12',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildModernStatCard(
                  title: AppStrings.overduePayments,
                  value: '5',
                  icon: Icons.warning,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),

          SizedBox(height: 32),

          // Quick Actions - أزرار دائرية مع تأثير Scale
          Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildModernActionCard(
                title: AppStrings.addCustomer,
                icon: Icons.person_add,
                color: AppColors.electric,
                onTap: () {
                  Navigator.pushNamed(context, AppConstants.customersRoute);
                },
              ),
              _buildModernActionCard(
                title: AppStrings.addInstallment,
                icon: Icons.add_card,
                color: AppColors.success,
                onTap: () {
                  Navigator.pushNamed(context, AppConstants.installmentsRoute);
                },
              ),
              _buildModernActionCard(
                title: AppStrings.addPayment,
                icon: Icons.payment,
                color: AppColors.warning,
                onTap: () {
                  Navigator.pushNamed(context, AppConstants.paymentsRoute);
                },
              ),
              _buildModernActionCard(
                title: AppStrings.reports,
                icon: Icons.bar_chart,
                color: AppColors.navy,
                onTap: () {
                  Navigator.pushNamed(context, AppConstants.reportsRoute);
                },
              ),
            ],
          ),

          SizedBox(height: 32),

          // Recent Installments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخر الأقساط',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppConstants.installmentsRoute);
                },
                child: Text('عرض الكل'),
              ),
            ],
          ),
          SizedBox(height: 16),
          Card(
            elevation: 4,
            shadowColor: AppColors.shadowColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.electric.withOpacity(0.1),
                    child: Icon(Icons.person, color: AppColors.electric),
                  ),
                  title: Text('عميل مثال ${index + 1}'),
                  subtitle: Text('قسط شهري: ${150000 + (index * 10000)} IQD'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'متبقي: ${(5 - index) * 50000} IQD',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'متأخر',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 120,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.cardBgDark
              : AppColors.cardBgLight,
        ),
        child: Row(
          children: [
            // الأيقونة على اليمين (RTL)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            // المحتوى
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedScale(
      scale: 1.0,
      duration: Duration(milliseconds: 150),
      child: Card(
        elevation: 4,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            // تأثير Scale عند الضغط
            setState(() {});
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppColors.danger),
            SizedBox(width: 12),
            Text(AppStrings.logout),
          ],
        ),
        content: Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}
