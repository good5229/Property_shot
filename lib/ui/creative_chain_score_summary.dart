import 'package:flutter/material.dart';

import '../game/analysis/creative_chain_score.dart';

class CreativeChainScoreSummary extends StatelessWidget {
  const CreativeChainScoreSummary({
    super.key,
    required this.analysis,
    this.showDetails = true,
    this.collapsibleDetails = false,
  });

  final CreativeChainScoreAnalysis analysis;
  final bool showDetails;
  final bool collapsibleDetails;

  List<Widget> _evidenceRows(BuildContext context) => [
    for (var index = 0; index < analysis.evidence.length; index++)
      Padding(
        key: Key('creative_chain_evidence_$index'),
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                analysis.evidence[index].label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+${analysis.evidence[index].points}점',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF2F7655),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: showDetails
          ? '연쇄 점수 ${analysis.totalScore}점과 점수 근거'
          : '연쇄 점수 ${analysis.totalScore}점',
      child: Container(
        key: const Key('creative_chain_score_summary'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5EE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF72A889)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.hub_rounded,
                  size: 20,
                  color: Color(0xFF2F7655),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '연쇄 점수 ${analysis.totalScore}점',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF235E43),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (showDetails && collapsibleDetails)
              Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  key: const Key('creative_chain_details_tile'),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('점수 근거 보기'),
                  children: _evidenceRows(context),
                ),
              )
            else if (showDetails) ...[
              const SizedBox(height: 8),
              ..._evidenceRows(context),
            ],
          ],
        ),
      ),
    );
  }
}
