# Sri Sai RO Water Plant

Flutter UI preview for RO water delivery management — customers, deliveries, billing, payments, and reports. Uses in-memory mock data (editable). Backend can be connected later.

## Run on Android phone (USB debug)

1. Enable **Developer options** and **USB debugging** on your phone.
2. Connect the phone with a USB cable.
3. Verify device: `flutter devices`
4. Run the app:

```bash
cd c:\Users\UNIFY\Downloads\water
flutter run
```

Hot reload: press `r` in the terminal. Hot restart: `R`.

## Screen roles (no duplicate money on customer list)

- **Dashboard** — plant-wide monthly overview (sales, cans, outstanding) + latest 5 deliveries
- **Customers** — directory only: name, phone, address, status chip (no ₹ on list)
- **Customer detail** — full account: monthly usage, balance, payments, actions
- **Bills** — monthly billing amounts and due per customer
- **Deliveries** — full log grouped by day (Today / Yesterday / date)
- **Add delivery** — normal/cool cans, pricing
- **Delivery history** — per customer, by month
- **Bills** — monthly summary and invoice preview
- **Record payment** — cash/UPI/other
- **Reports** — date range, KPIs, chart
- **More** — settings (editable prices), reset mock data

## Notes

- Data is stored in memory only (resets when app restarts unless you use **Reset Mock Data** in More).
- PDF download and notifications are placeholders for backend integration.
- Tablet layout: navigation rail on wider screens.
