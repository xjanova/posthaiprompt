// Thaiprompt POS — Route configuration with auth + role guards.
//
// Flow: first run → /setup (create owner PIN) → /login (PIN) → role home.
// Every route except /setup and /login needs a signed-in staff member;
// manager-only routes bounce other roles to /home; kitchen staff only see
// the KDS. The router listens to the store, so logout / lock re-evaluates
// instantly.
//
// Query parameters used by screens:
//   /receipt?id=A1042 · /tax-invoice?id=A1042 · /refund?id=A1042
//   /cust/item?code=P0001 · /self-order?table=7 · /cust/menu?table=7
//   /order-status?ticket=T-0001 · /shipping/labels?id=DL-0001
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../screens/accounting_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/affiliate_screen.dart';
import '../screens/barcode_screen.dart';
import '../screens/cashier_mobile_screen.dart';
import '../screens/cashier_screen.dart';
import '../screens/coupon_screen.dart';
import '../screens/create_bill_screen.dart';
import '../screens/crm_screen.dart';
import '../screens/cust_cart_screen.dart';
import '../screens/cust_confirm_screen.dart';
import '../screens/cust_item_screen.dart';
import '../screens/cust_menu_screen.dart';
import '../screens/customer_display_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/delivery_screen.dart';
import '../screens/discount_center_screen.dart';
import '../screens/floor_plan_designer_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/kitchen_display_screen.dart';
import '../screens/login_screen.dart';
import '../screens/membership_tiers_screen.dart';
import '../screens/menu_editor_screen.dart';
import '../screens/mobile_manager_screen.dart';
import '../screens/mobile_order_screen.dart';
import '../screens/multibranch_screen.dart';
import '../screens/nfc_scan_screen.dart';
import '../screens/order_status_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/purchase_order_screen.dart';
import '../screens/receipt_screen.dart';
import '../screens/refund_screen.dart';
import '../screens/screen_directory.dart';
import '../screens/self_order_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/setup_screen.dart';
import '../screens/shift_screen.dart';
import '../screens/shipping_label_screen.dart';
import '../screens/shipping_providers_screen.dart';
import '../screens/staff_screen.dart';
import '../screens/stock_management_screen.dart';
import '../screens/tablet_waiter_screen.dart';
import '../screens/tax_invoice_screen.dart';
import '../state/pos_store.dart';

/// Routes only owners/managers may open.
const kManagerRoutes = <String>{
  '/settings', '/admin', '/staff', '/accounting', '/hq', '/tiers', '/discount-center', '/coupons',
  '/menu-editor', '/po', '/shipping/providers', '/floor-designer', '/affiliate', '/dashboard',
  '/mobile/manager', '/screens', '/stock',
};

/// The only routes the kitchen role may open.
const kKitchenRoutes = <String>{'/display/kitchen', '/home', '/order-status'};

class AppRouter {
  AppRouter._();

