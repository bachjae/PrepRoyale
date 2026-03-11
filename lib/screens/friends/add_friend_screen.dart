import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../providers/friends_provider.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _friendCodeController = TextEditingController();
  final _focusNode = FocusNode();
  bool _requestSent = false;

  @override
  void dispose() {
    _friendCodeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFriendCodeChanged(String value) {
    // Clear any previous lookup when code changes
    if (value.length != 8) {
      ref.read(friendsProvider.notifier).clearFriendCodeLookup();
      setState(() {
        _requestSent = false;
      });
    }
  }

  void _lookupFriendCode() {
    final code = _friendCodeController.text.trim();
    if (code.length == 8) {
      _focusNode.unfocus();
      setState(() {
        _requestSent = false;
      });
      ref.read(friendsProvider.notifier).lookupUserByFriendCode(code);
    }
  }

  Future<void> _sendFriendRequest() async {
    final code = _friendCodeController.text.trim();
    final success = await ref
        .read(friendsProvider.notifier)
        .sendFriendRequestByCode(code);

    if (success && mounted) {
      setState(() {
        _requestSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);

    // Show error snackbar if there's an error
    ref.listen<FriendsState>(friendsProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(friendsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter your friend\'s 8-character code to add them.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Friend code input
            Text(
              'Friend Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _friendCodeController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'e.g., ABC12345',
                prefixIcon: const Icon(Icons.person_search),
                suffixIcon: friendsState.isLookingUpFriendCode
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _friendCodeController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _friendCodeController.clear();
                              ref.read(friendsProvider.notifier).clearFriendCodeLookup();
                              setState(() {
                                _requestSent = false;
                              });
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                counterText: '${_friendCodeController.text.length}/8',
              ),
              maxLength: 8,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                // Only allow valid friend code characters (exclude 0, O, 1, I for clarity)
                FilteringTextInputFormatter.allow(RegExp(r'[A-HJ-NP-Za-hj-np-z2-9]')),
                UpperCaseTextFormatter(),
              ],
              onChanged: (value) {
                setState(() {}); // Rebuild to update counter
                _onFriendCodeChanged(value);
              },
              onSubmitted: (_) => _lookupFriendCode(),
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 16),

            // Look up button
            FilledButton.icon(
              onPressed: _friendCodeController.text.length == 8 &&
                      !friendsState.isLookingUpFriendCode
                  ? _lookupFriendCode
                  : null,
              icon: const Icon(Icons.search),
              label: const Text('Look Up Friend'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 32),

            // User preview card
            if (friendsState.isLookingUpFriendCode)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (friendsState.friendCodeLookupResult != null)
              _UserPreviewCard(
                user: friendsState.friendCodeLookupResult!,
                isLoading: friendsState.isLoading,
                requestSent: _requestSent,
                onSendRequest: _sendFriendRequest,
              )
            else if (_friendCodeController.text.isEmpty)
              _buildEmptyState(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.qr_code,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter a Friend Code',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask your friend for their 8-character code\nYou can find your code on the Friends screen',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _UserPreviewCard extends StatelessWidget {
  final FriendCodeLookupResult user;
  final bool isLoading;
  final bool requestSent;
  final VoidCallback onSendRequest;

  const _UserPreviewCard({
    required this.user,
    required this.isLoading,
    required this.requestSent,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // User info
          CircleAvatar(
            radius: 40,
            backgroundImage: user.profilePictureUrl != null
                ? CachedNetworkImageProvider(user.profilePictureUrl!)
                : null,
            child: user.profilePictureUrl == null
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.username,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Level ${user.level}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 20),

          // Action button
          SizedBox(
            width: double.infinity,
            child: requestSent
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text(
                      'Request Sent',
                      style: TextStyle(color: Colors.green),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: isLoading ? null : onSendRequest,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add),
                    label: Text(isLoading ? 'Sending...' : 'Send Friend Request'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Input formatter to convert text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
