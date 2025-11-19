import 'package:family_socail/app/modules/HomePage/controller/home_controller.dart';
import 'package:family_socail/app/modules/HomePage/utils/responsive_helper.dart';
import 'package:family_socail/app/modules/HomePage/widgets/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';


class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Obx(() {
      if (controller.isLoading) {
        return const Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
            child: CircularProgressIndicator(
              color: primaryBlue,
            ),
          ),
        );
      }

      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: backgroundColor,
        drawer: _buildDrawer(context),
        body: CustomScrollView(
          slivers: [
            _buildAppBar(responsive),

            SliverPadding(
              padding: responsive.paddingAll(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildInviteButton(responsive),
                  SizedBox(height: responsive.spacing(24)),

                  _buildSectionHeader(
                    responsive,
                    'Quick Access',
                    'Navigate to key family features',
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  _buildQuickAccessGrid(responsive),
                  SizedBox(height: responsive.spacing(24)),

                  _buildSectionHeader(
                    responsive,
                    'Family Overview',
                    'Your family stats at a glance',
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  _buildFamilyOverview(responsive),
                  SizedBox(height: responsive.spacing(24)),

                  _buildSectionHeader(
                    responsive,
                    'Recent Activity',
                    'Latest family updates',
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  _buildRecentActivity(responsive),
                  SizedBox(height: responsive.spacing(100)),
                ]),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          elevation: 4,
          backgroundColor: primaryBlue,
          shape: const CircleBorder(),
          child: Icon(
            Icons.add,
            size: responsive.fontSize(28),
            color: Colors.white,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNavBar(responsive),
      );
    });
  }

  Widget _buildAppBar(ResponsiveHelper responsive) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: responsive.spacing(140),
      collapsedHeight: responsive.spacing(140),
      backgroundColor: cardWhite,
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: responsive.paddingFromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Welcome back, ${controller.userFirstName}',
                              style: GoogleFonts.inter(
                                fontSize: responsive.fontSize(16),
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: responsive.spacing(2)),
                            Text(
                              "Here's what's happening with ${controller.familyName}",
                              style: GoogleFonts.inter(
                                fontSize: responsive.fontSize(11),
                                fontWeight: FontWeight.w400,
                                color: textGrey,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        )),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconButton(
                        responsive,
                        Icons.notifications_outlined,
                        () {},
                      ),
                      SizedBox(width: responsive.spacing(8)),
                      Builder(
                        builder: (context) => _buildIconButton(
                          responsive,
                          Icons.menu_rounded,
                          () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(16)),

              _buildSearchBar(responsive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    ResponsiveHelper responsive,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: responsive.spacing(40),
      height: responsive.spacing(40),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(responsive.spacing(10)),
      ),
      child: IconButton(
        icon: Icon(icon, size: responsive.fontSize(20)),
        color: primaryBlue,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  /// Build Search Bar
  Widget _buildSearchBar(ResponsiveHelper responsive) {
    return Container(
      height: responsive.spacing(46),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        border: Border.all(
          color: lightBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search tasks, events, members...",
          hintStyle: GoogleFonts.inter(
            fontSize: responsive.fontSize(14),
            color: textGrey.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          contentPadding: responsive.paddingSymmetric(
            horizontal: 16,
            vertical: 12,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: primaryBlue.withValues(alpha: 0.7),
            size: responsive.fontSize(22),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: responsive.spacing(48),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: lightBlue,
              child: Icon(
                Icons.person,
                size: 40,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => Text(
                  controller.userName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                )),
            const SizedBox(height: 8),
            Obx(() => Text(
                  controller.familyName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: textGrey,
                  ),
                )),
            const SizedBox(height: 32),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              onTap: controller.logout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteButton(ResponsiveHelper responsive) {
    return SizedBox(
      width: double.infinity,
      height: responsive.spacing(50),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.add, size: responsive.fontSize(20)),
        label: Text(
          'Invite Member',
          style: GoogleFonts.inter(
            fontSize: responsive.fontSize(15),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.spacing(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ResponsiveHelper responsive,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: responsive.fontSize(13),
            fontWeight: FontWeight.w400,
            color: textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessGrid(ResponsiveHelper responsive) {
    return GridView.count(
      padding: responsive.paddingAll(8),
      crossAxisCount: responsive.isTablet ? 4 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: responsive.spacing(12),
      mainAxisSpacing: responsive.spacing(12),
      childAspectRatio: 1,
      children: [
        QuickAccessItem(
          responsive: responsive,
          icon: Icons.group_rounded,
          label: 'Members',
          onTap: controller.navigateToMembers,
        ),
        QuickAccessItem(
          responsive: responsive,
          icon: Icons.alarm_rounded,
          label: 'Alarms',
          onTap: controller.navigateToAlarmScreen,
        ),
        QuickAccessItem(
          responsive: responsive,
          icon: Icons.folder_rounded,
          label: 'Documents',
          onTap: controller.navigateToDocuments,
        ),
        QuickAccessItem(
          responsive: responsive,
          icon: Icons.credit_card_rounded,
          label: 'Expenses',
          onTap: () => controller.handleBottomNavigation(1),
        ),
        QuickAccessItem(
          responsive: responsive,
          icon: Icons.lock,
          label: 'Passwords',
          onTap: controller.navigateToPasswords,
        ),
        QuickAccessItem(
          responsive: responsive,
          icon: Icons.chat_bubble_rounded,
          label: 'Chat',
          onTap: controller.navigateToChat,
        ),
      ],
    );
  }

  Widget _buildFamilyOverview(ResponsiveHelper responsive) {
    return Column(
      children: [
        StatCard(
          responsive: responsive,
          title: 'Family Members',
          value: '4',
          subtitle: '2 online now',
          icon: Icons.group_rounded,
          onTap: controller.navigateToMembers,
        ),
        SizedBox(height: responsive.spacing(12)),
        StatCard(
          responsive: responsive,
          title: 'Active Alarms',
          value: '8',
          subtitle: '3 scheduled today',
          icon: Icons.alarm_rounded,
          onTap: controller.navigateToAlarmScreen,
        ),
        SizedBox(height: responsive.spacing(12)),
        StatCard(
          responsive: responsive,
          title: 'Shared Items',
          value: '24',
          subtitle: 'Passwords & docs',
          icon: Icons.folder_rounded,
          onTap: controller.navigateToDocuments,
        ),
        SizedBox(height: responsive.spacing(12)),
        StatCard(
          responsive: responsive,
          title: 'Monthly Expenses',
          value: '\$2,340',
          subtitle: '+8% from last month',
          icon: Icons.credit_card_rounded,
          onTap: () => controller.handleBottomNavigation(1),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(ResponsiveHelper responsive) {
    return Column(
      children: [
        ActivityItem(
          responsive: responsive,
          icon: Icons.alarm_rounded,
          text: 'Mike Johnson created alarm \'Family Dinner\'',
          time: '10 minutes ago',
        ),
        ActivityItem(
          responsive: responsive,
          icon: Icons.image_rounded,
          text: 'Emma Johnson uploaded 3 photos to \'Summer Vacation\'',
          time: '1 hour ago',
        ),
        ActivityItem(
          responsive: responsive,
          icon: Icons.check_circle_rounded,
          text: 'Alex Johnson completed task \'Take out trash\'',
          time: '2 hours ago',
        ),
        ActivityItem(
          responsive: responsive,
          icon: Icons.attach_money_rounded,
          text: 'Sarah Johnson added expense \'Groceries - \$156\'',
          time: '3 hours ago',
        ),
      ],
    );
  }
  Widget _buildBottomNavBar(ResponsiveHelper responsive) {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        padding: responsive.paddingSymmetric(horizontal: 8, vertical: 8),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: cardWhite,
        elevation: 0,
        height: responsive.spacing(67),
        child: Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavItem(
                  responsive: responsive,
                  icon: Icons.home_rounded,
                  label: "Home",
                  index: 0,
                  isSelected: controller.selectedIndex == 0,
                  onTap: () => controller.handleBottomNavigation(0),
                ),
                NavItem(
                  responsive: responsive,
                  icon: Icons.wallet_rounded,
                  label: "Expenses",
                  index: 1,
                  isSelected: controller.selectedIndex == 1,
                  onTap: () => controller.handleBottomNavigation(1),
                ),
                SizedBox(width: responsive.spacing(48)),
                NavItem(
                  responsive: responsive,
                  icon: Icons.chat_bubble_rounded,
                  label: "Chat",
                  index: 3,
                  isSelected: controller.selectedIndex == 3,
                  onTap: () => controller.handleBottomNavigation(3),
                ),
                NavItem(
                  responsive: responsive,
                  icon: Icons.person_rounded,
                  label: "Profile",
                  index: 4,
                  isSelected: controller.selectedIndex == 4,
                  onTap: () => controller.handleBottomNavigation(4),
                ),
              ],
            )),
      ),
    );
  }
}