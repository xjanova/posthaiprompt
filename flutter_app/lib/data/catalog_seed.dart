// Thaiprompt POS — (no more demo seed).
//
// The POS now loads REAL data from the live terminal API
// (/api/pos/sync/products + /api/pos/sync/categories, scoped to the paired
// terminal's shop). These return EMPTY so a fresh / unpaired install starts
// clean — no demo menu, no fake customers, no fake sales. Real data fills in on
// the first sync after the terminal is paired in Settings.
//
// by xman studio

import '../models/catalog_models.dart';
import '../models/extra_models.dart';

const kSeedCategories = <Category>[];
const kSeedCoupons = <(String, int)>[];

// Growable (NOT const) — the store appends real products/customers/etc. to these.
List<Product> seedProducts() => <Product>[];
List<Customer> seedCustomers() => <Customer>[];
List<Staff> seedStaff() => <Staff>[];
List<TableInfo> seedTables() => <TableInfo>[];
List<Supplier> seedSuppliers() => <Supplier>[];
List<Branch> seedBranches() => <Branch>[];
