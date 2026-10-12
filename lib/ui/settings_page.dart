import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../core/integrations/phone.dart';
import '../core/scheduler/schedule.dart';
import 'shell_state.dart';
import 'tokens.dart';
import 'widgets/apple.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppState state;
  late TextEditingController baseUrl, model, apiKey, userName, memoryDir;
  late TextEditingController bbBase, bbId, bbSecret, bbUser, bbPass, bbCode;
  late TextEditingController akLogin, akUserField, akPassField, akUser,
      akPass, akScrape, akRegex;
  late TextEditingController olClientId, autoSync;
  late TextEditingController ntfyServer, ntfyTopic;
  bool bbEnabled = false, akEnabled = false, olEnabled = false, olMail = true,
      ntfyEnabled = false;
  String testResult = '';

  @override
  void initState() {
    super.initState();
    state = context.read<AppState>();
    final s = state.store.settings;
    baseUrl = TextEditingController(text: s['baseUrl'] as String);
    model = TextEditingController(text: s['model'] as String);
    apiKey = TextEditingController(text: s['apiKey'] as String);
    userName = TextEditingController(text: s['userName'] as String);
    memoryDir = TextEditingController(text: state.store.root);

    final integ = (s['integrations'] as Map?)?.cast<String, dynamic>() ?? {};
    final bb = (integ['blackboard'] as Map?)?.cast<String, dynamic>() ?? {};
    bbEnabled = bb['enabled'] == true;
    bbBase = TextEditingController(text: '${bb['baseUrl'] ?? ''}');
    bbId = TextEditingController(text: '${bb['clientId'] ?? ''}');
    bbSecret = TextEditingController(text: '${bb['clientSecret'] ?? ''}');
    bbUser = TextEditingController(text: '${bb['username'] ?? ''}');
    bbPass = TextEditingController(text: '${bb['password'] ?? ''}');
    bbCode = TextEditingController();

    final ak = (integ['aktiv'] as Map?)?.cast<String, dynamic>() ?? {};
    akEnabled = ak['enabled'] == true;
    akLogin = TextEditingController(text: '${ak['loginUrl'] ?? ''}');
    akUserField = TextEditingController(text: '${ak['userField'] ?? 'login'}');
    akPassField = TextEditingController(text: '${ak['passField'] ?? 'password'}');
    akUser = TextEditingController(text: '${ak['username'] ?? ''}');
    akPass = TextEditingController(text: '${ak['password'] ?? ''}');
    akScrape = TextEditingController(text: '${ak['scrapeUrl'] ?? ''}');
    akRegex = TextEditingController(text: '${ak['itemRegex'] ?? ''}');

    final ol = (integ['outlook'] as Map?)?.cast<String, dynamic>() ?? {};
    olEnabled = ol['enabled'] == true;
    olMail = ol['fetchMail'] == true;
    olClientId = TextEditingController(text: '${ol['clientId'] ?? ''}');
    autoSync =
        TextEditingController(text: '${integ['autoSyncMinutes'] ?? 15}');

    final nf = (integ['ntfy'] as Map?)?.cast<String, dynamic>() ?? {};
    ntfyEnabled = nf['enabled'] == true;
    ntfyServer =
        TextEditingController(text: '${nf['server'] ?? 'https://ntfy.sh'}');
    ntfyTopic = TextEditingController(text: '${nf['topic'] ?? ''}');
  }

  @override
  void dispose() {
    for (final c in [
      baseUrl, model, apiKey, userName, memoryDir,
      bbBase, bbId, bbSecret, bbUser, bbPass, bbCode,
      akLogin, akUserField, akPassField, akUser, akPass, akScrape, akRegex,
      olClientId, autoSync, ntfyServer, ntfyTopic,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await state.saveSettings(
      baseUrl: baseUrl.text.trim(),
      model: model.text.trim(),
      apiKey: apiKey.text.trim(),
      userName: userName.text.trim(),
      memoryDir: memoryDir.text.trim(),
    );
    final integ = Map<String, dynamic>.from(
        state.store.settings['integrations'] as Map? ?? {});
    final bb = Map<String, dynamic>.from(integ['blackboard'] as Map? ?? {});
    bb['enabled'] = bbEnabled;
    bb['baseUrl'] = bbBase.text.trim();
    bb['clientId'] = bbId.text.trim();
    bb['clientSecret'] = bbSecret.text.trim();
    bb['username'] = bbUser.text.trim();
    bb['password'] = bbPass.text.trim();
    integ['blackboard'] = bb;
    final ak = Map<String, dynamic>.from(integ['aktiv'] as Map? ?? {});
    ak['enabled'] = akEnabled;
    ak['loginUrl'] = akLogin.text.trim();
    ak['userField'] = akUserField.text.trim().isEmpty ? 'login' : akUserField.text.trim();
    ak['passField'] = akPassField.text.trim().isEmpty ? 'password' : akPassField.text.trim();
    ak['username'] = akUser.text.trim();
    ak['password'] = akPass.text.trim();
    ak['scrapeUrl'] = akScrape.text.trim();
    ak['itemRegex'] = akRegex.text.trim();
    integ['aktiv'] = ak;
    final ol = Map<String, dynamic>.from(integ['outlook'] as Map? ?? {});
    ol['enabled'] = olEnabled;
    ol['fetchMail'] = olMail;
    if (olClientId.text.trim().isNotEmpty) ol['clientId'] = olClientId.text.trim();
    integ['outlook'] = ol;
    final nf = Map<String, dynamic>.from(integ['ntfy'] as Map? ?? {});
    nf['enabled'] = ntfyEnabled;
    nf['server'] =
        ntfyServer.text.trim().isEmpty ? 'https://ntfy.sh' : ntfyServer.text.trim();
    nf['topic'] = ntfyTopic.text.trim();
    integ['ntfy'] = nf;
    integ['autoSyncMinutes'] = int.tryParse(autoSync.text) ?? 15;
    state.store.settings['integrations'] = integ;
    await state.store.saveSettings();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = state.integrations.status;
    final t = tk(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader('Settings',
            subtitle: 'AI endpoint, integrations and schedule',
            trailing: [
              AppleButton('Save',
                  icon: CupertinoIcons.checkmark,
                  onPressed: _save),
              const SizedBox(width: 10),
              AppleButton('Test connection',
                  tone: AppleTone.gray,
                  onPressed: () async {
                    // Apply the form values first so Test hits the URL/model
                    // currently typed, not the last saved settings.
                    await _save();
                    final r = await state.testConnection();
                    if (mounted) setState(() => testResult = r);
                  }),
            ]),
        Expanded(
          child: Scrollbar(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                Text('AI endpoint (OpenAI-compatible)',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: t.label)),
                const SizedBox(height: 8),
                SectionCard(
                  child: Column(
                    children: [
                      appleField(baseUrl, 'Base URL',
                          hint: 'http://127.0.0.1:1234/v1  (LM Studio)'),
                      appleField(model, 'Model',
                          hint: 'exact id from LM Studio'),
                      appleField(apiKey, 'API key (blank for local)'),
                    ],
                  ),
                ),
                if (testResult.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SelectableText(testResult,
                        style: TextStyle(
                            color: testResult.startsWith('ERROR')
                                ? t.red
                                : t.green,
                            fontSize: 13)),
                  ),
                const SizedBox(height: 24),
                Text('Identity & memory',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: t.label)),
                const SizedBox(height: 8),
                SectionCard(
                  child: Column(
                    children: [
                      appleField(userName, 'Your name'),
                      appleField(memoryDir, 'Memory directory'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Device sync',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: t.label)),
                const SizedBox(height: 8),
                _DeviceSyncCard(state: state),
                const SizedBox(height: 24),
                Text('Integrations',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: t.label)),
                const SizedBox(height: 8),
                _card('Blackboard',
                    'Uses the Blackboard Learn public REST API with the OAuth '
                    'authorization-code flow: request a code (it is sent to your '
                    'Blackboard notifications), enter it here, and MindFlow '
                    'exchanges it for your access token. Client id/secret come '
                    'from a registered Blackboard app - ask your school IT to register '
                    'one for MindFlow.',
                    bbEnabled, (v) => setState(() => bbEnabled = v), [
                      appleField(bbBase, 'Base URL',
                          hint: 'https://ccsu.blackboard.com'),
                      Row(children: [
                        Expanded(child: appleField(bbId, 'Client ID')),
                        const SizedBox(width: 10),
                        Expanded(child: appleField(bbSecret, 'Client Secret')),
                      ]),
                      appleField(bbUser,
                          'Username (your Blackboard user id / NetID)'),
                      Row(children: [
                        AppleButton('Open Developer Playground',
                            icon: CupertinoIcons.arrow_right_circle,
                            tone: AppleTone.tinted,
                            onPressed: () => launchUrl(
                              Uri.parse('${bbBase.text.trim()}'
                                  '/webapps/developer-playground/index.html'),
                              mode: LaunchMode.externalApplication),
                            ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'Register an app yourself (authorization code '
                                'grant), then copy the id/secret above.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: t.secondary,
                                    height: 1.4))),
                      ]),
                      Row(children: [
                        AppleButton('Request code',
                            icon: CupertinoIcons.arrow_2_circlepath,
                            tone: AppleTone.tinted,
                            onPressed: () async {
                              try {
                                final code =
                                    await state.blackboardRequestCode();
                                if (context.mounted) {
                                  bbCode.text = code;
                                  await appleDialog(
                                    context,
                                    title: 'Blackboard code',
                                    content: Text(code.isEmpty
                                        ? 'A code was sent to your Blackboard '
                                            'notifications (System Messages). '
                                            'Check there and paste it into the '
                                            'Code field.'
                                        : 'Code received: $code\nIf the field '
                                            'is empty, check your Blackboard '
                                            'notifications.'),
                                    actions: [
                                      AppleButton('Close',
                                          tone: AppleTone.gray,
                                          onPressed: () =>
                                              Navigator.pop(context)),
                                    ],
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')));
                                }
                              }
                            }),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: state.blackboardSignedIn
                                      ? t.green
                                      : t.tertiary,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                                state.blackboardSignedIn
                                    ? 'signed in'
                                    : 'not signed in',
                                 style: TextStyle(
                                     fontSize: 12,
                                     color: t.secondary)),
                          ],
                        ),
                      ]),
                      Row(children: [
                        Expanded(
                            child: appleField(bbCode,
                                'Code (from Blackboard notification)')),
                        const SizedBox(width: 10),
                        AppleButton('Exchange code',
                            onPressed: () async {
                              try {
                                final ok = await state
                                    .blackboardExchangeCode(
                                        bbCode.text.trim());
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(ok
                                          ? 'Blackboard signed in and synced'
                                          : 'Exchange failed')));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')));
                                }
                              }
                            }),
                      ]),
                     ], t),
                 _card('Aktiv (chemistry)',
                    'Logs in to the Aktiv site and scrapes assignment links '
                    'from your dashboard. Set login URL, credentials, and '
                    'optionally a scrape URL and item regex.',
                    akEnabled, (v) => setState(() => akEnabled = v), [
                      appleField(akLogin, 'Login URL'),
                      Row(children: [
                        Expanded(child: appleField(akUserField,
                            'User field name')),
                        const SizedBox(width: 10),
                        Expanded(child: appleField(akPassField,
                            'Password field name')),
                      ]),
                      Row(children: [
                        Expanded(child: appleField(akUser, 'Username')),
                        const SizedBox(width: 10),
                        Expanded(child: appleField(akPass, 'Password')),
                      ]),
                      appleField(akScrape,
                          'Scrape URL (blank = login page)'),
                      appleField(akRegex,
                          'Item regex (blank = default link regex)'),
                     ], t),
                 _card('Outlook (school)',
                    'Signs in with the Microsoft device-code flow (no app '
                    'secret needed). Pulls your school calendar events and '
                    'recent mail into nodes.',
                    olEnabled, (v) => setState(() => olEnabled = v), [
                      appleField(olClientId, 'Client ID (default works)'),
                      Row(children: [
                        AppleSwitch(
                            value: olMail,
                            onChanged: (b) =>
                                setState(() => olMail = b)),
                        const SizedBox(width: 8),
                        const Text('fetch mail',
                            style: TextStyle(fontSize: 13)),
                        const Spacer(),
                        AppleButton(
                            state.integrations.outlookSignedIn
                                ? 'Signed in - re-sign'
                                : 'Sign in',
                            icon: CupertinoIcons.arrow_right_circle,
                            tone: AppleTone.tinted,
                            onPressed: () async {
                              final code = await state.outlookSignIn();
                              if (context.mounted) {
                                await appleDialog(
                                  context,
                                  title: 'Sign in to Outlook',
                                  content: Text(
                                      'Go to microsoft.com/device and enter '
                                      'code:\n\n$code\n\nThe app signs in '
                                      'automatically once you approve it in '
                                      'the browser.'),
                                  actions: [
                                    AppleButton('Close',
                                        tone: AppleTone.gray,
                                        onPressed: () =>
                                            Navigator.pop(context)),
                                  ],
                                );
                              }
                            }),
                      ]),
                     ], t),
                 _card('Phone notifications (ntfy)',
                    'Install the ntfy app on your phone and subscribe to a '
                    'topic (any random words you invent). MindFlow pushes '
                    'reminders and agent messages to that topic, including '
                    'delayed delivery that arrives at the reminder time even '
                    'when this app is closed. Use a private topic name, or '
                    'self-host your own server.',
                    ntfyEnabled, (v) => setState(() => ntfyEnabled = v), [
                      Row(children: [
                        Expanded(child: appleField(ntfyServer, 'Server')),
                        const SizedBox(width: 10),
                        Expanded(child: appleField(ntfyTopic, 'Topic')),
                      ]),
                      Row(children: [
                        AppleButton('Send test',
                            icon: CupertinoIcons.bell,
                            tone: AppleTone.tinted,
                            onPressed: () async {
                              PhoneNotifier.enabled = true;
                              PhoneNotifier.server = ntfyServer.text.trim()
                                  .isEmpty
                                  ? 'https://ntfy.sh'
                                  : ntfyServer.text.trim();
                              PhoneNotifier.topic = ntfyTopic.text.trim();
                              final r = await PhoneNotifier.send(
                                  'MindFlow test',
                                  'If you see this on your phone, ntfy is '
                                      'working.');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(r)));
                              }
                            }),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text('phone must have the ntfy app '
                                'subscribed to the same topic',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: t.secondary,
                                    height: 1.4))),
                      ]),
                     ], t),
                 const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: appleField(autoSync,
                            'Auto-sync every (minutes)')),
                    const SizedBox(width: 10),
                    AppleButton('Sync now',
                        icon: CupertinoIcons.arrow_2_circlepath,
                        onPressed: state.integrations.busy
                            ? null
                            : () async {
                                final c = await state.syncNow();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Sync done, $c new items')));
                                }
                              }),
                  ],
                ),
                const SizedBox(height: 10),
                for (final e in status.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: e.value.startsWith('error')
                                  ? t.red
                                  : t.green,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('${e.key}: ${e.value}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: t.secondary)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text('Class schedule',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: t.label)),
                const SizedBox(height: 8),
                SectionCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  child: Column(
                    children: [
                      for (final s in (state.schedule.slots
                          ..sort((a, b) => a.weekday != b.weekday
                              ? a.weekday.compareTo(b.weekday)
                              : a.startMin.compareTo(b.startMin))))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.book,
                                  size: 15, color: t.purple),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${s.name}  -  ${_days[s.weekday]} '
                                  '${s.startLabel}-${s.endLabel}',
                                  style: TextStyle(
                                      fontSize: 13, color: t.label)),
                              ),
                              AppleIconButton(
                                  icon: CupertinoIcons.trash,
                                  color: t.tertiary,
                                  onPressed: () =>
                                      state.removeClass(s.id)),
                            ],
                          ),
                        ),
                      if (state.schedule.slots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('No classes yet',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: t.tertiary)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppleButton('Add class',
                        icon: CupertinoIcons.plus,
                        tone: AppleTone.tinted,
                        onPressed: () => _addClassDialog(context)),
                    const SizedBox(width: 10),
                    AppleButton('Import ICS',
                        icon: CupertinoIcons.arrow_down_circle,
                        tone: AppleTone.gray,
                        onPressed: () => _importIcsDialog(context)),
                  ],
                ),
                const SizedBox(height: 24),
                SectionCard(
                  color: t.elevated,
                  shadow: false,
                  child: Text(
                    'The agent talks to any OpenAI-compatible endpoint: '
                    'Strata local (http://127.0.0.1:8080/v1), Ollama '
                    '(http://localhost:11434/v1), LM Studio, OpenAI, '
                    'OpenRouter. The memory directory stores all nodes, '
                    'views, chat history, long-term memory and the event '
                    'log as plain files you can inspect. Synced items from '
                    'Blackboard, Aktiv and Outlook become nodes tagged by '
                    'source and appear on the Calendar tab alongside your '
                    'class schedule.',
                    style: TextStyle(
                        color: t.secondary,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _days = {
    1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu',
    5: 'Fri', 6: 'Sat', 7: 'Sun'
  };

  Widget _card(String title, String help, bool enabled,
      ValueChanged<bool> onToggle, List<Widget> fields, Tokens t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusLg),
        border: Border.all(color: t.hairline),
        boxShadow: [t.shadowHigh],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.label)),
              const Spacer(),
              Text('enabled',
                  style: TextStyle(fontSize: 12, color: t.secondary)),
              const SizedBox(width: 8),
              AppleSwitch(value: enabled, onChanged: onToggle),
            ],
          ),
          Text(help,
              style: TextStyle(
                  color: t.secondary,
                  fontSize: 11,
                  height: 1.4)),
          const SizedBox(height: 10),
          ...fields,
        ],
      ),
    );
  }

  void _addClassDialog(BuildContext context) {
    final t = tk(context);
    final name = TextEditingController();
    final start = TextEditingController(text: '09:00');
    final end = TextEditingController(text: '10:00');
    final loc = TextEditingController();
    int weekday = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Dialog(
          backgroundColor: t.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusXl),
            side: BorderSide(color: t.hairline),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: (420)
                    .clamp(0.0, MediaQuery.sizeOf(ctx2).width - 40)
                    .toDouble()),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add class',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: t.label)),
                  const SizedBox(height: 14),
                  appleField(name, 'Name'),
                  DropdownButton<int>(
                    value: weekday,
                    underline: const SizedBox(),
                    items: [
                      for (final d in _days.entries)
                        DropdownMenuItem(value: d.key, child: Text(d.value))
                    ],
                    onChanged: (v) => setS(() => weekday = v ?? 1),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: appleField(start, 'Start HH:mm')),
                    const SizedBox(width: 10),
                    Expanded(child: appleField(end, 'End HH:mm')),
                  ]),
                  appleField(loc, 'Location'),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppleButton('Cancel',
                          tone: AppleTone.gray,
                          onPressed: () => Navigator.pop(ctx)),
                      const SizedBox(width: 10),
                      AppleButton('Add',
                          onPressed: () {
                            final sm = _parseHm(start.text),
                em = _parseHm(end.text);
                            Navigator.pop(ctx);
                            state.addClass(ClassSlot(
                                id: const Uuid().v4(),
                                name: name.text.trim(),
                                weekday: weekday,
                                startMin: sm,
                                endMin: em,
                                location: loc.text.trim()));
                          }),
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

  void _importIcsDialog(BuildContext context) {
    final t = tk(context);
    final text = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          side: BorderSide(color: t.hairline),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: (460)
                  .clamp(0.0, MediaQuery.sizeOf(ctx).width - 40)
                  .toDouble()),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Import ICS',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: t.label)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 260,
                  child: TextField(
                    controller: text,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                        hintText: 'Paste .ics content here'),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppleButton('Cancel',
                        tone: AppleTone.gray,
                        onPressed: () => Navigator.pop(ctx)),
                    const SizedBox(width: 10),
                    AppleButton('Import',
                        onPressed: () async {
                          final n = await state.importIcs(text.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Imported $n slots')));
                          }
                        }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _parseHm(String s) {
    final p = s.split(':');
    if (p.length != 2) return 540;
    return int.tryParse(p[0])! * 60 + int.tryParse(p[1])!;
  }
}

