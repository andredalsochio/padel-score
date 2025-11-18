import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/viewmodel/auth_view_model.dart';
import '../widgets/greeting_header.dart';
import '../widgets/section_header.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/recent_match_card.dart';
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: const SectionHeader(
                title: 'Ações rápidas',
                icon: Icons.flash_on,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: QuickActionsBar(
              actions: [
                QuickAction(
                  label: 'Registrar Jogo',
                  icon: Icons.sports_tennis,
                  onTap: () => context.push('/games/register'),
                ),
                QuickAction(
                  label: 'Jogadores',
                  icon: Icons.group_add,
                  onTap: () => context.push('/players'),
                ),
                QuickAction(
                  label: 'Patotas',
                  icon: Icons.groups,
                  onTap: () => context.push('/patotas'),
                ),
                QuickAction(
                  label: 'Ranking',
                  icon: Icons.bar_chart,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ranking — coming soon')),
                  ),
                ),
              ],
            ),
          ),

          // Recent Matches section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: const SectionHeader(
                title: 'Recent Matches',
                icon: Icons.history,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 170,
              child: PageView.builder(
                controller: _matchesController,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: RecentMatchCard(
                      duoA: 'Joao & Rodrigo',
                      duoB: 'Andre & Leonardo',
                      scores: const ['6×0', '4×7', '4×6'],
                      winnerDuo: index % 2 == 0
                          ? 'Joao & Rodrigo'
                          : 'Andre & Leonardo',
                    ),
                  );
                },
              ),
            ),
          ),

          // Ranking Summary expandable card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
