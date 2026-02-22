part of 'friend_list_page.dart';

extension _HomePageTab on _FriendListPageState {
  Widget _buildHomeBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            style: TextStyle(
              color: Color(0xFFE6EDF3),
              fontFamily: 'Courier New',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFF0D1117),
              labelText: 'Search user',
              labelStyle: TextStyle(
                color: Color(0xFF8B949E),
                fontFamily: 'Courier New',
              ),
              prefixIcon: Icon(Icons.search, color: Color(0xFF58A6FF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF30363D), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF00D084), width: 2),
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF30363D), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'total_pending: ₹${getOverallTotal().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Courier New',
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF58A6FF),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child:
              displayedKeys.isEmpty
                  ? Center(
                    child: Text(
                      r'$ user_not_found()' '\n\ntype "+ icon" to create_user()',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6E7681),
                        fontSize: 14,
                        fontFamily: 'Courier New',
                        height: 1.6,
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: EdgeInsets.only(bottom: 100),
                    physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: displayedKeys.length,
                    itemBuilder: (_, index) {
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
                                    onTapDown:
                                        (_) => setInnerState(
                                          () => pressed = true,
                                        ),
                                    onTapUp:
                                        (_) => setInnerState(
                                          () => pressed = false,
                                        ),
                                    onTapCancel:
                                        () => setInnerState(
                                          () => pressed = false,
                                        ),
                                    onTap:
                                        () => Navigator.of(context)
                                            .push(
                                              PageRouteBuilder(
                                                pageBuilder:
                                                    (_, animation, __) =>
                                                        FriendDetailPage(
                                                          name: key,
                                                        ),
                                                transitionsBuilder: (
                                                  _,
                                                  animation,
                                                  __,
                                                  child,
                                                ) {
                                                  final tween = Tween(
                                                    begin: const Offset(1, 0),
                                                    end: Offset.zero,
                                                  ).chain(
                                                    CurveTween(
                                                      curve:
                                                          Curves.easeInOutCubic,
                                                    ),
                                                  );
                                                  return SlideTransition(
                                                    position: animation.drive(
                                                      tween,
                                                    ),
                                                    child: child,
                                                  );
                                                },
                                                transitionDuration:
                                                    const Duration(
                                                      milliseconds: 500,
                                                    ),
                                              ),
                                            )
                                            .then(
                                              (_) {
                                                displayedKeys =
                                                    box.keys.cast<String>()
                                                        .toList();
                                                _refreshView();
                                              },
                                            ),
                                    child: AnimatedScale(
                                      scale: pressed ? 0.97 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
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
                                          color: const Color(0xFF161B22),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                pressed
                                                    ? const Color(0xFF00D084)
                                                    : const Color(0xFF30363D),
                                            width: pressed ? 2 : 1,
                                          ),
                                          boxShadow:
                                              pressed
                                                  ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF00D084,
                                                      ).withOpacity(0.3),
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: const Color(
                                                    0xFF0D1117,
                                                  ),
                                                  child: Builder(
                                                    builder: (c) {
                                                      final iconKey =
                                                          metaBox.get(key)
                                                              as String? ??
                                                          'terminal';
                                                      try {
                                                        if (iconKey.startsWith(
                                                              '/',
                                                            ) ||
                                                            iconKey.startsWith(
                                                              'file://',
                                                            )) {
                                                          final path = iconKey
                                                              .replaceFirst(
                                                                'file://',
                                                                '',
                                                              );
                                                          final f = File(path);
                                                          if (f.existsSync()) {
                                                            return ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                              child: Image.file(
                                                                f,
                                                                width: 36,
                                                                height: 36,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      } catch (_) {}
                                                      switch (iconKey) {
                                                        case 'code':
                                                          return const Icon(
                                                            Icons.code,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                        case 'robot':
                                                          return const Icon(
                                                            Icons.smart_toy,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                        case 'user':
                                                          return const Icon(
                                                            Icons.person,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                        case 'smile':
                                                          return const Icon(
                                                            Icons
                                                                .emoji_emotions,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                        default:
                                                          return const Icon(
                                                            Icons.terminal,
                                                            color: Color(
                                                              0xFF58A6FF,
                                                            ),
                                                          );
                                                      }
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      key,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFFE6EDF3,
                                                        ),
                                                        fontFamily:
                                                            'Courier New',
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'balance: ₹${total.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontFamily:
                                                            'Courier New',
                                                        color:
                                                            total >= 0
                                                                ? const Color(
                                                                  0xFF3FB950,
                                                                )
                                                                : const Color(
                                                                  0xFFF85149,
                                                                ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF6E7681),
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
                  ),
        ),
      ],
    );
  }

  Widget _buildAddUserFab() {
    return FloatingActionButton(
      backgroundColor: Color(0xFF00D084),
      foregroundColor: Color(0xFF0D1117),
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
                        backgroundColor: Color(0xFF161B22),
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFF30363D),
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
                                  color: Color(0xFF00D084),
                                  fontFamily: 'Courier New',
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
                                  _iconChoice('code', Icons.code, setDialogState),
                                  SizedBox(width: 8),
                                  _iconChoice(
                                    'robot',
                                    Icons.smart_toy,
                                    setDialogState,
                                  ),
                                  SizedBox(width: 8),
                                  _iconChoice('user', Icons.person, setDialogState),
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
                                                  ? Color(0xFF0D1117)
                                                  : Color(0xFF161B22),
                                          border: Border.all(
                                            color:
                                                (_selectedIcon.startsWith('/') ||
                                                        _selectedIcon
                                                            .startsWith(
                                                              'file://',
                                                            ))
                                                    ? Color(0xFF00D084)
                                                    : Color(0xFF30363D),
                                            width:
                                                (_selectedIcon.startsWith('/') ||
                                                        _selectedIcon
                                                            .startsWith(
                                                              'file://',
                                                            ))
                                                    ? 2
                                                    : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.image,
                                          color: Color(0xFF58A6FF),
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
                                  color: Color(0xFFE6EDF3),
                                  fontFamily: 'Courier New',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'name_',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF6E7681),
                                    fontFamily: 'Courier New',
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFF0D1117),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xFF30363D),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xFF30363D),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Color(0xFF00D084),
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
                                        color: Color(0xFF8B949E),
                                        fontFamily: 'Courier New',
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  SizedBox(width: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF00D084),
                                      foregroundColor: Color(0xFF0D1117),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'create',
                                      style: TextStyle(
                                        fontFamily: 'Courier New',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed:
                                        () =>
                                            addFriend(nameController.text.trim()),
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
