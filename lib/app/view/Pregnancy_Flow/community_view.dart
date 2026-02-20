// import 'package:babyland/app/controller/pregnancy_flow/pregnancy_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:babyland/app/widgets/custom_appbar.dart';
// import 'package:babyland/app/widgets/custom_image.dart';
// import 'package:babyland/app/widgets/custom_textform_field.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
//
// import '../../constants/images.dart';
// import '../../theme/app_colors.dart';
// import '../../theme/font_family.dart';
// import '../../theme/font_style.dart';
// import '../../widgets/container.dart';
//
// class CommunityView extends StatefulWidget {
//
//   bool backButton;
//   CommunityView({super.key,this.backButton=true});
//
//   @override
//   State<CommunityView> createState() => _CommunityViewState();
// }
//
// class _CommunityViewState extends State<CommunityView> {
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final provider = context.read<PregnancyController>();
//       provider.getCommunitiesData();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     final provider = context.watch<PregnancyController>();
//
//     if (provider.isLoadingComm) {
//       return Scaffold(
//         appBar: _buildAppBar(),
//         body: _buildShimmerLoader(),
//       );
//     }
//
//     if (provider.communitiesApiData?.status == false) {
//       return Scaffold(
//         appBar: _buildAppBar(),
//         body: SizedBox(
//           height: MediaQuery.of(context).size.height,
//           width: MediaQuery.of(context).size.width,
//           child: Center(
//             child: Text(
//               provider.communitiesApiData?.message ?? "Something went wrong!",
//               style: const TextStyle(color: Colors.red, fontSize: 16),
//             ),
//           ),
//         ),
//       );
//     }
//
//     final data = provider.communitiesApiData?.data;
//
//     if (data?.data?.posts == null || data?.data?.posts == null || (data?.data?.posts?.isEmpty  ?? true)) {
//       return Scaffold(
//         appBar: _buildAppBar(),
//         body: SizedBox(
//             height: MediaQuery.of(context).size.height,
//             width: MediaQuery.of(context).size.width,
//             child: const Center(child: Text("No posts found."))),
//       );
//     }
//
//     return Scaffold(
//       appBar: CustomAppBar(
//         title: Text(
//           "Community",
//           style: AppFontStyle.text_20_400(
//             color: AppColors.textClr,
//             fontFamily: AppFontFamily.gilroySemiBold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: AppContainer(
//         gradient: AppColors.backGroundColor,
//         child: Column(
//           children: [
//             const SizedBox(height: 18),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: CustomTextFormField(
//                 borderColor: AppColors.borderColor,
//                   suffix: Icon(
//                     Icons.search,
//                     color: AppColors.textLightClr,
//                     size: 24,
//                   ),
//                   hintText: "Search Discussions",
//                   hintStyle: AppFontStyle.text_13_400(
//                     fontFamily: AppFontFamily.gilroyRegular,
//                     color: AppColors.textLightClr,
//                   ),
//                 ),
//             ),
//             const SizedBox(height: 28),
//             Expanded(
//               child: Container(
//                 decoration: const BoxDecoration(
//                   color: AppColors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(40),
//                     topRight: Radius.circular(40),
//                   ),
//                 ),
//                 child: DefaultTabController(
//                   length: 2,
//                   child: Column(
//                     children: [
//                       TabBar(
//                         tabs: [
//                           Tab(
//                             child: Text(
//                               "All",
//                               style: AppFontStyle.text_16_400(
//                                 fontFamily: AppFontFamily.gilroySemiBold,
//                                 color: AppColors.black,
//                               ),
//                             ),
//                           ),
//                           Tab(
//                             child: Text(
//                               "For you",
//                               style: AppFontStyle.text_16_400(
//                                 fontFamily: AppFontFamily.gilroyMedium,
//                                 color: AppColors.textLightClr,
//                               ),
//                             ),
//                           ),
//                         ],
//                         indicatorPadding:
//                         const EdgeInsets.symmetric(horizontal: 16),
//                         unselectedLabelColor: AppColors.textLightClr,
//                         labelColor: AppColors.black,
//                         indicatorColor: AppColors.black,
//                         indicatorSize: TabBarIndicatorSize.tab,
//                         labelStyle: AppFontStyle.text_16_400(
//                           fontFamily: AppFontFamily.gilroyMedium,
//                         ),
//                         unselectedLabelStyle: AppFontStyle.text_16_400(
//                           fontFamily: AppFontFamily.gilroyMedium,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Expanded(
//                         child: TabBarView(
//                           children: [
//                             // Tab 1: All
//                             RefreshIndicator(
//                               onRefresh: () {
//                                 provider.getCommunitiesData();
//                                 return provider.getCommunitiesData();
//                               },
//                               child: ListView.builder(
//                                 padding: const EdgeInsets.symmetric(vertical: 16),
//                                 itemCount: data?.data?.posts?.length,
//                                 itemBuilder: (_, index) {
//                                   final post = data?.data?.posts?[index];
//
//                                   return Padding(
//                                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                                     child: AppContainer(
//                                       padding: const EdgeInsets.all(12),
//                                       child: Column(
//                                         crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                         children: [
//                                           Row(
//                                             children: [
//                                                CircleAvatar(
//                                                 radius: 25,
//                                                 backgroundImage: /* post?.userId?.sId !=
//                                                     null
//                                                     ? NetworkImage(
//                                                   // You can replace with an actual user image URL here
//                                                     "https://example.com/user/${post?.userId?.sId}/avatar")
//                                                     :*/ AssetImage(
//                                                     'assets/images/girl.png')as ImageProvider,
//                                               ),
//                                               const SizedBox(width: 8),
//                                               Column(
//                                                 crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                                 children: [
//                                                   Text(
//                                                     post?.userId?.name ?? "",
//                                                     style:
//                                                     AppFontStyle.text_18_400(
//                                                       fontFamily: AppFontFamily
//                                                            .gilroySemiBold,
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     "@${post?.userId?.name ?? ""}",
//                                                     style:
//                                                     AppFontStyle.text_16_400(
//                                                       fontFamily: AppFontFamily
//                                                           .gilroyRegular,
//                                                       color:
//                                                       AppColors.textLightClr,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(height: 12),
//                                           Text(
//                                             post?.message ??"",
//                                             maxLines: 5,
//                                             style: AppFontStyle.text_14_400(
//                                               fontFamily:
//                                               AppFontFamily.gilroyMedium,
//                                             ),
//                                           ),
//                                           if (post?.hashtags != null && post!.hashtags!.isNotEmpty)...[
//                                             const SizedBox(height: 8),
//                                             Text(
//                                             post.hashtags!.join(" ") ?? "",
//                                             style: AppFontStyle.text_14_400(
//                                               fontFamily: AppFontFamily.gilroyMedium,
//                                             ),
//                                           )],
//                                           const SizedBox(height: 10),
//                                           Row(
//                                             children: [
//                                               const Icon(Icons.favorite_border),
//                                               const SizedBox(width: 4),
//                                               Text(
//                                                 post?.likes?.length.toString() ?? "0",
//                                                 style: AppFontStyle.text_14_400(
//                                                   fontFamily:
//                                                   AppFontFamily.gilroyMedium,
//                                                 ),
//                                               ),
//                                               const SizedBox(width: 8),
//                                               const Icon(
//                                                   Icons.chat_bubble_outline),
//                                               const SizedBox(width: 4),
//                                               Text(
//                                                 post?.commentsCount?.toString() ?? "0",
//                                                 style: AppFontStyle.text_14_400(
//                                                   fontFamily:
//                                                   AppFontFamily.gilroyMedium,
//                                                 ),
//                                               ),
//                                               const SizedBox(width: 8),
//                                               CustomImage(
//                                                 path: "assets/images/save.png",
//                                                 scale: 4,
//                                                 color: AppColors.black,
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(height: 10),
//                                           Text(
//                                             post?.createdAt != null ? formatDate(post?.createdAt ?? "") : "",
//                                             style: AppFontStyle.text_14_400(
//                                               fontFamily:
//                                               AppFontFamily.gilroyMedium,
//                                               color: AppColors.textLightClr,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//
//                             // Tab 2: For you (Placeholder)
//                             Center(
//                               child: Text(
//                                 "No personalized posts yet!",
//                                 style: AppFontStyle.text_16_400(
//                                   fontFamily: AppFontFamily.gilroyMedium,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: AppContainer(
//         gradient:AppColors.buttonClr,
//         radius: 100,
//         height: 54,
//         width: 54,
//         child: const Center(
//           child: Icon(
//             Icons.add,
//             color: AppColors.white,
//             size: 26,
//           ),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }
//
//
//   PreferredSizeWidget _buildAppBar() {
//     return CustomAppBar(
//       isLeading: widget.backButton == true ? true : false,
//       title: Text(
//         "Community",
//         style: AppFontStyle.text_20_400(
//           color: AppColors.textClr,
//           fontFamily: AppFontFamily.gilroySemiBold,
//         ),
//       ),
//       centerTitle: true,
//     );
//   }
//
//   Widget _buildShimmerLoader() {
//     return AppContainer(
//       gradient: AppColors.backGroundColor,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: ListView.builder(
//           itemCount: 4,
//           itemBuilder: (context, index) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               child: Shimmer.fromColors(
//                 baseColor: Colors.grey.shade300,
//                 highlightColor: Colors.grey.shade100,
//                 child: AppContainer(
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             height: 50,
//                             width: 50,
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             height: 15,
//                             width: 120,
//                             color: Colors.white,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Container(
//                         height: 40,
//                         width: double.infinity,
//                         color: Colors.white,
//                       ),
//                       const SizedBox(height: 8),
//                       Container(
//                         height: 15,
//                         width: 150,
//                         color: Colors.white,
//                       ),
//                       const SizedBox(height: 10),
//                       Row(
//                         children: [
//                           Container(height: 15, width: 20, color: Colors.white),
//                           const SizedBox(width: 8),
//                           Container(height: 15, width: 20, color: Colors.white),
//                           const SizedBox(width: 8),
//                           Container(height: 15, width: 20, color: Colors.white),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   String formatDate(String dateStr) {
//     try {
//       final date = DateTime.parse(dateStr);
//       // "hh:mm a" -> 12-hour format + AM/PM, "MMMM" -> full month name
//       final time = DateFormat('hh:mm a').format(date); // e.g. 11:18 AM
//       final day = date.day;
//       final month = DateFormat('MMMM').format(date); // e.g. June
//       final year = date.year;
//       return "$time. $month $day, $year";
//     } catch (e) {
//       return dateStr;
//     }
//   }
// }

