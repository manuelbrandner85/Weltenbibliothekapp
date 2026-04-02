/// 💀 LOADING SKELETON WIDGETS
/// Shimmer-Effekt Loading States für bessere UX
/// 
/// Features:
/// - Post Card Skeletons
/// - List Item Skeletons  
/// - Profile Skeletons
/// - Custom Skeletons
/// - Smooth Transition zu echtem Content
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeletons {
  /// Shimmer-Basis-Widget
  static Widget shimmerWrapper({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: child,
    );
  }
  
  /// Skeleton Box (Basis-Element)
  static Widget box({
    double? width,
    double? height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
  
  /// Post Card Skeleton (für Community Feed)
  static Widget postCard() {
    return shimmerWrapper(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Name + Zeit
              Row(
                children: [
                  box(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        box(width: 120, height: 14, borderRadius: 4),
                        const SizedBox(height: 6),
                        box(width: 80, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Content: Titel + Text
              box(width: double.infinity, height: 18, borderRadius: 4),
              const SizedBox(height: 8),
              box(width: double.infinity, height: 14, borderRadius: 4),
              const SizedBox(height: 6),
              box(width: 200, height: 14, borderRadius: 4),
              const SizedBox(height: 16),
              
              // Image Placeholder
              box(
                width: double.infinity,
                height: 180,
                borderRadius: 12,
              ),
              const SizedBox(height: 16),
              
              // Footer: Likes, Comments, Shares
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  box(width: 80, height: 32, borderRadius: 16),
                  box(width: 80, height: 32, borderRadius: 16),
                  box(width: 80, height: 32, borderRadius: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// List Item Skeleton (für Listen)
  static Widget listItem() {
    return shimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            box(width: 60, height: 60, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(width: double.infinity, height: 16, borderRadius: 4),
                  const SizedBox(height: 8),
                  box(width: 180, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  box(width: 120, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Profile Header Skeleton
  static Widget profileHeader() {
    return shimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            box(width: 100, height: 100, borderRadius: 50),
            const SizedBox(height: 16),
            
            // Name
            box(width: 180, height: 20, borderRadius: 4),
            const SizedBox(height: 8),
            
            // Bio
            box(width: 220, height: 14, borderRadius: 4),
            const SizedBox(height: 24),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    box(width: 60, height: 24, borderRadius: 4),
                    const SizedBox(height: 6),
                    box(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
                Column(
                  children: [
                    box(width: 60, height: 24, borderRadius: 4),
                    const SizedBox(height: 6),
                    box(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
                Column(
                  children: [
                    box(width: 60, height: 24, borderRadius: 4),
                    const SizedBox(height: 6),
                    box(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Search Result Skeleton
  static Widget searchResult() {
    return shimmerWrapper(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag
              box(width: 80, height: 20, borderRadius: 10),
              const SizedBox(height: 12),
              
              // Title
              box(width: double.infinity, height: 18, borderRadius: 4),
              const SizedBox(height: 8),
              
              // Description
              box(width: double.infinity, height: 14, borderRadius: 4),
              const SizedBox(height: 6),
              box(width: 240, height: 14, borderRadius: 4),
              const SizedBox(height: 12),
              
              // Meta
              Row(
                children: [
                  box(width: 100, height: 12, borderRadius: 4),
                  const SizedBox(width: 16),
                  box(width: 80, height: 12, borderRadius: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Grid Item Skeleton (für Bildergalerien)
  static Widget gridItem() {
    return shimmerWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          box(
            width: double.infinity,
            height: 150,
            borderRadius: 12,
          ),
          const SizedBox(height: 8),
          
          // Title
          box(width: double.infinity, height: 14, borderRadius: 4),
          const SizedBox(height: 6),
          box(width: 100, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
  
  /// Comment Skeleton
  static Widget comment() {
    return shimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box(width: 32, height: 32, borderRadius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(width: 120, height: 12, borderRadius: 4),
                  const SizedBox(height: 8),
                  box(width: double.infinity, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  box(width: 180, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Liste von Post Card Skeletons
  static Widget postList({int count = 3}) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => postCard(),
    );
  }
  
  /// Liste von List Item Skeletons
  static Widget list({int count = 5}) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => listItem(),
    );
  }
  
  /// Grid von Grid Item Skeletons
  static Widget grid({int count = 6, int crossAxisCount = 2}) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: count,
      itemBuilder: (context, index) => gridItem(),
    );
  }
}
