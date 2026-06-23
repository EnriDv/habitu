import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;
  final bool autoJoin;
  final bool isInviteCode;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
    this.autoJoin = false,
    this.isInviteCode = false,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoJoin) {
      _joined = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reto privado',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenge ${widget.challengeId}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.isInviteCode
                  ? 'Abriste una invitacion de reto. La integracion completa con backend queda preparada para el siguiente paso.'
                  : 'Abriste el detalle de un reto desde un deep link.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _joined
                    ? 'Ya quedaste marcado para unirte a este reto en cuanto el backend lo exponga.'
                    : 'Tendras aqui descripcion, participantes, progreso y reglas.',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _joined
                    ? null
                    : () {
                        setState(() {
                          _joined = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Union marcada localmente.'),
                          ),
                        );
                      },
                child: Text(_joined ? 'Unido' : 'Unirme al reto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
