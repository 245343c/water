enum PaymentMethod {
  cash('Cash'),
  upi('UPI'),
  other('Other');

  const PaymentMethod(this.label);
  final String label;
}
