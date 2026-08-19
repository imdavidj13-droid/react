import 'package:flutter/material.dart';

import '../../../core/theme/react_colors.dart';
import '../data/friends_repository.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, this.repository = const FriendsRepository()});

  final FriendsRepository repository;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  late Future<FriendsSnapshot> _snapshot;
  FriendPlayer? _searchResult;
  String? _searchMessage;
  bool _searching = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _snapshot = widget.repository.load();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _snapshot;
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searchMessage = null;
      _searchResult = null;
    });

    try {
      final result = await widget.repository.findByCode(_searchController.text);
      if (!mounted) return;
      setState(() {
        _searchResult = result;
        _searchMessage = result == null ? 'NO PLAYER FOUND' : null;
      });
    } on FriendsException catch (error) {
      if (!mounted) return;
      setState(() => _searchMessage = error.message.toUpperCase());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _reload();
        _searchResult = null;
        _searchMessage = successMessage.toUpperCase();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } on FriendsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRemove(FriendPlayer player) async {
    final relationshipId = player.relationshipId;
    if (relationshipId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF07111D),
        title: const Text('REMOVE FRIEND?'),
        content: Text(
          '${player.displayName} will be removed from your friends list. You can add each other again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ReactColors.coral),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(
      () => widget.repository.remove(relationshipId),
      successMessage: 'Friend removed.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPad = MediaQuery.sizeOf(context).width < 360 ? 12.0 : 18.0;
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<FriendsSnapshot>(
          future: _snapshot,
          builder: (context, snapshot) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontalPad, 10, horizontalPad, 30),
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 18),
                  if (snapshot.hasData)
                    _Overview(snapshot: snapshot.requireData)
                  else if (snapshot.hasError)
                    _OfflineCard(onRetry: () => setState(_reload))
                  else
                    const _OverviewLoading(),
                  const SizedBox(height: 18),
                  _SectionTitle(label: 'FIND A PLAYER', color: ReactColors.electricBlueBright),
                  const SizedBox(height: 9),
                  _SearchPanel(
                    controller: _searchController,
                    searching: _searching,
                    enabled: !_busy,
                    onSearch: _search,
                  ),
                  if (_searchResult != null || _searchMessage != null) ...[
                    const SizedBox(height: 10),
                    if (_searchResult != null)
                      _SearchResultCard(
                        player: _searchResult!,
                        busy: _busy,
                        onAdd: () => _runAction(
                          () => widget.repository.sendRequest(_searchResult!.playerCode),
                          successMessage: 'Friend request sent.',
                        ),
                        onAccept: _searchResult!.relationshipId == null
                            ? null
                            : () => _runAction(
                                  () => widget.repository.accept(_searchResult!.relationshipId!),
                                  successMessage: 'Friend request accepted.',
                                ),
                        onDecline: _searchResult!.relationshipId == null
                            ? null
                            : () => _runAction(
                                  () => widget.repository.decline(_searchResult!.relationshipId!),
                                  successMessage: 'Friend request declined.',
                                ),
                        onCancel: _searchResult!.relationshipId == null
                            ? null
                            : () => _runAction(
                                  () => widget.repository.cancel(_searchResult!.relationshipId!),
                                  successMessage: 'Friend request cancelled.',
                                ),
                        onRemove: () => _confirmRemove(_searchResult!),
                      )
                    else
                      _SearchMessage(message: _searchMessage!),
                  ],
                  const SizedBox(height: 20),
                  if (snapshot.hasData) ..._sections(snapshot.requireData),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sections(FriendsSnapshot data) {
    return [
      _SectionTitle(
        label: 'REQUESTS ${data.incoming.isEmpty ? '' : '(${data.incoming.length})'}',
        color: ReactColors.coral,
      ),
      const SizedBox(height: 9),
      if (data.incoming.isEmpty)
        const _EmptyCard(
          icon: Icons.mark_email_read_outlined,
          title: 'NO INCOMING REQUESTS',
          subtitle: 'New friend requests will appear here.',
        )
      else
        for (final player in data.incoming) ...[
          _PlayerCard(
            player: player,
            primaryLabel: 'ACCEPT',
            primaryColor: ReactColors.lime,
            onPrimary: player.relationshipId == null
                ? null
                : () => _runAction(
                      () => widget.repository.accept(player.relationshipId!),
                      successMessage: 'Friend request accepted.',
                    ),
            secondaryLabel: 'DECLINE',
            onSecondary: player.relationshipId == null
                ? null
                : () => _runAction(
                      () => widget.repository.decline(player.relationshipId!),
                      successMessage: 'Friend request declined.',
                    ),
          ),
          const SizedBox(height: 9),
        ],
      const SizedBox(height: 18),
      _SectionTitle(label: 'FRIENDS (${data.friendCount})', color: ReactColors.lime),
      const SizedBox(height: 9),
      if (data.friends.isEmpty)
        const _EmptyCard(
          icon: Icons.group_outlined,
          title: 'NO FRIENDS YET',
          subtitle: 'Search an RX player code to start building your list.',
        )
      else
        for (final player in data.friends) ...[
          _PlayerCard(
            player: player,
            primaryLabel: 'FRIEND',
            primaryColor: ReactColors.lime,
            onPrimary: null,
            secondaryLabel: 'REMOVE',
            onSecondary: () => _confirmRemove(player),
          ),
          const SizedBox(height: 9),
        ],
      const SizedBox(height: 18),
      _SectionTitle(label: 'SENT REQUESTS', color: ReactColors.purple),
      const SizedBox(height: 9),
      if (data.outgoing.isEmpty)
        const _EmptyCard(
          icon: Icons.send_outlined,
          title: 'NOTHING PENDING',
          subtitle: 'Requests you send will stay here until accepted or cancelled.',
        )
      else
        for (final player in data.outgoing) ...[
          _PlayerCard(
            player: player,
            primaryLabel: 'PENDING',
            primaryColor: ReactColors.purple,
            onPrimary: null,
            secondaryLabel: 'CANCEL',
            onSecondary: player.relationshipId == null
                ? null
                : () => _runAction(
                      () => widget.repository.cancel(player.relationshipId!),
                      successMessage: 'Friend request cancelled.',
                    ),
          ),
          const SizedBox(height: 9),
        ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF07101E),
            side: const BorderSide(color: Color(0xFF203854)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'FRIENDS',
                style: TextStyle(
                  color: ReactColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'YOUR RE△CT NETWORK',
                style: TextStyle(
                  color: ReactColors.electricBlueBright,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.snapshot});

  final FriendsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .35)),
        boxShadow: [
          BoxShadow(
            color: ReactColors.electricBlue.withValues(alpha: .08),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          const _OverviewIcon(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SOCIAL LINK',
                  style: TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${snapshot.friendCount} FRIEND${snapshot.friendCount == 1 ? '' : 'S'}',
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  snapshot.pendingCount == 0
                      ? 'No requests waiting'
                      : '${snapshot.pendingCount} request${snapshot.pendingCount == 1 ? '' : 's'} waiting',
                  style: TextStyle(
                    color: snapshot.pendingCount == 0
                        ? ReactColors.textSecondary
                        : ReactColors.coral,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewIcon extends StatelessWidget {
  const _OverviewIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ReactColors.electricBlue.withValues(alpha: .11),
        border: Border.all(color: ReactColors.electricBlueBright.withValues(alpha: .7)),
      ),
      child: const Icon(Icons.group_rounded, color: ReactColors.electricBlueBright, size: 27),
    );
  }
}

class _OverviewLoading extends StatelessWidget {
  const _OverviewLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 88,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _OfflineCard extends StatelessWidget {
  const _OfflineCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ReactColors.coral.withValues(alpha: .38)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: ReactColors.coral, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FRIENDS UNAVAILABLE',
                  style: TextStyle(color: ReactColors.textPrimary, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Connect your player profile to load friends and requests.',
                  style: TextStyle(color: ReactColors.textSecondary, fontSize: 9, height: 1.3),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('RETRY')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: color.withValues(alpha: .28))),
      ],
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.searching,
    required this.enabled,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool searching;
  final bool enabled;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .32)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_search_rounded, color: ReactColors.electricBlueBright),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => onSearch(),
              style: const TextStyle(
                color: ReactColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'RX-XXXXXXXXXX',
                hintStyle: TextStyle(color: ReactColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: enabled && !searching ? onSearch : null,
              child: searching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('FIND'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.player,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  final FriendPlayer player;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    String primary;
    VoidCallback? action;
    Color color;
    switch (player.relationshipState) {
      case FriendRelationshipState.none:
        primary = 'ADD FRIEND';
        action = onAdd;
        color = ReactColors.electricBlueBright;
      case FriendRelationshipState.self:
        primary = 'THIS IS YOU';
        action = null;
        color = ReactColors.textSecondary;
      case FriendRelationshipState.incoming:
        primary = 'ACCEPT';
        action = onAccept;
        color = ReactColors.lime;
      case FriendRelationshipState.outgoing:
        primary = 'REQUEST SENT';
        action = null;
        color = ReactColors.purple;
      case FriendRelationshipState.friend:
        primary = 'FRIEND';
        action = null;
        color = ReactColors.lime;
    }

    return _PlayerShell(
      player: player,
      trailing: Wrap(
        spacing: 7,
        runSpacing: 6,
        alignment: WrapAlignment.end,
        children: [
          if (player.relationshipState == FriendRelationshipState.incoming && onDecline != null)
            TextButton(onPressed: busy ? null : onDecline, child: const Text('DECLINE')),
          if (player.relationshipState == FriendRelationshipState.outgoing && onCancel != null)
            TextButton(onPressed: busy ? null : onCancel, child: const Text('CANCEL')),
          if (player.relationshipState == FriendRelationshipState.friend)
            TextButton(onPressed: busy ? null : onRemove, child: const Text('REMOVE')),
          FilledButton(
            onPressed: busy ? null : action,
            style: FilledButton.styleFrom(
              backgroundColor: color.withValues(alpha: action == null ? .16 : 1),
              foregroundColor: action == null ? color : ReactColors.background,
            ),
            child: Text(primary),
          ),
        ],
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ReactColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ReactColors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .9,
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.primaryLabel,
    required this.primaryColor,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final FriendPlayer player;
  final String primaryLabel;
  final Color primaryColor;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return _PlayerShell(
      player: player,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: .35)),
            ),
            child: Text(
              primaryLabel,
              style: TextStyle(
                color: primaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ),
          const SizedBox(height: 5),
          if (onPrimary != null)
            TextButton(onPressed: onPrimary, child: Text(primaryLabel))
          else if (onSecondary != null)
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
          if (onPrimary != null && onSecondary != null)
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel)),
        ],
      ),
    );
  }
}

class _PlayerShell extends StatelessWidget {
  const _PlayerShell({required this.player, required this.trailing});

  final FriendPlayer player;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReactColors.border),
      ),
      child: Row(
        children: [
          _Avatar(player: player),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  player.playerCode,
                  style: const TextStyle(
                    color: ReactColors.electricBlueBright,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.player});

  final FriendPlayer player;

  @override
  Widget build(BuildContext context) {
    final url = player.avatarUrl;
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ReactColors.panel,
        border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .45)),
      ),
      child: url == null
          ? const Icon(Icons.person_rounded, color: ReactColors.textSecondary, size: 26)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person_rounded,
                color: ReactColors.textSecondary,
                size: 26,
              ),
            ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReactColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: ReactColors.textSecondary, size: 25),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ReactColors.textSecondary,
                    fontSize: 9,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
