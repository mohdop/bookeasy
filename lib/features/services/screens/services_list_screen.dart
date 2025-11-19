import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/service_card.dart';
import '../../../data/providers/supabase_provider.dart';
import '../../../data/models/service.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  List<Service> _services = [];
  bool _isLoading = true;
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);

    try {
      // Get business ID
      final businessData = await SupabaseProvider.table('businesses')
          .select('id')
          .eq('owner_id', SupabaseProvider.currentUserId!)
          .single();
      
      _businessId = businessData['id'];

      // Load services
      final servicesData = await SupabaseProvider.table('services')
          .select('*')
          .eq('business_id', _businessId!)
          .order('order_index');

      _services = servicesData.map((json) => Service.fromJson(json)).toList();
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteService(Service service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le service'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${service.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseProvider.table('services')
          .delete()
          .eq('id', service.id);

      if (mounted) {
        context.showSnackBar('Service supprimé');
        _loadServices();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Erreur: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              context.push('/services/create');
              _loadServices();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Chargement des services...')
          : _services.isEmpty
              ? EmptyState(
                  icon: Icons.list_alt,
                  title: 'Aucun service',
                  message: 'Commencez par créer votre premier service',
                  actionText: 'Créer un service',
                  onAction: () async {
                     context.push('/services/create');
                    _loadServices();
                  },
                )
              : RefreshIndicator(
                  onRefresh: _loadServices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return ServiceCard(
                        service: service,
                        onEdit: () async {
                           context.push('/services/edit/${service.id}');
                          _loadServices();
                        },
                        onDelete: () => _deleteService(service),
                      );
                    },
                  ),
                ),
      floatingActionButton: _services.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                 context.push('/services/create');
                _loadServices();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouveau service'),
            )
          : null,
    );
  }
}