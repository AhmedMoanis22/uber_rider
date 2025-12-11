import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../bussiness_logic/map_cubit/map_cubit.dart';
import '../../bussiness_logic/map_cubit/user_cubit/user_cubit.dart';
import '../../bussiness_logic/map_cubit/user_cubit/user_state.dart';
import '../../bussiness_logic/ride_tracking_cubit/ride_tracking_cubit.dart';

void showRatingDialog(BuildContext context, String rideId) {
  int rating = 0;
  final reviewController = TextEditingController();
  final trackingCubit = context.read<RideTrackingCubit>();
  final userCubit = context.read<UserCubit>();
  final mapCubit = context.read<MapCubit>();

  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
            value: userCubit,
            child: StatefulBuilder(
              builder: (context, setState) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 10,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rate_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title
                          const Text(
                            'Rate Your Ride',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'How was your experience?',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Star Rating with Container
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: rating > 0
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.grey[200]!,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        rating = index + 1;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Icon(
                                      index < rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: index < rating
                                          ? Colors.amber
                                          : Colors.grey[300],
                                      size: 40,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          if (rating > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              rating == 5
                                  ? 'Excellent!'
                                  : rating >= 4
                                      ? 'Great!'
                                      : rating >= 3
                                          ? 'Good'
                                          : 'Could be better',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Review TextField
                          TextField(
                            controller: reviewController,
                            decoration: InputDecoration(
                              hintText: 'Share your feedback (optional)',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: Colors.grey[200]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              prefixIcon: const Icon(Icons.edit_note_rounded,
                                  color: AppColors.primary),
                            ),
                            maxLines: 3,
                            maxLength: 200,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    mapCubit.clearRoute();
                                    trackingCubit.reset();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Skip',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: BlocConsumer<UserCubit, UserState>(
                                  listener: (context, state) {
                                    if (state is RateRideSuccessState) {
                                      Navigator.of(dialogContext).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle,
                                                  color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: Text(state.message)),
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                      mapCubit.clearRoute();
                                      trackingCubit.reset();
                                    } else if (state is RateRideErrorState) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.error_outline,
                                                  color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child:
                                                      Text(state.errorMessage)),
                                            ],
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  builder: (context, state) {
                                    if (state is RateRideLoadingState) {
                                      return ElevatedButton(
                                        onPressed: null,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          backgroundColor: AppColors.primary,
                                          disabledBackgroundColor: AppColors
                                              .primary
                                              .withOpacity(0.6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                      );
                                    }
                                    return ElevatedButton(
                                      onPressed: rating > 0 && rideId.isNotEmpty
                                          ? () {
                                              context
                                                  .read<UserCubit>()
                                                  .rateRide(
                                                    rideId: rideId,
                                                    rating: rating,
                                                    review: reviewController
                                                        .text
                                                        .trim(),
                                                  );
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor:
                                            Colors.grey[300],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Submit Rating',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ));
}
