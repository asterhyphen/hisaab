part of 'friend_list_page.dart';

extension _HomePageTab on _FriendListPageState {
  Widget _buildHomeBody() {
    final isEmpty = displayedKeys.isEmpty;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: context.hisaabFontFamily,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                labelText: 'Search user',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: context.hisaabFontFamily,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'total_pending: ₹${getOverallTotal().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: context.hisaabFontFamily,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    searchController.text.isEmpty
                        ? r'$ user_not_found()'
                        : 'search for "${searchController.text}" is not found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontFamily: context.hisaabFontFamily,
                      height: 1.6,
                    ),
                  ),
                  if (searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final nameToPush = searchController.text.trim();
                        addFriend(nameToPush);
                      },
                      child: Text(
                        'Create "${searchController.text}"',
                        style: TextStyle(
                          fontFamily: context.hisaabFontFamily,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Text(
                      'type "+  icon" to create_user()',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: context.hisaabFontFamily,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final key = displayedKeys.elementAt(index);
                  final transactions = box.get(key) as List;
                  final total = calculateTotal(transactions);
                  bool pressed = false;

                  return StatefulBuilder(
                    builder: (context, setInnerState) {
                      return AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_fadeAnimation.value * 10, 0),
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              constraints: const BoxConstraints(
                                minHeight: 70,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            Dismissible(
                              key: ValueKey(key),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => deleteFriend(key),
                              background: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 70,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTapDown: (_) => setInnerState(() => pressed = true),
                                onTapUp: (_) => setInnerState(() => pressed = false),
                                onTapCancel: () => setInnerState(() => pressed = false),
                                onTap: () => Navigator.of(context)
                                    .push(
                                      PageRouteBuilder(
                                        pageBuilder: (_, animation, __) => FriendDetailPage(
                                          name: key,
                                        ),
                                        transitionsBuilder: (_, animation, __, child) {
                                          final tween = Tween(
                                            begin: const Offset(1, 0),
                                            end: Offset.zero,
                                          ).chain(
                                            CurveTween(
                                              curve: Curves.easeInOutCubic,
                                            ),
                                          );
                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                        transitionDuration: const Duration(milliseconds: 500),
                                      ),
                                    )
                                    .then((_) {
                                      displayedKeys = box.keys.cast<String>().toList();
                                      _refreshView();
                                    }),
                                child: AnimatedScale(
                                  scale: pressed ? 0.97 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeInOutCubic,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 70,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: pressed
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.outline,
                                        width: pressed ? 2 : 1,
                                      ),
                                      boxShadow: pressed
                                          ? [
                                              BoxShadow(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                              child: Builder(
                                                builder: (c) {
                                                  final iconKey = metaBox.get(key) as String? ?? 'terminal';
                                                  try {
                                                    if (iconKey.startsWith('/') || iconKey.startsWith('file://')) {
                                                      final path = iconKey.replaceFirst('file://', '');
                                                      final f = File(path);
                                                      if (f.existsSync()) {
                                                        return ClipRRect(
                                                          borderRadius: BorderRadius.circular(20),
                                                          child: Image.file(
                                                            f,
                                                            width: 36,
                                                            height: 36,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  } catch (_) {}
                                                  switch (iconKey) {
                                                    case 'code':
                                                      return Icon(
                                                        Icons.code,
                                                        color: Theme.of(context).colorScheme.secondary,
                                                      );
                                                    case 'robot':
                                                      return Icon(
                                                        Icons.smart_toy,
                                                        color: Theme.of(context).colorScheme.secondary,
                                                      );
                                                    case 'user':
                                                      return Icon(
                                                        Icons.person,
                                                        color: Theme.of(context).colorScheme.secondary,
                                                      );
                                                    case 'smile':
                                                      return Icon(
                                                        Icons.emoji_emotions,
                                                        color: Theme.of(context).colorScheme.secondary,
                                                      );
                                                    default:
                                                      return Icon(
                                                        Icons.terminal,
                                                        color: Theme.of(context).colorScheme.secondary,
                                                      );
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  key,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                    fontFamily: 'Courier New',
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'balance: ₹${total.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontFamily: 'Courier New',
                                                    color: total >= 0
                                                        ? Theme.of(context).colorScheme.tertiary
                                                        : Theme.of(context).colorScheme.error,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                childCount: displayedKeys.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddUserFab() {
    return FloatingActionButton(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Icon(Icons.add, size: 28),
      elevation: 2,
      onPressed:
          () => showDialog(
            context: context,
            builder:
                (_) => StatefulBuilder(
                  builder:
                      (context, setDialogState) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                r'$ add_user()',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontFamily: context.hisaabFontFamily,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _iconChoice(
                                    'terminal',
                                    Icons.terminal,
                                    setDialogState,
                                  ),
                                  SizedBox(width: 8),
                                  _iconChoice(
                                    'code',
                                    Icons.code,
                                    setDialogState,
                                  ),
                                  SizedBox(width: 8),
                                  _iconChoice(
                                    'robot',
                                    Icons.smart_toy,
                                    setDialogState,
                                  ),
                                  SizedBox(width: 8),
                                  _iconChoice(
                                    'user',
                                    Icons.person,
                                    setDialogState,
                                  ),
                                  SizedBox(width: 8),
                                  _iconChoice(
                                    'smile',
                                    Icons.emoji_emotions,
                                    setDialogState,
                                  ),
                                  SizedBox(width: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () async {
                                        final saved =
                                            await _pickCropAndSaveImage();
                                        if (saved != null) {
                                          _selectedIcon = saved;
                                          _refreshView();
                                          setDialogState(() {});
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color:
                                              (_selectedIcon.startsWith('/') ||
                                                      _selectedIcon.startsWith(
                                                        'file://',
                                                      ))
                                                  ? Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor
                                                  : Theme.of(
                                                    context,
                                                  ).colorScheme.surface,
                                          border: Border.all(
                                            color:
                                                (_selectedIcon.startsWith(
                                                          '/',
                                                        ) ||
                                                        _selectedIcon
                                                            .startsWith(
                                                              'file://',
                                                            ))
                                                    ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                    : Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
                                            width:
                                                (_selectedIcon.startsWith(
                                                          '/',
                                                        ) ||
                                                        _selectedIcon
                                                            .startsWith(
                                                              'file://',
                                                            ))
                                                    ? 2
                                                    : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.image,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              TextField(
                                controller: nameController,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontFamily: context.hisaabFontFamily,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'name_',
                                  hintStyle: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                    fontFamily: context.hisaabFontFamily,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                autofocus: true,
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    child: Text(
                                      'cancel',
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                        fontFamily: context.hisaabFontFamily,
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  SizedBox(width: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor:
                                          Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'create',
                                      style: TextStyle(
                                        fontFamily: context.hisaabFontFamily,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed:
                                        () => addFriend(
                                          nameController.text.trim(),
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
    );
  }
}
