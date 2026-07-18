import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/challenges_repository.dart';
import '../../domain/stats/challenge_progress.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/auth/auth_config.dart';
import '../../services/auth/auth_service.dart';
import '../settings/settings_screen.dart';
import '../../ui/hant/hant_backdrop.dart';
import '../../ui/icons/breathin_icon.dart';
import '../../ui/icons/breathin_icons.dart';
import '../../ui/widgets/empty_state.dart';

/// Экран «Челленджи» (ТЗ §4 — соревнование с друзьями).
///
/// Гейтит доступ к Supabase: репозиторий создаётся ЛЕНИВО только когда
/// [AuthService.isReady] и пользователь вошёл (в тестах Supabase.instance
/// недоступен, поэтому создавать его нельзя).
class ChallengesScreen extends StatefulWidget {
  final AuthService auth;
  final ChallengesRepository? repo;

  const ChallengesScreen({
    super.key,
    this.auth = const AuthService(),
    this.repo,
  });

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  ChallengesRepository? _repo;
  // Future хранится в стейте (а не создаётся в build), чтобы не плодить лишние
  // сетевые цепочки и не мигать спиннером на каждый rebuild (ревью С5).
  Future<List<ChallengeView>>? _future;
  StreamSubscription<AppUser?>? _sub;
  String? _knownUid;

  @override
  void initState() {
    super.initState();
    _knownUid = widget.auth.currentUser?.id;
    // Вход завершается ВНЕ экрана (возврат deep link'ом из браузера) — гейт
    // должен исчезнуть сам, поэтому подписываемся на изменения сессии (ревью
    // С6). Перезагрузка только при СМЕНЕ пользователя: initialSession для уже
    // вошедшего не должна дублировать сетевую цепочку первой загрузки.
    _sub = widget.auth.onAuthStateChange.listen((u) {
      if (!mounted) return;
      if (u == null) {
        _knownUid = null;
        return;
      }
      if (u.id == _knownUid) return;
      _knownUid = u.id;
      _reload();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  ChallengesRepository _getRepo() {
    _repo ??= widget.repo ?? ChallengesRepository();
    return _repo!;
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<List<ChallengeView>> _load() {
    return _getRepo().loadAndSyncProgress();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.challengesTitle)),
      // В HANT под челленджами — фон-«чертёж» (в классике HantBackdrop прозрачен).
      body: HantBackdrop(child: _body(l)),
    );
  }

  Widget _body(AppLocalizations l) {
    if (!widget.auth.isReady || widget.auth.currentUser == null) {
      return _SignInGate(auth: widget.auth, onSignedIn: _reload);
    }

    // Ленивая инициализация future при первом обращении (не в build).
    _future ??= _load();

    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<ChallengeView>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _ErrorState(onRetry: _reload);
              }
              final challenges = snap.data ?? const [];
              if (challenges.isEmpty) {
                return _EmptyState(message: AppLocalizations.of(context).challengesEmpty);
              }
              return _ChallengeList(challenges: challenges, repo: _getRepo(), onReload: _reload);
            },
          ),
        ),
        _BottomActions(repo: _getRepo, onReload: _reload),
      ],
    );
  }
}

// ─── Гейт входа ─────────────────────────────────────────────────────────────

/// Гейт-заглушка: строит EmptyState с двумя кнопками входа.
class _SignInGate extends StatelessWidget {
  final AuthService auth;
  final VoidCallback onSignedIn;

  const _SignInGate({required this.auth, required this.onSignedIn});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return EmptyState(
      icon: BreathinIcons.trophy,
      message: l.challengesSignInHint,
      actions: [
        FilledButton.tonalIcon(
          icon: const BreathinIcon(BreathinIcons.user, size: 20),
          label: Text(l.createGuestProfile),
          onPressed: () async {
            try {
              await auth.signInAnonymously();
              onSignedIn();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.authActionFailed)),
                );
              }
            }
          },
        ),
        // Постоянный вход — по почте: форма живёт в настройках (секция
        // «Аккаунт»), отсюда — переход. Возврат дёргает onSignedIn: если
        // вход уже случился, гейт сменяется списком без ручного обновления.
        OutlinedButton.icon(
          icon: const BreathinIcon(BreathinIcons.login, size: 20),
          label: Text(l.emailSignInAction),
          onPressed: () => Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              )
              .then((_) => onSignedIn()),
        ),
        if (googleAuthEnabled)
          OutlinedButton.icon(
            icon: const BreathinIcon(BreathinIcons.login, size: 20),
            label: Text(l.signInGoogle),
            onPressed: () async {
              try {
                await auth.signInWithGoogle();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.authActionFailed)),
                  );
                }
              }
            },
          ),
      ],
    );
  }
}

// ─── Заглушка пустого списка и ошибки ────────────────────────────────────────

/// Пустой список — иконка + текст, без действий.
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: BreathinIcons.trophy,
        message: message,
      );
}

/// Ошибка загрузки — иконка + текст + кнопка «Повторить».
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return EmptyState(
      icon: BreathinIcons.trophy,
      message: l.challengesLoadFailed,
      actions: [
        // Полноширинная CTA — EmptyState сам добавляет SizedBox.expand.
        FilledButton.tonal(
          onPressed: onRetry,
          child: Text(l.commonRetry),
        ),
      ],
    );
  }
}