class _DeviceSyncCard extends StatefulWidget {
  final AppState state;
  const _DeviceSyncCard({required this.state});

  @override
  State<_DeviceSyncCard> createState() => _DeviceSyncCardState();
}

class _DeviceSyncCardState extends State<_DeviceSyncCard> {
  late final TextEditingController syncUrl;
  late final TextEditingController passphrase;
  late final TextEditingController shareCode;
  late final TextEditingController shareTitle;
  String status = '';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    syncUrl = TextEditingController(
        text: widget.state.syncUrl.isEmpty
            ? 'http://127.0.0.1:8787'
            : widget.state.syncUrl);
    passphrase = TextEditingController(text: widget.state.syncPassphrase);
    shareCode = TextEditingController();
    shareTitle = TextEditingController(text: 'Shared pages');
  }

  @override
  void dispose() {
    syncUrl.dispose();
    passphrase.dispose();
    shareCode.dispose();
    shareTitle.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      busy = true;
      status = '';
    });
    try {
      await fn();
    } catch (e) {
      setState(() => status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tk(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sync this vault between your laptop and phone. '
            'Same server URL + same passphrase on each device.',
            style: TextStyle(color: t.secondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          appleField(syncUrl, 'Sync server URL',
              hint: 'http://192.168.1.20:8787'),
          appleField(passphrase, 'Sync passphrase (same on every device)',
              obscure: true),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppleButton('Save sync settings',
                  tone: AppleTone.tinted,
                  onPressed: busy
                      ? null
                      : () => _run(() async {
                            await widget.state.saveDeviceSync(
                              syncUrl: syncUrl.text.trim(),
                              passphrase: passphrase.text,
                            );
                            setState(() =>
                                status = widget.state.syncStatus ?? 'Saved');
                          })),
              AppleButton('Sync now',
                  icon: CupertinoIcons.arrow_2_circlepath,
                  onPressed: busy
                      ? null
                      : () => _run(() async {
                            await widget.state.saveDeviceSync(
                              syncUrl: syncUrl.text.trim(),
                              passphrase: passphrase.text,
                            );
                            final r = await widget.state.syncVault();
                            setState(() => status = r);
                          })),
            ],
          ),
          const SizedBox(height: 14),
          Text('Optional: share a page with someone',
              style: TextStyle(
                  color: t.label, fontWeight: FontWeight.w600, fontSize: 13)),
          appleField(shareTitle, 'Share title'),
          AppleButton('Share current page',
              tone: AppleTone.gray,
              onPressed: busy
                  ? null
                  : () => _run(() async {
                        await widget.state.saveDeviceSync(
                          syncUrl: syncUrl.text.trim(),
                          passphrase: passphrase.text,
                        );
                        final shell = context.read<ShellState>();
                        final id = shell.currentPage;
                        if (id == null) {
                          setState(() => status = 'Open a page first');
                          return;
                        }
                        final code = await widget.state.shareNodes([id],
                            title: shareTitle.text.trim());
                        setState(() => status = 'Share code: $code');
                      })),
          appleField(shareCode, 'Redeem share code'),
          AppleButton('Redeem into my vault',
              onPressed: busy
                  ? null
                  : () => _run(() async {
                        await widget.state.saveDeviceSync(
                          syncUrl: syncUrl.text.trim(),
                          passphrase: passphrase.text,
                        );
                        final n = await widget.state
                            .redeemShareCode(shareCode.text.trim());
                        setState(() =>
                            status = 'Imported $n page(s) into Shared space');
                      })),
          if ((widget.state.syncStatus ?? status).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(status.isNotEmpty ? status : widget.state.syncStatus!,
                style: TextStyle(color: t.secondary, fontSize: 12.5)),
          ],
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: AppleProgress(),
            ),
        ],
      ),
    );
  }
}
