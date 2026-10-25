import 'package:flutter/material.dart';

class StartupFailure extends StatelessWidget {
  const StartupFailure({super.key, required this.storageUnavailable});

  final bool storageUnavailable;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nizam',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  storageUnavailable
                      ? 'Kalıcı ve güvenli tarayıcı depolaması kullanılamıyor. '
                          'Gizli pencere yerine normal bir tarayıcı penceresi '
                          'kullanın ve site depolamasına izin verin. '
                          'Sorun sürerse Android uygulamasını kullanın.'
                      : 'Nizam başlatılamadı. Mevcut kayıtlar silinmedi. '
                          'Uygulamayı yeniden açın; sorun sürerse destek alın.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
}
