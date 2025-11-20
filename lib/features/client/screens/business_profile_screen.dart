import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../data/providers/supabase_provider.dart';
import '../../../data/models/business.dart';
import '../../../data/models/service.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String businessId;

  const BusinessProfileScreen({super.key, required this.businessId});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  Business? _business;
  List<Service> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load business
      final businessData = await SupabaseProvider.table('businesses')
          .select('*')
          .eq('id', widget.businessId)
          .maybeSingle();
      
      _business = Business.fromJson(businessData!);

      // Load services
      final servicesData = await SupabaseProvider.table('services')
          .select('*')
          .eq('business_id', widget.businessId)
          .eq('is_active', true)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingIndicator()
          : CustomScrollView(
              slivers: [
                // App Bar with Business Info
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      _business?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.business,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Business Details
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 20,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _business?.category.displayName ?? '',
                              style: ContextExtension(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        
                        if (_business?.description != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _business!.description!,
                            style: ContextExtension(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.gray,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        // Contact Info
                        _ContactInfo(
                          icon: Icons.phone,
                          text: _business?.phone ?? '',
                        ),
                        const SizedBox(height: 12),
                        if (_business?.email != null)
                          _ContactInfo(
                            icon: Icons.email,
                            text: _business!.email!,
                          ),
                        const SizedBox(height: 12),
                        _ContactInfo(
                          icon: Icons.location_on,
                          text: '${_business?.address}, ${_business?.postalCode} ${_business?.city}',
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Services Section Header
                SliverToBoxAdapter(
                  child: Container(
                    color: AppTheme.background,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      'Nos services',
                      style: ContextExtension(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                
                // Services List
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _services[index];
                        return _ServiceListItem(
                          service: service,
                          onTap: () {
                            context.push(
                              '/booking/${widget.businessId}?serviceId=${service.id}',
                            );
                          },
                        );
                      },
                      childCount: _services.length,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: !_isLoading && _services.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/booking/${widget.businessId}');
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Réserver'),
            )
          : null,
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.gray),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: ContextExtension(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;

  const _ServiceListItem({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.content_cut,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: ContextExtension(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.gray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.formattedDuration,
                          style: ContextExtension(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                service.formattedPrice,
                style: ContextExtension(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.gray,
              ),
            ],
          ),
        ),
      ),
    );
  }
}