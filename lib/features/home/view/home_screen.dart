import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/viewmodel/auth_view_model.dart';
import '../widgets/greeting_header.dart';
import '../widgets/section_header.dart';
import '../widgets/horizontal_cards.dart';
import '../widgets/action_card.dart';
import '../widgets/recent_match_placeholder.dart';
import '../widgets/ranking_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _rankingExpanded = false;
  final PageController _matchesController = PageController(
    viewportFraction: 0.92,
  );

  @override
  void dispose() {
    _matchesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: scheme.surface,
            surfaceTintColor: scheme.surfaceTint,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: GreetingHeader(
                  title: 'Hello, André 👋',
                  subtitle: 'Your padel hub — fast and fluid',
                  onProfileTap: () {},
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: authVm.isLoading ? null : authVm.signOut,
              ),
            ],
          ),

          // Quick Actions section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: const SectionHeader(
                title: 'Quick Actions',
                icon: Icons.flash_on,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: HorizontalCards(
                children: [
                  ActionCard(
                    heroTag: 'register_game',
                    title: 'Register Game',
                    description: 'Start a new match now',
                    icon: Icons.sports_tennis,
                    gradient: [scheme.primary, scheme.primaryContainer],
                    onTap: () {
                      context.push('/games/register');
                    },
                  ),
                  ActionCard(
                    heroTag: 'add_players',
                    title: 'Add Players',
                    description: 'Invite or create profiles',
                    icon: Icons.group_add,
                    gradient: [scheme.secondary, scheme.secondaryContainer],
                    onTap: () {
                      context.push('/players');
                    },
                  ),
                  ActionCard(
                    heroTag: 'view_ranking',
                    title: 'View Ranking',
                    description: 'Top pairs and players',
                    icon: Icons.bar_chart,
                    gradient: [scheme.tertiary, scheme.tertiaryContainer],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ranking — coming soon')),
                      );
                    },
                  ),
                  ActionCard(
                    heroTag: 'tournaments',
                    title: 'Tournaments',
                    description: 'Browse and manage',
                    icon: Icons.emoji_events,
                    gradient: [scheme.primary, scheme.tertiary],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tournaments — coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Recent Matches section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: const SectionHeader(
                title: 'Recent Matches',
                icon: Icons.history,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: PageView.builder(
                controller: _matchesController,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: RecentMatchPlaceholder(index: index),
                  );
                },
              ),
            ),
          ),

          // Ranking Summary expandable card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: RankingSummaryCard(
                expanded: _rankingExpanded,
                onToggle: () =>
                    setState(() => _rankingExpanded = !_rankingExpanded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