// ─── Список челленджей ────────────────────────────────────────────────────────

class _ChallengeList extends StatelessWidget {
  final List<ChallengeView> challenges;
  final ChallengesRepository repo;
  final VoidCallback onReload;

  const _ChallengeList({
    required this.challenges,
    required this.repo,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: challenges.length,
      itemBuilder: (context, i) =>
          _ChallengeCard(challenge: challenges[i], onReload: onReload),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeView challenge;
  final VoidCallback onReload;

  const _ChallengeCard({required this.challenge, required this.onReload});

  String _metricLabel(AppLocalizations l, ChallengeMetric metric) {
    switch (metric) {
      case ChallengeMetric.sessions:
        return l.metricSessions;
      case ChallengeMetric.minutes:
        return l.metricMinutes;
      case ChallengeMetric.streak:
        return l.metricStreak;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final c = challenge;
    final today = DateTime.now();
    final isActive = c.isActive(today);
    final dateStr = isActive
        ? l.challengeUntil(DateFormat.yMd(locale).format(c.endsOn))
        : l.challengeFinished;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(c.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            // Метрика · цель · дата
            Text(
              '${_metricLabel(l, c.metric)} · ${l.targetLabel} ${c.target} · $dateStr',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Участники
            for (final p in c.participants) ...[
              _ParticipantRow(participant: p, target: c.target),
              const SizedBox(height: 8),
            ],
            // Строка кода
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.challengeCodeShare(c.code),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: const BreathinIcon(BreathinIcons.copy, size: 20),
                  tooltip: l.codeCopied,
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: c.code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.codeCopied)),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final ChallengeParticipant participant;
  final int target;

  const _ParticipantRow({required this.participant, required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = participant;
    final progress = target > 0
        ? (p.progress / target).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              p.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: p.isMe ? FontWeight.bold : null,
              ),
            ),
            Text(
              '${p.progress}/$target',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}

// ─── Нижняя панель действий ──────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final ChallengesRepository Function() repo;
  final VoidCallback onReload;

  const _BottomActions({required this.repo, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => _showCreateDialog(context, l),
              child: Text(l.createChallengeAction),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => _showJoinDialog(context, l),
              child: Text(l.joinByCodeAction),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, AppLocalizations l) async {
    final titleCtrl = TextEditingController(text: l.challengeTitleDefault);
    final targetCtrl = TextEditingController(text: '10');
    final daysCtrl = TextEditingController(text: '7');
    ChallengeMetric metric = ChallengeMetric.sessions;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => AlertDialog(
          title: Text(l.createChallengeAction),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: l.challengeTitleLabel),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                Text(l.metricLabel, style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 8),
                SegmentedButton<ChallengeMetric>(
                  segments: [
                    ButtonSegment(
                      value: ChallengeMetric.sessions,
                      label: Text(l.metricSessions),
                    ),
                    ButtonSegment(
                      value: ChallengeMetric.minutes,
                      label: Text(l.metricMinutes),
                    ),
                    ButtonSegment(
                      value: ChallengeMetric.streak,
                      label: Text(l.metricStreak),
                    ),
                  ],
                  selected: {metric},
                  onSelectionChanged: (s) {
                    setInnerState(() => metric = s.first);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  decoration: InputDecoration(labelText: l.targetLabel),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: daysCtrl,
                  decoration: InputDecoration(labelText: l.durationLabel),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.commonCreate),
            ),
          ],
        ),
      ),
    );

    // Значения читаем ДО dispose контроллеров.
    final title = titleCtrl.text.trim().isEmpty
        ? l.challengeTitleDefault
        : titleCtrl.text.trim();
    final target = int.tryParse(targetCtrl.text) ?? 10;
    final days = int.tryParse(daysCtrl.text) ?? 7;
    titleCtrl.dispose();
    targetCtrl.dispose();
    daysCtrl.dispose();

    if (result != true || !context.mounted) return;

    try {
      final code = await repo().create(
        title: title,
        metric: metric,
        target: target,
        days: days,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.challengeCodeShare(code))),
      );
      onReload();
    } catch (_) {
      // Офлайн/сетевая ошибка — не роняем экран (ревью С5).
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.authActionFailed)),
        );
      }
    }
  }

  Future<void> _showJoinDialog(BuildContext context, AppLocalizations l) async {
    final codeCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.joinByCodeAction),
        content: TextField(
          controller: codeCtrl,
          decoration: InputDecoration(labelText: l.codeFieldLabel),
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) {
            final upper = v.toUpperCase();
            if (v != upper) {
              codeCtrl.value = codeCtrl.value.copyWith(text: upper);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.commonJoin),
          ),
        ],
      ),
    );

    // Значение читаем ДО dispose контроллера.
    final code = codeCtrl.text;
    codeCtrl.dispose();

    if (result != true || !context.mounted) return;

    try {
      final title = await repo().joinByCode(code);
      if (!context.mounted) return;
      if (title == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.codeNotFound)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.joinedChallenge(title))),
        );
        onReload();
      }
    } catch (_) {
      // Офлайн/сетевая ошибка — не роняем экран (ревью С5).
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.authActionFailed)),
        );
      }
    }
  }
}
