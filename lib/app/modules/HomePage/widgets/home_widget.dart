import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive_helper.dart';

// Theme colors (keep consistent)
const Color primaryBlue = Color(0xFF2196F3);
const Color lightBlue = Color(0xFFE3F2FD);
const Color cardWhite = Color(0xFFFFFFFF);
const Color textDark = Color(0xFF1A1A1A);
const Color textGrey = Color(0xFF6B7280);

/// Quick Access Grid Item Widget
class QuickAccessItem extends StatelessWidget {
  final ResponsiveHelper responsive;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAccessItem({
    super.key,
    required this.responsive,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(responsive.spacing(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: responsive.spacing(44),
              height: responsive.spacing(44),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: responsive.fontSize(22),
              ),
            ),
            SizedBox(height: responsive.spacing(8)),
            Padding(
              padding: responsive.paddingSymmetric(horizontal: 4, vertical: 0),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat Card Widget
class StatCard extends StatelessWidget {
  final ResponsiveHelper responsive;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.responsive,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: responsive.paddingAll(16),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(responsive.spacing(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: responsive.spacing(48),
              height: responsive.spacing(48),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: responsive.fontSize(24),
              ),
            ),
            SizedBox(width: responsive.spacing(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: responsive.fontSize(13),
                            fontWeight: FontWeight.w500,
                            color: textGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(4)),
                      Icon(
                        Icons.group_rounded,
                        size: responsive.fontSize(14),
                        color: textGrey.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: responsive.fontSize(24),
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w400,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textGrey.withValues(alpha: 0.3),
              size: responsive.fontSize(24),
            ),
          ],
        ),
      ),
    );
  }
}

/// Activity Item Widget
class ActivityItem extends StatelessWidget {
  final ResponsiveHelper responsive;
  final IconData icon;
  final String text;
  final String time;

  const ActivityItem({
    super.key,
    required this.responsive,
    required this.icon,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacing(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: responsive.spacing(36),
            height: responsive.spacing(36),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(responsive.spacing(10)),
            ),
            child: Icon(
              icon,
              color: primaryBlue,
              size: responsive.fontSize(18),
            ),
          ),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w500,
                    color: textDark,
                  ),
                ),
                SizedBox(height: responsive.spacing(2)),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: responsive.fontSize(12),
                    fontWeight: FontWeight.w400,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Navigation Item Widget
class NavItem extends StatelessWidget {
  final ResponsiveHelper responsive;
  final IconData icon;
  final String label;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.responsive,
    required this.icon,
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: responsive.paddingSymmetric(vertical: 2, horizontal: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? primaryBlue
                    : textGrey.withValues(alpha: 0.5),
                size: responsive.fontSize(22),
              ),
              SizedBox(height: responsive.spacing(2)),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: responsive.fontSize(9),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? primaryBlue
                      : textGrey.withValues(alpha: 0.5),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}