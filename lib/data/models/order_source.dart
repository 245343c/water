/// How a dispatch request was created.
enum OrderSource {
  /// Customer app request — admin must accept.
  customerApp,

  /// Admin logged a phone / walk-in request.
  phoneCall;

  String get label => switch (this) {
        OrderSource.customerApp => 'App request',
        OrderSource.phoneCall => 'Walk-in dispatch',
      };
}
