import 'package:family_socail/app/modules/Alarm/controllers%20/alarm_controller.dart';
import 'package:family_socail/app/modules/Alarm/widgets/alarm_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;


class AlarmScreen extends GetView<AlarmController> {
  const AlarmScreen({super.key});

  
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          
          _buildAppBar(screenWidth, screenHeight, textScaleFactor, horizontalPadding),

          
          SliverPadding(
            padding: EdgeInsets.all(horizontalPadding),
            sliver: Obx(() {
              if (controller.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  ),
                );
              }

              if (controller.alarms.isEmpty) {
                return _buildEmptyState(screenWidth, screenHeight);
              }

              return _buildAlarmsList(screenWidth, screenHeight);
            }),
          ),
        ],
      ),
    );
  }

  
  Widget _buildAppBar(
    double screenWidth,
    double screenHeight,
    double textScaleFactor,
    double horizontalPadding,
  ) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: math.max(70.0, 50.0 + (textScaleFactor * 20)),
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.only(left: screenWidth * 0.02),
        child: IconButton(
          icon: Container(
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
              maxWidth: 44,
              maxHeight: 44,
            ),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back,
              color: primaryBlue,
              size: math.min(20, 16 + textScaleFactor * 4),
            ),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      flexibleSpace: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.15,
            0,
            horizontalPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Family Alarms',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenHeight * 0.003),
              Text(
                'Stay connected with timely reminders',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: textGrey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return SliverFillRemaining(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnalogClock(screenWidth: screenWidth),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: CreateAlarmButton(
                        onPressed: controller.showCreateAlarmDialog,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'No alarms set',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                      child: Text(
                        'Tap the button above to create your first alarm',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  
  Widget _buildAlarmsList(double screenWidth, double screenHeight) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Column(
              children: [
                AnalogClock(screenWidth: screenWidth),
                SizedBox(height: screenHeight * 0.025),
                CreateAlarmButton(onPressed: controller.showCreateAlarmDialog),
                SizedBox(height: screenHeight * 0.03),
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Your Alarms',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.025,
                            vertical: screenHeight * 0.005,
                          ),
                          constraints: const BoxConstraints(minHeight: 24),
                          decoration: BoxDecoration(
                            color: lightBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${controller.alarmsCount} alarm${controller.alarmsCount > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    )),
                SizedBox(height: screenHeight * 0.015),
                Obx(() => AlarmCard(
                      alarm: controller.alarms[index],
                      onDelete: () => controller.deleteAlarm(controller.alarms[index]),
                    )),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.012),
            child: Obx(() => AlarmCard(
                  alarm: controller.alarms[index],
                  onDelete: () => controller.deleteAlarm(controller.alarms[index]),
                )),
          );
        },
        childCount: controller.alarms.length,
      ),
    );
  }
}