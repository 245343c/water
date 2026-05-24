/**
 * Customer ledger: pending amount (owed) and advance credit (prepaid) stay non-negative.
 */
function applyDeliveryCharge(customer, amount) {
  const charge = Math.max(0, Number(amount) || 0);
  if (charge === 0) return;

  let remaining = charge;
  const advance = Math.max(0, customer.advanceCredit || 0);
  if (advance > 0) {
    const fromAdvance = Math.min(advance, remaining);
    customer.advanceCredit = advance - fromAdvance;
    remaining -= fromAdvance;
  }
  customer.totalPendingAmount = Math.max(0, (customer.totalPendingAmount || 0) + remaining);
}

function applyPayment(customer, amount) {
  const paid = Math.max(0, Number(amount) || 0);
  if (paid === 0) return;

  let remaining = paid;
  const pending = Math.max(0, customer.totalPendingAmount || 0);
  if (pending > 0) {
    const toPending = Math.min(pending, remaining);
    customer.totalPendingAmount = pending - toPending;
    remaining -= toPending;
  }
  if (remaining > 0) {
    customer.advanceCredit = Math.max(0, (customer.advanceCredit || 0) + remaining);
  }
}

function reverseDeliveryCharge(customer, amount) {
  const charge = Math.max(0, Number(amount) || 0);
  if (charge === 0) return;

  let remaining = charge;
  const pending = Math.max(0, customer.totalPendingAmount || 0);
  if (pending > 0) {
    const fromPending = Math.min(pending, remaining);
    customer.totalPendingAmount = pending - fromPending;
    remaining -= fromPending;
  }
  if (remaining > 0) {
    const advance = Math.max(0, customer.advanceCredit || 0);
    customer.advanceCredit = Math.max(0, advance - remaining);
  }
}

function reversePayment(customer, amount) {
  const paid = Math.max(0, Number(amount) || 0);
  if (paid === 0) return;

  let remaining = paid;
  const advance = Math.max(0, customer.advanceCredit || 0);
  if (advance > 0) {
    const fromAdvance = Math.min(advance, remaining);
    customer.advanceCredit = advance - fromAdvance;
    remaining -= fromAdvance;
  }
  if (remaining > 0) {
    customer.totalPendingAmount = Math.max(0, (customer.totalPendingAmount || 0) + remaining);
  }
}

module.exports = {
  applyDeliveryCharge,
  applyPayment,
  reverseDeliveryCharge,
  reversePayment,
};