import 'package:babyland/app/controller/pregnancy_flow/pregnancy_controller.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/material.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/custom_textform_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/images.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/app_popup.dart';
import '../../widgets/container.dart';

class CommunityView extends StatefulWidget {

  bool backButton;
  CommunityView({super.key,this.backButton=true});

  @override
  State<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _filteredPosts = [];
  List<dynamic> _allPosts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PregnancyController>();
      provider.getCommunitiesData();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredPosts.clear();
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredPosts = _allPosts.where((post) {
          final userName = post?.userId?.name?.toLowerCase() ?? '';
          final message = post?.message?.toLowerCase() ?? '';
          final hashtags = post?.hashtags?.join(' ')?.toLowerCase() ?? '';

          return userName.contains(query) ||
              message.contains(query) ||
              hashtags.contains(query);
        }).toList();
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filteredPosts.clear();
    });
  }

  @override
  Widget build(BuildContext context) {

    final provider = context.watch<PregnancyController>();

    if (provider.isLoadingComm) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildShimmerLoader(),
      );
    }

    if (provider.communitiesApiData?.status == false) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Text(
              provider.communitiesApiData?.message ?? "Something went wrong!",
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final data = provider.communitiesApiData?.data;
    _allPosts = data?.data?.posts ?? [];

    if (_allPosts.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: const Center(child: Text("No posts found."))),
      );
    }

    final displayPosts = _isSearching ? _filteredPosts : _allPosts;

    return Scaffold(
      appBar: CustomAppBar(
        isNavbarTab: true,
        title: Text(
          "Community",
          style: AppFontStyle.text_20_400(
            color: AppColors.textClr,
            fontFamily: AppFontFamily.gilroySemiBold,
          ),
        ),
        centerTitle: true,
      ),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: Column(
          children: [
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CustomTextFormField(
                controller: _searchController,
                borderColor: AppColors.borderColor,
                suffix: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textLightClr,
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                )
                    : Icon(
                  Icons.search,
                  color: AppColors.textLightClr,
                  size: 24,
                ),
                hintText: "Search Discussions",
                hintStyle: AppFontStyle.text_13_400(
                  fontFamily: AppFontFamily.gilroyRegular,
                  color: AppColors.textLightClr,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(
                            child: Text(
                              "All",
                              style: AppFontStyle.text_16_400(
                                fontFamily: AppFontFamily.gilroySemiBold,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          Tab(
                            child: Text(
                              "For you",
                              style: AppFontStyle.text_16_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                                color: AppColors.textLightClr,
                              ),
                            ),
                          ),
                        ],
                        indicatorPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        unselectedLabelColor: AppColors.textLightClr,
                        labelColor: AppColors.black,
                        indicatorColor: AppColors.black,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: AppFontStyle.text_16_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                        ),
                        unselectedLabelStyle: AppFontStyle.text_16_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab 1: All
                            RefreshIndicator(
                              onRefresh: () async {
                                await provider.getCommunitiesData();
                                // After refresh, update the search if active
                                if (_searchController.text.isNotEmpty) {
                                  _onSearchChanged();
                                }
                              },
                              child: _isSearching && _filteredPosts.isEmpty
                                  ? _buildNoSearchResults()
                                  : ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                itemCount: displayPosts.length,
                                itemBuilder: (_, index) {
                                  final post = displayPosts[index];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: AppContainer(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 25,
                                                backgroundImage: AssetImage(
                                                    'assets/images/girl.png') as ImageProvider,
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    post?.userId?.name ?? "",
                                                    style:
                                                    AppFontStyle.text_18_400(
                                                      fontFamily: AppFontFamily
                                                          .gilroySemiBold,
                                                    ),
                                                  ),
                                                  Text(
                                                    "@${post?.userId?.name ?? ""}",
                                                    style:
                                                    AppFontStyle.text_16_400(
                                                      fontFamily: AppFontFamily
                                                          .gilroyRegular,
                                                      color:
                                                      AppColors.textLightClr,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            post?.message ??"",
                                            maxLines: 5,
                                            style: AppFontStyle.text_14_400(
                                              fontFamily:
                                              AppFontFamily.gilroyMedium,
                                            ),
                                          ),
                                          if (post?.hashtags != null && post!.hashtags!.isNotEmpty)...[
                                            const SizedBox(height: 8),
                                            Text(
                                              post.hashtags!.join(" ") ?? "",
                                              style: AppFontStyle.text_14_400(
                                                fontFamily: AppFontFamily.gilroyMedium,
                                              ),
                                            )],
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [

                                              InkWell(
                                                  onTap: (){
                                                    pt("this is id here ${post?.sId}");
                                                    provider.lieApi(likeId:post?.sId );
                                                  },
                                                  child: const Icon(Icons.favorite_border)),
                                              const SizedBox(width: 4),
                                              Text(
                                                post?.likes?.length.toString() ?? "0",
                                                style: AppFontStyle.text_14_400(
                                                  fontFamily:
                                                  AppFontFamily.gilroyMedium,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                  Icons.chat_bubble_outline),
                                              const SizedBox(width: 4),
                                              Text(
                                                post?.commentsCount?.toString() ?? "0",
                                                style: AppFontStyle.text_14_400(
                                                  fontFamily:
                                                  AppFontFamily.gilroyMedium,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              CustomImage(
                                                path: "assets/images/save.png",
                                                scale: 4,
                                                color: AppColors.black,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            post?.createdAt != null ? formatDate(post?.createdAt ?? "") : "",
                                            style: AppFontStyle.text_14_400(
                                              fontFamily:
                                              AppFontFamily.gilroyMedium,
                                              color: AppColors.textLightClr,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Tab 2: For you (with search)
                            RefreshIndicator(
                              onRefresh: () async {
                                await provider.getCommunitiesData();
                                // After refresh, update the search if active
                                if (_searchController.text.isNotEmpty) {
                                  _onSearchChanged();
                                }
                              },
                              child: _isSearching && _filteredPosts.isEmpty
                                  ? _buildNoSearchResults()
                                  : _buildForYouTab(displayPosts),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: InkWell(
        onTap: (){
          _showPostMessageDialog(context,provider);
        },
        child: AppContainer(
          gradient:AppColors.buttonClr,
          radius: 100,
          height: 54,
          width: 54,
          child: const Center(
            child: Icon(
              Icons.add,
              color: AppColors.white,
              size: 26,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textLightClr.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No results found for '${_searchController.text}'",
            style: AppFontStyle.text_16_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textLightClr,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _clearSearch,
            child: Text(
              "Clear search",
              style: AppFontStyle.text_14_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouTab(List<dynamic> displayPosts) {
    // You can implement your own logic for "For You" posts here
    // For now, it shows all posts when searching, or a placeholder
    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: displayPosts.length,
        itemBuilder: (_, index) {
          final post = displayPosts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AppContainer(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage(
                            'assets/images/girl.png') as ImageProvider,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post?.userId?.name ?? "",
                            style: AppFontStyle.text_18_400(
                              fontFamily: AppFontFamily.gilroySemiBold,
                            ),
                          ),
                          Text(
                            "@${post?.userId?.name ?? ""}",
                            style: AppFontStyle.text_16_400(
                              fontFamily: AppFontFamily.gilroyRegular,
                              color: AppColors.textLightClr,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post?.message ?? "",
                    maxLines: 5,
                    style: AppFontStyle.text_14_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                    ),
                  ),
                  if (post?.hashtags != null && post!.hashtags!.isNotEmpty)...[
                    const SizedBox(height: 8),
                    Text(
                      post.hashtags!.join(" ") ?? "",
                      style: AppFontStyle.text_14_400(
                        fontFamily: AppFontFamily.gilroyMedium,
                      ),
                    )],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border),
                      const SizedBox(width: 4),
                      Text(
                        post?.likes?.length.toString() ?? "0",
                        style: AppFontStyle.text_14_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chat_bubble_outline),
                      const SizedBox(width: 4),
                      Text(
                        post?.commentsCount?.toString() ?? "0",
                        style: AppFontStyle.text_14_400(
                          fontFamily: AppFontFamily.gilroyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomImage(
                        path: "assets/images/save.png",
                        scale: 4,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post?.createdAt != null ? formatDate(post?.createdAt ?? "") : "",
                    style: AppFontStyle.text_14_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.textLightClr,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group,
              size: 64,
              color: AppColors.textLightClr.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "Personalized posts coming soon!",
              style: AppFontStyle.text_16_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: AppColors.textLightClr,
              ),
            ),
          ],
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      isLeading: widget.backButton == true ? true : false,
      title: Text(
        "Community",
        style: AppFontStyle.text_20_400(
          color: AppColors.textClr,
          fontFamily: AppFontFamily.gilroySemiBold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildShimmerLoader() {
    return AppContainer(
      gradient: AppColors.backGroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: 4,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: AppContainer(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 15,
                            width: 120,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 40,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 15,
                        width: 150,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(height: 15, width: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Container(height: 15, width: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Container(height: 15, width: 20, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final time = DateFormat('hh:mm a').format(date);
      final day = date.day;
      final month = DateFormat('MMMM').format(date);
      final year = date.year;
      return "$time. $month $day, $year";
    } catch (e) {
      return dateStr;
    }
  }


  void _showPostMessageDialog(BuildContext context, PregnancyController provider) {

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              AppContainer(
                radius: 30,
                padding: EdgeInsets.all(12),
                gradient: AppColors.buttonClr,
                child: Icon(Icons.message, color: AppColors.white, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                "Post Message",
                style: AppFontStyle.text_18_600(
                  color: AppColors.textClr,
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Share your message with the community",
                style: AppFontStyle.text_14_400(
                  color: AppColors.textLightClr,
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              CustomTextFormField(
                controller: provider.msgController,
                height: 150,
                maxLines: 5,
                minLines: 5,
                borderColor: AppColors.borderColor,
                hintText: "Type your message here...",
                textInputType: TextInputType.multiline,
              ),
            ],
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () {
                provider.msgController.clear();
                Navigator.pop(dialogContext);

              },
              child: Text(
                "Cancel",
                style: AppFontStyle.text_16_500(
                  color: AppColors.textLightClr,
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
              ),
            ),
            // Post Button
            AppContainer(
              radius: 8,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              gradient: AppColors.buttonClr,
              child: InkWell(
                onTap: () {
                  final message = provider.msgController.text.trim();
                  if (message.isNotEmpty) {
                    provider.msgController.clear();
                    provider.postCreateApi(msg: message.toString());
                    Navigator.pop(dialogContext);
                  } else {
                    AppPopUp.showToast(
                      message: "Please enter a message",
                      lineColor: AppColors.red,
                    );
                  }
                },
                child: Text(
                  "Post",
                  style: AppFontStyle.text_16_600(
                    color: AppColors.white,
                    fontFamily: AppFontFamily.gilroySemiBold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}