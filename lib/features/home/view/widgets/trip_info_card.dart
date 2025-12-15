import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Widget to display trip information with pickup and dropoff locations
class TripInfoCard extends StatelessWidget {
  final LatLng fromLocation;
  final LatLng toLocation;
  final String? fromAddress;
  final String? toAddress;
  final VoidCallback onCancel;
  final VoidCallback onRequestRide;
  final bool isRequesting;

  const TripInfoCard({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    this.fromAddress,
    this.toAddress,
    required this.onCancel,
    required this.onRequestRide,
    this.isRequesting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLocationInfo(
              icon: Icons.trip_origin,
              color: Colors.red,
              label: 'From',
              address: fromAddress ??
                  '${fromLocation.latitude.toStringAsFixed(4)}, ${fromLocation.longitude.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 8),
            _buildLocationInfo(
              icon: Icons.location_on,
              color: Colors.green,
              label: 'To',
              address: toAddress ??
                  '${toLocation.latitude.toStringAsFixed(4)}, ${toLocation.longitude.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $address',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isRequesting ? null : onRequestRide,
            icon: isRequesting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.car_rental, size: 18),
            label: Text(isRequesting ? 'Requesting...' : 'Request Ride'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
