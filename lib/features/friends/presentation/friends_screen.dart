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
  bool _busy = false;
  bool _searching = false;

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

  void _reload() => _snapshot = widget.repository.load();

  Future<void> _refresh() async {
    setState(_reload);
    await _snapshot;
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searchResult = null;
      _searchMessage = null;
    });
    try {
      final player = await widget.repository.findByCode(_searchController.text);
      if (!mounted) return;
      setState(() {
        _searchResult = player;
        _searchMessage = player == null ? 'NO PLAYER FOUND' : null;
      });
    } on FriendsException catch (error) {
      if (mounted) setState(() => _searchMessage = error.message.toUpperCase());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _act(
    Future<void> Function() callback,
    String successMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await callback();
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

  Future<void> _removeFriend(FriendPlayer player) async {
    final id = player.relationshipId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF07111D),
        title: const Text('REMOVE FRIEND?'),
        content: Text('Remove ${player.displayName} from your friends list?'),
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
    if (confirmed == true) {
      await _act(() => widget.repository.remove(id), 'Friend removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 360 ? 12.0 : 18.0;
    return Scaffold(
      backgroundColor: ReactColors.background,
      body: SafeArea(
        child: FutureBuilder<FriendsSnapshot>(
          future: _snapshot,
          builder: (context, snapshot) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 30),
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 18),
                  if (snapshot.hasData)
                    _Overview(data: snapshot.data!)
                  else if (snapshot.hasError)
                    _StatusCard(
                      icon: Icons.cloud_off_outlined,
                      title: 'FRIENDS UNAVAILABLE',
                      subtitle: 'Connect your online player profile and try again.',
                      color: ReactColors.coral,
                      action: TextButton(
                        onPressed: () => setState(_reload),
                        child: const Text('RETRY'),
                      ),
                    )
                  else
                    const SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  const SizedBox(height: 20),
                  const _SectionTitle('FIND A PLAYER', ReactColors.electricBlueBright),
                  const SizedBox(height: 9),
                  _SearchBar(
                    controller: _searchController,
                    busy: _busy || _searching,
                    onSearch: _search,
                  ),
                  if (_searchResult != null || _searchMessage != null) ...[
                    const SizedBox(height: 10),
                    if (_searchResult != null)
                      _SearchResult(
                        player: _searchResult!,
                        busy: _busy,
                        onAdd: () => _act(
                          () => widget.repository.sendRequest(_searchResult!.playerCode),
                          'Friend request sent.',
                        ),
                        onAccept: (id) => _act(
                          () => widget.repository.accept(id),
                          'Friend request accepted.',
                        ),
                        onDecline: (id) => _act(
                          () => widget.repository.decline(id),
                          'Friend request declined.',
                        ),
                        onCancel: (id) => _act(
                          () => widget.repository.cancel(id),
                          'Friend request cancelled.',
                        ),
                        onRemove: () => _removeFriend(_searchResult!),
                      )
                    else
                      _StatusCard(
                        icon: Icons.search_off_rounded,
                        title: _searchMessage!,
                        subtitle: 'Player codes look like RX-1A2B3C4D5E.',
                        color: ReactColors.textSecondary,
                      ),
                  ],
                  if (snapshot.hasData) ...[
                    const SizedBox(height: 20),
                    ..._relationshipSections(snapshot.data!),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _relationshipSections(FriendsSnapshot data) => [
        _SectionTitle(
          'REQUESTS${data.incoming.isEmpty ? '' : ' (${data.incoming.length})'}',
          ReactColors.coral,
        ),
        const SizedBox(height: 9),
        if (data.incoming.isEmpty)
          const _EmptyRelationship(
            icon: Icons.mark_email_read_outlined,
            title: 'NO INCOMING REQUESTS',
            subtitle: 'New requests will appear here.',
          )
        else
          for (final player in data.incoming) ...[
            _RelationshipCard(
              player: player,
              status: 'REQUEST',
              statusColor: ReactColors.coral,
              primary: 'ACCEPT',
              onPrimary: player.relationshipId == null
                  ? null
                  : () => _act(
                        () => widget.repository.accept(player.relationshipId!),
                        'Friend request accepted.',
                      ),
              secondary: 'DECLINE',
              onSecondary: player.relationshipId == null
                  ? null
                  : () => _act(
                        () => widget.repository.decline(player.relationshipId!),
                        'Friend request declined.',
                      ),
            ),
            const SizedBox(height: 9),
          ],
        const SizedBox(height: 18),
        _SectionTitle('FRIENDS (${data.friendCount})', ReactColors.lime),
        const SizedBox(height: 9),
        if (data.friends.isEmpty)
          const _EmptyRelationship(
            icon: Icons.group_outlined,
            title: 'NO FRIENDS YET',
            subtitle: 'Search an RX player code to build your list.',
          )
        else
          for (final player in data.friends) ...[
            _RelationshipCard(
              player: player,
              status: 'FRIEND',
              statusColor: ReactColors.lime,
              secondary: 'REMOVE',
              onSecondary: () => _removeFriend(player),
            ),
            const SizedBox(height: 9),
          ],
        const SizedBox(height: 18),
        const _SectionTitle('SENT REQUESTS', ReactColors.purple),
        const SizedBox(height: 9),
        if (data.outgoing.isEmpty)
          const _EmptyRelationship(
            icon: Icons.send_outlined,
            title: 'NOTHING PENDING',
            subtitle: 'Requests you send will appear here.',
          )
        else
          for (final player in data.outgoing) ...[
            _RelationshipCard(
              player: player,
              status: 'PENDING',
              statusColor: ReactColors.purple,
              secondary: 'CANCEL',
              onSecondary: player.relationshipId == null
                  ? null
                  : () => _act(
                        () => widget.repository.cancel(player.relationshipId!),
                        'Friend request cancelled.',
                      ),
            ),
            const SizedBox(height: 9),
          ],
      ];
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
        const Expanded(
          child: Column(
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
              Text(
                'YOUR RE△CT NETWORK',
                style: TextStyle(
                  color: ReactColors.electricBlueBright,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
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
  const _Overview({required this.data});

  final FriendsSnapshot data;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      icon: Icons.group_rounded,
      title: '${data.friendCount} FRIEND${data.friendCount == 1 ? '' : 'S'}',
      subtitle: data.pendingCount == 0
          ? 'No requests waiting'
          : '${data.pendingCount} incoming request${data.pendingCount == 1 ? '' : 's'}',
      color: ReactColors.electricBlueBright,
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.busy, required this.onSearch});

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_search_rounded, color: ReactColors.electricBlueBright),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !busy,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => onSearch(),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'RX-XXXXXXXXXX',
              ),
            ),
          ),
          FilledButton(
            onPressed: busy ? null : onSearch,
            child: busy
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('FIND'),
          ),
        ],
      ),
    );
  }
}

