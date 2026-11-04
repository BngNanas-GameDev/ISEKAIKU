import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Halaman dukungan: menampilkan gambar donasi (bisa di-zoom).
class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  static const String imagePath = 'assets/donate/DOnate.webp';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Dukung Isekaiku', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Isekaiku gratis dan tanpa iklan. Kalau kamu merasa terbantu, '
                'dukunganmu dipakai untuk biaya server dan pengembangan.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.onSurfaceVariant,
                          ),
                          SizedBox(height: AppSpacing.m),
                          Text(
                            'Gambar donasi belum tersedia.',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Cubit dua jari untuk memperbesar.',
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (AppConfig.hasSaweria) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Donasi QRIS',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: AppSpacing.s),
                const _SaweriaQr(),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Scan QR dengan aplikasi bank atau e-wallet. '
                  'Pembayaran diproses oleh Saweria.',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(AppConfig.saweriaQrUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Buka di browser'),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Terima kasih sudah membaca di Isekaiku.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget QR Saweria (donasi QRIS) di dalam WebView.
class _SaweriaQr extends StatefulWidget {
  const _SaweriaQr();

  @override
  State<_SaweriaQr> createState() => _SaweriaQrState();
}

class _SaweriaQrState extends State<_SaweriaQr> {
  late final WebViewController _controller;

  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            // Abaikan error subresource (font/gambar); hanya halaman utama.
            if (error.isForMainFrame == false) return;
            if (mounted) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
          onNavigationRequest: (request) {
            final Uri? uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            final bool internal =
                uri.host == 'saweria.co' || uri.host.endsWith('.saweria.co');
            if (internal) return NavigationDecision.navigate;

            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(AppConfig.saweriaQrUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: _failed
          ? _Fallback(onOpen: _openExternal)
          : Stack(
              children: <Widget>[
                WebViewWidget(controller: _controller),
                if (_loading)
                  const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _openExternal() async {
    await launchUrl(
      Uri.parse(AppConfig.saweriaQrUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.onOpen});

  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.qr_code_2,
            size: 48,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            'QR tidak bisa dimuat di aplikasi.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.m),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Buka di browser'),
          ),
        ],
      ),
    );
  }
}
