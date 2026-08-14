import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/localization_helper.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    AppLocalizations.load(locale);
    AppLocalizations? t;
    try { t = AppLocalizations.of(locale); } catch (_) {}
    if (t == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        title: Text(t.planning,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20,
                color: isDark ? Colors.white : AppColors.deepNavy)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.roseGold,
          labelColor: AppColors.roseGold,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: t.budgetTracker),
            Tab(text: t.guestList),
            Tab(text: t.weddingChecklist),
            Tab(text: t.nekathTimes),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _BudgetTab(isDark: isDark, t: t),
          _GuestListTab(isDark: isDark, t: t),
          _ChecklistTab(isDark: isDark, t: t),
          _NekathTab(isDark: isDark, t: t),
        ],
      ),
    );
  }
}

// ─── Budget Tab ───────────────────────────────────────────────────────────────

class _BudgetTab extends ConsumerWidget {
  final bool isDark;
  final AppLocalizations t;

  const _BudgetTab({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider);
    final fmt = NumberFormat('#,###');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.navyGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _BudgetStat('Total', 'LKR ${fmt.format(budget.totalBudget)}', Colors.white),
                _BudgetStat('Spent', 'LKR ${fmt.format(budget.totalSpent)}', AppColors.roseGold),
                _BudgetStat('Left', 'LKR ${fmt.format(budget.remaining)}', AppColors.gold),
              ]),
              const SizedBox(height: 20),
              LinearPercentIndicator(
                percent: budget.spentPercentage,
                lineHeight: 10,
                backgroundColor: Colors.white24,
                linearGradient: const LinearGradient(colors: [AppColors.roseGold, AppColors.gold]),
                barRadius: const Radius.circular(5),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Text('${(budget.spentPercentage * 100).toStringAsFixed(1)}% used',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Set Total Budget'),
                onPressed: () => _showBudgetDialog(context, ref, budget.totalBudget),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.roseGold, size: 18),
              label: const Text('Export', style: TextStyle(color: AppColors.roseGold)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.roseGold)),
              onPressed: () {
                final guests = ref.read(guestProvider);
                final mealCost = ref.read(mealCostProvider);
                final attending = guests.where((g) => g.rsvpStatus == 'Attending').length;
                final consumers = guests.where((g) => g.consumesLiquor).length;
                PdfExportService.exportBudgetToPdf(budget, mealCost, attending, consumers);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Add expense
        OutlinedButton.icon(
          icon: const Icon(Icons.add_rounded, color: AppColors.roseGold, size: 18),
          label: Text(t.addExpense, style: const TextStyle(color: AppColors.roseGold)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.roseGold)),
          onPressed: () => _showExpenseDialog(context, ref),
        ),
        const SizedBox(height: 20),

        // Expenses list
        if (budget.expenses.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No expenses yet. Tap "Add Expense" to start.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 14)),
          ))
        else
          ...budget.expenses.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.roseGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_rounded, color: AppColors.roseGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.category, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.deepNavy)),
                if (e.note.isNotEmpty) Text(e.note, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('LKR ${fmt.format(e.amount)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.roseGold)),
                Text(e.date, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey)),
              ]),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref.read(budgetProvider.notifier).removeExpense(e.id),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
              ),
            ]),
          )),
      ],
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref, int current) {
    final ctrl = TextEditingController(text: current.toString());
    showDialog(context: context, builder: (dialogCtx) => AlertDialog(
      title: const Text('Set Total Budget'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (LKR)', prefixText: 'LKR ')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final v = int.tryParse(ctrl.text.replaceAll(',', '')) ?? current;
            ref.read(budgetProvider.notifier).setTotalBudget(v);
            Navigator.pop(dialogCtx);
          },
          child: const Text('Save'),
        ),
      ],
    ));
  }

  void _showExpenseDialog(BuildContext context, WidgetRef ref) {
    final cats = ['Venue', 'Photography', 'Catering', 'Decoration', 'Bridal', 'Transport', 'Cards', 'Cake', 'Other'];
    String selCat = cats.first;
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      title: const Text('Add Expense'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          initialValue: selCat,
          items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => ss(() => selCat = v!),
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        const SizedBox(height: 12),
        TextField(controller: amtCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (LKR)', prefixText: 'LKR ')),
        const SizedBox(height: 12),
        TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final amt = int.tryParse(amtCtrl.text.replaceAll(',', ''));
            if (amt == null) return;
            ref.read(budgetProvider.notifier).addExpense(BudgetExpense(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              category: selCat, note: noteCtrl.text,
              amount: amt, date: DateFormat('dd MMM yyyy').format(DateTime.now()),
            ));
            Navigator.pop(ctx);
          },
          child: const Text('Add'),
        ),
      ],
    )));
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BudgetStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    const SizedBox(height: 4),
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
  ]);
}