class _SearchResult extends StatelessWidget {
  const _SearchResult({
    required this.player,
    required this.busy,
    required this.onAdd,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    required this.onRemove,
  });

  final FriendPlayer player;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onDecline;
  final ValueChanged<String> onCancel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final id = player.relationshipId;
    final buttons = switch (player.relationshipState) {
      FriendRelationshipState.none => <Widget>[
          FilledButton(onPressed: busy ? null : onAdd, child: const Text('ADD FRIEND')),
        ],
      FriendRelationshipState.self => const <Widget>[
          _StatePill(label: 'THIS IS YOU', color: ReactColors.textSecondary),
        ],
      FriendRelationshipState.incoming => <Widget>[
          TextButton(onPressed: busy || id == null ? null : () => onDecline(id), child: const Text('DECLINE')),
          FilledButton(onPressed: busy || id == null ? null : () => onAccept(id), child: const Text('ACCEPT')),
        ],
      FriendRelationshipState.outgoing => <Widget>[
          TextButton(onPressed: busy || id == null ? null : () => onCancel(id), child: const Text('CANCEL')),
          const _StatePill(label: 'REQUEST SENT', color: ReactColors.purple),
        ],
      FriendRelationshipState.friend => <Widget>[
          TextButton(onPressed: busy ? null : onRemove, child: const Text('REMOVE')),
          const _StatePill(label: 'FRIEND', color: ReactColors.lime),
        ],
    };

    return _PlayerShell(player: player, actions: buttons);
  }
}

class _RelationshipCard extends StatelessWidget {
  const _RelationshipCard({
    required this.player,
    required this.status,
    required this.statusColor,
    this.primary,
    this.onPrimary,
    this.secondary,
    this.onSecondary,
  });

  final FriendPlayer player;
  final String status;
  final Color statusColor;
  final String? primary;
  final VoidCallback? onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return _PlayerShell(
      player: player,
      actions: [
        if (secondary != null)
          TextButton(onPressed: onSecondary, child: Text(secondary!)),
        if (primary != null)
          FilledButton(onPressed: onPrimary, child: Text(primary!))
        else
          _StatePill(label: status, color: statusColor),
      ],
    );
  }
}

class _PlayerShell extends StatelessWidget {
  const _PlayerShell({required this.player, required this.actions});

  final FriendPlayer player;
  final List<Widget> actions;

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
          const SizedBox(width: 7),
          Flexible(
            child: Wrap(
              spacing: 5,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: actions,
            ),
          ),
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
    return Container(
      width: 46,
      height: 46,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ReactColors.panel,
        border: Border.all(color: ReactColors.electricBlue.withValues(alpha: .45)),
      ),
      child: player.avatarUrl == null
          ? const Icon(Icons.person_rounded, color: ReactColors.textSecondary)
          : Image.network(
              player.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person_rounded,
                color: ReactColors.textSecondary,
              ),
            ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: color.withValues(alpha: .32)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReactColors.textPrimary,
                    fontSize: 13,
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
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _EmptyRelationship extends StatelessWidget {
  const _EmptyRelationship({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => _StatusCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        color: ReactColors.textSecondary,
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label, this.color);

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
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(child: Divider(color: color.withValues(alpha: .28))),
      ],
    );
  }
}
