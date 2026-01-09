import 'package:flutter/material.dart';
import 'package:frontend/core/routes/o_routes.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/constants/colors.dart';
import '../../../../../core/utils/helpers/helper_functions.dart';
import '../../controllers/home_controller.dart';

/// 💬 Chats Tab Widget
///
/// This widget displays the list of users that can be messaged.
/// It integrates with the HomeController to fetch users from the Rust backend.
///
/// FLUTTER + GETX PATTERN:
/// - Uses GetX for reactive state management
/// - Automatically updates UI when data changes
/// - Handles loading and error states
class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔗 GET CONTROLLER
    // GetX automatically creates and manages the HomeController
    final homeController = Get.put(HomeController());
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Column(
      children: [
        // 🔍 SEARCH BAR
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: homeController.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: TextStyle(
                color: isDarkMode
                    ? TColors.white.withOpacity(0.7)
                    : TColors.primary,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDarkMode
                    ? TColors.white.withOpacity(0.7)
                    : TColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? TColors.white.withOpacity(0.3)
                      : TColors.primary.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? TColors.white.withOpacity(0.3)
                      : TColors.primary.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: TColors.primary,
                  width: 2,
                ),
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? TColors.white : TColors.primary,
            ),
          ),
        ),

        // 👥 USERS LIST
        Expanded(
          child: Obx(() {
            // 🔄 LOADING STATE
            if (homeController.isLoadingUsers) {
              return const Center(
                child: CircularProgressIndicator(
                  color: TColors.primary,
                ),
              );
            }

            // ❌ ERROR STATE
            if (homeController.errorMessage.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: isDarkMode
                          ? TColors.white.withOpacity(0.7)
                          : TColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load users',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? TColors.white.withOpacity(0.7)
                            : TColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      homeController.errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode
                            ? TColors.white.withOpacity(0.7)
                            : TColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: homeController.refreshUsers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: TColors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // 📝 EMPTY STATE
            if (homeController.filteredUsers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: isDarkMode
                          ? TColors.white.withOpacity(0.7)
                          : TColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      homeController.searchQuery.isEmpty
                          ? 'No users found'
                          : 'No users match your search',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? TColors.white.withOpacity(0.7)
                            : TColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      homeController.searchQuery.isEmpty
                          ? 'Pull to refresh or check your connection'
                          : 'Try a different search term',
                      style: TextStyle(
                        color: isDarkMode
                            ? TColors.white.withOpacity(0.7)
                            : TColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 📋 USERS LIST
            return RefreshIndicator(
              onRefresh: homeController.refreshUsers,
              color: TColors.primary,
              child: ListView.builder(
                itemCount: homeController.filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = homeController.filteredUsers[index];

                  return ListTile(
                    onTap: () => homeController.startChatWithUser(user),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: TColors.primary,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.initials,
                              style: const TextStyle(
                                color: TColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      user.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? TColors.white.withOpacity(0.9)
                            : TColors.primary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: TextStyle(
                            color: isDarkMode
                                ? TColors.white.withOpacity(0.7)
                                : TColors.primary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: user.isOnline
                                ? Colors.green
                                : isDarkMode
                                    ? TColors.white.withOpacity(0.5)
                                    : TColors.primary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (user.isOnline)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.chevron_right,
                          color: isDarkMode
                              ? TColors.white.withOpacity(0.5)
                              : TColors.primary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}
