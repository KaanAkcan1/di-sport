import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod'un üç durumunu (yükleniyor / hata / veri) tek yerden çizer.
///
/// Bu bileşen olmadan her ekran aynı `switch`i tekrar yazar; sekiz
/// ekranda sekiz farklı yükleme göstergesi ve sekiz farklı hata metni
/// oluşur. Tutarsızlığın en sık kaynağı budur.
///
/// Boş liste durumu da buraya ait: [emptyWhen] verilirse veri geldiği
/// hâlde anlamlı içerik yoksa [empty] gösterilir — boş ekran yerine
/// kullanıcıya ne yapacağını söyleyen bir mesaj
/// (ui-ux §8 `empty-states`).
class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.empty,
    this.emptyWhen,
    this.onRetry,
  });

  final AsyncValue<T> value;

  /// Veri hazır olduğunda çizilecek içerik.
  final Widget Function(T data) data;

  /// Yükleme göstergesi. Verilmezse ortalanmış ilerleme çemberi.
  /// Uzun süren yüklemelerde iskelet ekran tercih edilir
  /// (ui-ux §3 `progressive-loading`).
  final Widget? loading;

  /// Hata görünümü. Verilmezse yeniden deneme eylemli boş durum.
  final Widget Function(Object error)? error;

  /// [emptyWhen] doğru döndüğünde çizilir.
  final Widget? empty;

  /// Verinin "boş" sayıldığı koşul — örneğin `(list) => list.isEmpty`.
  final bool Function(T data)? emptyWhen;

  /// Hata görünümündeki yeniden deneme eylemi. Genellikle
  /// `() => ref.invalidate(someProvider)`.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) =>
        (emptyWhen?.call(value) ?? false)
            ? (empty ?? const AppEmptyState(title: 'Kayıt yok'))
            : data(value),
      AsyncError(:final error) =>
        this.error?.call(error) ?? _defaultError(context, error),
      _ => loading ?? const _DefaultLoading(),
    };
  }

  Widget _defaultError(BuildContext context, Object err) {
    // Hata mesajı nedeni ve çıkış yolunu birlikte verir
    // (ui-ux §8 `error-clarity`, `error-recovery`).
    return AppEmptyState(
      icon: Icons.error_outline,
      tone: AppEmptyStateTone.danger,
      title: 'Bir şeyler ters gitti',
      description: '$err',
      actionLabel: onRetry == null ? null : 'Tekrar dene',
      onAction: onRetry,
    );
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl3),
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