  static GoRouter create(PosStore store) => GoRouter(
        initialLocation: '/home',
        refreshListenable: store,
        redirect: (context, state) => guard(store, state.matchedLocation),
        routes: [
          GoRoute(path: '/', redirect: (_, _) => '/home'),
          GoRoute(path: '/setup', pageBuilder: (c, s) => _fade(s, const SetupScreen())),
          GoRoute(path: '/login', pageBuilder: (c, s) => _fade(s, const LoginScreen())),
          GoRoute(path: '/home', pageBuilder: (c, s) => _fade(s, const HomeScreen())),
          GoRoute(path: '/screens', pageBuilder: (c, s) => _fade(s, const ScreenDirectory())),

          // ── Sell ──
          GoRoute(path: '/cashier', pageBuilder: (c, s) => _fade(s, const CashierScreen())),
          GoRoute(path: '/m/cashier', pageBuilder: (c, s) => _fade(s, const CashierMobileScreen())),
          GoRoute(path: '/payment', pageBuilder: (c, s) => _fade(s, const PaymentScreen())),
          GoRoute(path: '/receipt', pageBuilder: (c, s) => _fade(s, const ReceiptScreen())),
          GoRoute(path: '/orders', pageBuilder: (c, s) => _fade(s, const OrdersScreen())),
          GoRoute(path: '/bill/create', pageBuilder: (c, s) => _fade(s, const CreateBillScreen())),
          GoRoute(path: '/refund', pageBuilder: (c, s) => _fade(s, const RefundScreen())),
          GoRoute(path: '/payment/nfc', pageBuilder: (c, s) => _fade(s, const NfcScanScreen())),
          GoRoute(path: '/tax-invoice', pageBuilder: (c, s) => _fade(s, const TaxInvoiceScreen())),
          GoRoute(path: '/shift', pageBuilder: (c, s) => _fade(s, const ShiftScreen())),

          // ── Tables & kitchen ──
          GoRoute(path: '/tablet/floor', pageBuilder: (c, s) => _fade(s, const TabletWaiterScreen())),
          GoRoute(path: '/floor-designer', pageBuilder: (c, s) => _fade(s, const FloorPlanDesignerScreen())),
          GoRoute(path: '/display/kitchen', pageBuilder: (c, s) => _fade(s, const KitchenDisplayScreen())),
          GoRoute(path: '/mobile/order', pageBuilder: (c, s) => _fade(s, const MobileOrderScreen())),

          // ── Customer-facing (kiosk) ──
          GoRoute(path: '/display/customer', pageBuilder: (c, s) => _fade(s, const CustomerDisplayScreen())),
          GoRoute(path: '/self-order', pageBuilder: (c, s) => _fade(s, const SelfOrderScreen())),
          GoRoute(path: '/order-status', pageBuilder: (c, s) => _fade(s, const OrderStatusScreen())),
          GoRoute(path: '/cust/menu', pageBuilder: (c, s) => _fade(s, const CustMenuScreen())),
          GoRoute(path: '/cust/item', pageBuilder: (c, s) => _fade(s, const CustItemScreen())),
          GoRoute(path: '/cust/cart', pageBuilder: (c, s) => _fade(s, const CustCartScreen())),
          GoRoute(path: '/cust/confirm', pageBuilder: (c, s) => _fade(s, const CustConfirmScreen())),

          // ── Catalog & stock ──
          GoRoute(path: '/menu-editor', pageBuilder: (c, s) => _fade(s, const MenuEditorScreen())),
          GoRoute(path: '/inventory', pageBuilder: (c, s) => _fade(s, const InventoryScreen())),
          GoRoute(path: '/stock', pageBuilder: (c, s) => _fade(s, const StockManagementScreen())),
          GoRoute(path: '/po', pageBuilder: (c, s) => _fade(s, const PurchaseOrderScreen())),
          GoRoute(path: '/barcode', pageBuilder: (c, s) => _fade(s, const BarcodeScreen())),

          // ── Customers & promotions ──
          GoRoute(path: '/crm', pageBuilder: (c, s) => _fade(s, const CrmScreen())),
          GoRoute(path: '/tiers', pageBuilder: (c, s) => _fade(s, const MembershipTiersScreen())),
          GoRoute(path: '/coupons', pageBuilder: (c, s) => _fade(s, const CouponScreen())),
          GoRoute(path: '/discount-center', pageBuilder: (c, s) => _fade(s, const DiscountCenterScreen())),
          GoRoute(path: '/affiliate', pageBuilder: (c, s) => _fade(s, const AffiliateScreen())),

          // ── Delivery ──
          GoRoute(path: '/delivery', pageBuilder: (c, s) => _fade(s, const DeliveryScreen())),
          GoRoute(path: '/shipping/providers', pageBuilder: (c, s) => _fade(s, const ShippingProvidersScreen())),
          GoRoute(path: '/shipping/labels', pageBuilder: (c, s) => _fade(s, const ShippingLabelScreen())),

          // ── Reports & admin ──
          GoRoute(path: '/dashboard', pageBuilder: (c, s) => _fade(s, const DashboardScreen())),
          GoRoute(path: '/mobile/manager', pageBuilder: (c, s) => _fade(s, const MobileManagerScreen())),
          GoRoute(path: '/accounting', pageBuilder: (c, s) => _fade(s, const AccountingScreen())),
          GoRoute(path: '/hq', pageBuilder: (c, s) => _fade(s, const MultiBranchScreen())),
          GoRoute(path: '/staff', pageBuilder: (c, s) => _fade(s, const StaffScreen())),
          GoRoute(path: '/admin', pageBuilder: (c, s) => _fade(s, const AdminScreen())),
          GoRoute(path: '/settings', pageBuilder: (c, s) => _fade(s, const SettingsScreen())),
        ],
      );

  /// Pure guard so tests can check it without a widget tree.
  static String? guard(PosStore store, String loc) =>
      guardFor(needsSetup: store.needsSetup, me: store.currentStaff, loc: loc);

  /// Role/auth rule only — returns the redirect target, or null if allowed.
  static String? guardFor({required bool needsSetup, required Staff? me, required String loc}) {
    if (needsSetup) return loc == '/setup' ? null : '/setup';
    if (loc == '/setup') return me != null ? '/home' : '/login';
    if (me == null) return loc == '/login' ? null : '/login';
    if (loc == '/login') return me.role.home;
    if (me.role == StaffRole.kitchen && !kKitchenRoutes.contains(loc)) return '/display/kitchen';
    if (kManagerRoutes.contains(loc) && !me.role.isManager) return '/home';
    return null;
  }

  /// Fast fade transition (no horizontal slide — feels instant on a POS).
  static CustomTransitionPage _fade(GoRouterState state, Widget child) => CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 140),
        reverseTransitionDuration: const Duration(milliseconds: 100),
        transitionsBuilder: (c, anim, sec, child) => FadeTransition(opacity: anim, child: child),
      );
}
