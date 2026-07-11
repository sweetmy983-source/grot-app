// modules/plant/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../plant_provider.dart';
import '../widgets/plant_card.dart';
import 'plant_detail_screen.dart';
import 'plant_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('내 화분')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<PlantProvider>().load(),
        child: _buildBody(provider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(PlantProvider provider) {
    if (provider.loading && provider.plants.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (provider.isEmpty) return _emptyState();
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: provider.plants.length,
      itemBuilder: (context, i) => _PlantCardTile(plantId: provider.plants[i].id!),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const