// ─── Guest List Tab ───────────────────────────────────────────────────────────

class _GuestListTab extends ConsumerWidget {
  final bool isDark;
  final AppLocalizations t;

  const _GuestListTab({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guests = ref.watch(guestProvider);
    final mealCostPerPlate = ref.watch(mealCostProvider);

    final fmt = NumberFormat('#,###');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Row(
          children: [
            Expanded(child: _buildGuestStatCard('Total', guests.length, AppColors.deepNavy, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildGuestStatCard('Attending', guests.where((g) => g.rsvpStatus == 'Attending').length, AppColors.whatsappGreen, isDark)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Meal Cost Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Est. Meal Cost', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _showMealCostDialog(context, ref, mealCostPerPlate),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: AppColors.roseGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: const Icon(Icons.edit_rounded, size: 12, color: AppColors.roseGold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${guests.where((g) => g.rsvpStatus == 'Attending').length} Attending x LKR ${fmt.format(mealCostPerPlate)}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey)),
                      ],
                    ),
                  ),
                  Text('LKR ${fmt.format(guests.where((g) => g.rsvpStatus == 'Attending').length * mealCostPerPlate)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.deepNavy)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: isDark ? Colors.white10 : Colors.grey[200], height: 1),
              ),
              // Liquor Cost Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Est. Liquor Cost', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${guests.where((g) => g.consumesLiquor).length} Consumers (Avg LKR 5k)', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey)),
                      ],
                    ),
                  ),
                  Text('LKR ${fmt.format(guests.where((g) => g.consumesLiquor).length * 5000)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.roseGold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_rounded, color: AppColors.roseGold, size: 18),
                label: const Text('Add Guest', style: TextStyle(color: AppColors.roseGold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.roseGold)),
                onPressed: () => _showGuestDialog(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.roseGold, size: 18),
              label: const Text('Export', style: TextStyle(color: AppColors.roseGold)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.roseGold)),
              onPressed: () => PdfExportService.exportGuestListToPdf(guests),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (guests.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No guests added yet. Tap "Add Guest" to start building your list.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ))
        else
          ...guests.map((g) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: AppColors.roseGold.withValues(alpha: 0.1),
                child: Text(g.name[0].toUpperCase(), style: const TextStyle(color: AppColors.roseGold, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(g.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.deepNavy))),
                  if (g.consumesLiquor) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.local_bar_rounded, size: 14, color: AppColors.gold)),
                ]),
                const SizedBox(height: 2),
                Text('${g.group} • ${g.mealPreference}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: g.rsvpStatus == 'Attending' ? AppColors.whatsappGreen.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(g.rsvpStatus, style: TextStyle(fontSize: 10, color: g.rsvpStatus == 'Attending' ? AppColors.whatsappGreen : Colors.grey)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref.read(guestProvider.notifier).removeGuest(g.id),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
              ),
            ]),
          )),
      ],
    );
  }

  Widget _buildGuestStatCard(String title, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
        const SizedBox(height: 4),
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  void _showGuestDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    String group = "Bride's Family";
    String rsvp = 'Pending';
    String meal = 'Non-Veg';
    bool consumesLiquor = false;

    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      title: const Text('Add Guest'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Guest Name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: group,
            decoration: const InputDecoration(labelText: 'Group'),
            items: ["Bride's Family", "Groom's Family", "Friends", "Colleagues", "Other"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => ss(() => group = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: rsvp,
            decoration: const InputDecoration(labelText: 'RSVP Status'),
            items: ['Pending', 'Attending', 'Not Attending']
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => ss(() => rsvp = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: meal,
            decoration: const InputDecoration(labelText: 'Meal Preference'),
            items: ['Non-Veg', 'Veg', 'Vegan', 'Kids']
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => ss(() => meal = v!),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Consumes Liquor', style: TextStyle(fontSize: 14)),
            value: consumesLiquor,
            activeTrackColor: AppColors.roseGold,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => ss(() => consumesLiquor = v),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            ref.read(guestProvider.notifier).addGuest(Guest(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: nameCtrl.text.trim(),
              group: group,
              rsvpStatus: rsvp,
              mealPreference: meal,
              consumesLiquor: consumesLiquor,
            ));
            Navigator.pop(ctx);
          },
          child: const Text('Add'),
        ),
      ],
    )));
  }

  void _showMealCostDialog(BuildContext context, WidgetRef ref, int currentCost) {
    final ctrl = TextEditingController(text: currentCost.toString());
    showDialog(context: context, builder: (dialogCtx) => AlertDialog(
      title: const Text('Set Plate/Person Cost'),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Cost (LKR)', prefixText: 'LKR '),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final v = int.tryParse(ctrl.text.replaceAll(',', '')) ?? currentCost;
            ref.read(mealCostProvider.notifier).setCost(v);
            Navigator.pop(dialogCtx);
          },
          child: const Text('Save'),
        ),
      ],
    ));
  }
}

