import 'package:fawateery/features/code_compiler/views/code_compiler_view.dart';
import 'package:fawateery/features/user_details/manager/cubit/user_info_cubit.dart';
import 'package:fawateery/features/user_details/widgets/build_date_row.dart';
import 'package:fawateery/features/user_details/widgets/build_info_tile.dart';
import 'package:fawateery/features/user_details/widgets/get_rating_color.dart';
import 'package:fawateery/features/user_rating/views/user_rating_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDetailsViewBody extends StatefulWidget {
  const UserDetailsViewBody({super.key});

  @override
  State<UserDetailsViewBody> createState() => _UserDetailsViewBodyState();
}

class _UserDetailsViewBodyState extends State<UserDetailsViewBody> {
  @override
  initState() {
    super.initState();
    BlocProvider.of<UserInfoCubit>(context).fetchUserInfo('Karam');
  }

  String _formatDate(int seconds) {
    if (seconds == 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B3B6F),
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Code Compiler',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CodeCompilerView(),
                ),
              );
            },
            icon: const Icon(Icons.code_rounded),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: BlocBuilder<UserInfoCubit, UserInfoState>(
        builder: (context, state) {
          if (state is UserInfoSuccess) {
            Color rankColor = getRatingColor(
              state.userModel.rating,
              state.userModel.maxRating,
            );
            Color maxRankColor = getRatingColor(
              state.userModel.maxRating,
              state.userModel.maxRating,
            );
            return SingleChildScrollView(
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B3B6F),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 120),
                          SizedBox(
                            width: double.infinity,
                            child: Card(
                              color: Colors.white,
                              elevation: 3,
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        children: [
                                          // Full Name
                                          Text(
                                            '${state.userModel.firstName} ${state.userModel.lastName}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          // Handle
                                          Text(
                                            state.userModel.handle,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: rankColor,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              // color: rankColor.withOpacity(0.12),
                                              color: rankColor,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              ' ${state.userModel.rank}'
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                // color: rankColor,
                                                color: Colors.white,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Rating Value
                                          Text(
                                            '${state.userModel.rating}',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              // color: rankColor,
                                              color: rankColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: Card(
                              color: Colors.white,
                              elevation: 3,
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Full Name
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Current Rating',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${state.userModel.rating}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: rankColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            state.userModel.rank.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: rankColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Max Rating',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${state.userModel.maxRating}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: maxRankColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            state.userModel.maxRank
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: maxRankColor,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Handle

                                      // Rating Value
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Card(
                            elevation: 2,
                            color: Colors.white,
                            shadowColor: Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                buildInfoTile(
                                  Icons.public,
                                  'Location',
                                  state.userModel.country,
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                buildInfoTile(
                                  Icons.business,
                                  'Organization',
                                  state.userModel.organization,
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                buildInfoTile(
                                  Icons.emoji_events_outlined,
                                  'Contribution',
                                  '${state.userModel.contribution > 0 ? "+${state.userModel.contribution}" : state.userModel.contribution}',
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                buildInfoTile(
                                  Icons.people_outline,
                                  'Friends',
                                  '${state.userModel.friendOfCount} users',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Dates Activity Card
                          Card(
                            elevation: 2,
                            shadowColor: Colors.black12,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  buildDateRow(
                                    'Registered:',
                                    _formatDate(
                                      state.userModel.registrationTimeSeconds,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  buildDateRow(
                                    'Last Online:',
                                    _formatDate(
                                      state.userModel.lastOnlineTimeSeconds,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF1B3B6F),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'View Submissions',
                                    style: TextStyle(
                                      color: Color(0xFF1B3B6F),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => UserRatingView(
                                          handle: state.userModel.handle,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B3B6F),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Contest History',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: rankColor,
                        child: CircleAvatar(
                          radius: 42,
                          backgroundImage: NetworkImage(
                            state.userModel.titlePhoto.isNotEmpty
                                ? state.userModel.titlePhoto
                                : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is UserInfoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is UserInfoFailure) {
            return Center(child: Text(state.errorMessage));
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