// ─── Checklist Tab ────────────────────────────────────────────────────────────

class _ChecklistTab extends StatefulWidget {
  final bool isDark;
  final AppLocalizations t;

  const _ChecklistTab({required this.isDark, required this.t});

  @override
  State<_ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<_ChecklistTab> {
  final List<_CheckItem> _items = [
    _CheckItem('Book the venue'),
    _CheckItem('Select wedding date & nekath'),
    _CheckItem('Book photographer'),
    _CheckItem('Choose catering service'),
    _CheckItem('Order wedding cake'),
    _CheckItem('Book DJ or live band'),
    _CheckItem('Order wedding cards'),
    _CheckItem('Book bridal salon'),
    _CheckItem('Arrange transport'),
    _CheckItem('Send invitations'),
    _CheckItem('Confirm guest list'),
    _CheckItem('Finalise decoration theme'),
    _CheckItem('Book honeymoon'),
    _CheckItem('Pre-wedding photoshoot'),
  ];

  @override
  Widget build(BuildContext context) {
    final done = _items.where((i) => i.done).length;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$done / ${_items.length} completed',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _items.isEmpty ? 0 : done / _items.length,
                backgroundColor: AppColors.roseGold.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.roseGold),
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ])),
            const SizedBox(width: 16),
            Text('${((done / (_items.isEmpty ? 1 : _items.length)) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.roseGold)),
          ]),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = _items[i];
              return GestureDetector(
                onTap: () => setState(() => item.done = !item.done),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: item.done
                        ? AppColors.roseGold.withValues(alpha: 0.08)
                        : (widget.isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: item.done ? AppColors.roseGold.withValues(alpha: 0.3) : Colors.transparent,
                    ),
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: item.done ? AppColors.roseGold : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: item.done ? AppColors.roseGold : Colors.grey, width: 1.5),
                      ),
                      child: item.done ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(item.label,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: item.done ? Colors.grey : (widget.isDark ? Colors.white : AppColors.deepNavy),
                          decoration: item.done ? TextDecoration.lineThrough : null,
                        ))),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CheckItem {
  final String label;
  bool done;
  _CheckItem(this.label) : done = false;
}

// ─── Nekath Times Tab ─────────────────────────────────────────────────────────

class _NekathTab extends ConsumerWidget {
  final bool isDark;
  final AppLocalizations t;

  const _NekathTab({required this.isDark, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTimes = ref.watch(userNekathProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, color: AppColors.roseGold, size: 18),
            label: const Text('Add Custom Nekath', style: TextStyle(color: AppColors.roseGold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.roseGold),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _showAddNekathDialog(context, ref),
          ),
        ),
        Expanded(
          child: myTimes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No custom Nekath times added. Tap the button above to add your auspicious times.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: myTimes.length,
                  itemBuilder: (_, i) {
                    final e = myTimes[i];
                    return _nekathCard(e, ref);
                  },
                ),
        ),
      ],
    );
  }

  Widget _nekathCard(UserNekath e, WidgetRef ref) {
    final dateParts = e.date.split('-');
    final dayStr = dateParts.isNotEmpty ? dateParts.last : '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(dayStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.eventType, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.deepNavy)),
          const SizedBox(height: 2),
          Text('${e.startTime} – ${e.endTime}', style: const TextStyle(fontSize: 12, color: AppColors.roseGold, fontWeight: FontWeight.w600)),
        ])),
        GestureDetector(
          onTap: () => ref.read(userNekathProvider.notifier).removeNekath(e.id),
          child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
        ),
      ]),
    );
  }

  void _showAddNekathDialog(BuildContext context, WidgetRef ref) {
    final typeCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();

    showDialog(context: context, builder: (dialogCtx) => AlertDialog(
      title: const Text('Add Nekath Time'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Event (e.g. Poruwa)')),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (e.g. 2026-09-06)', hintText: 'YYYY-MM-DD')),
          const SizedBox(height: 12),
          TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Time (e.g. 09:14 AM)')),
          const SizedBox(height: 12),
          TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Time (e.g. 09:34 AM)')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (typeCtrl.text.trim().isEmpty || dateCtrl.text.trim().isEmpty) return;
            ref.read(userNekathProvider.notifier).addNekath(UserNekath(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              eventType: typeCtrl.text.trim(),
              date: dateCtrl.text.trim(),
              startTime: startCtrl.text.trim(),
              endTime: endCtrl.text.trim(),
            ));
            Navigator.pop(dialogCtx);
          },
          child: const Text('Add'),
        ),
      ],
    ));
  }
}
