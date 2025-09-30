import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/api_config.dart';
import 'package:pos_app/core/network/network_info.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/core/theme/theme_provider.dart';
import 'package:pos_app/core/widgets/startup_view.dart';

// Repository interfaces
import 'package:pos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos_app/features/products/domain/repositories/product_repository.dart';
import 'package:pos_app/features/customer/domain/repositories/customer_repository.dart';
import 'package:pos_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:pos_app/features/orders/domain/repositories/order_repository.dart';
import 'package:pos_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:pos_app/features/sync/domain/repositories/sync_repository.dart';

// Repository implementations
import 'package:pos_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pos_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:pos_app/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:pos_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:pos_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:pos_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:pos_app/features/sync/data/repositories/sync_repository_impl.dart';

// State providers
import 'package:pos_app/features/auth/presentation/providers/user_provider.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:pos_app/features/customer/presentation/providers/cartcustomer_provider.dart';
import 'package:pos_app/features/orders/presentation/providers/orderinfo_provider.dart';
import 'package:pos_app/features/refunds/presentation/providers/cart_provider_refund.dart';

import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Core services - DIAPALET tarzı
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  final dio = ApiConfig.dio;
  final connectivity = Connectivity();
  final networkInfo = NetworkInfoImpl(connectivity);

  // Sadece dikey yönlendirmeye izin ver
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      child: MultiProvider(
        providers: [
          // Core services - DIAPALET tarzı
          Provider<DatabaseHelper>.value(value: dbHelper),
          Provider<Dio>.value(value: dio),
          Provider<NetworkInfo>.value(value: networkInfo),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),

          // Repository layer - DIAPALET tarzı DI
          Provider<AuthRepository>(
            create: (context) => AuthRepositoryImpl(
              dbHelper: context.read<DatabaseHelper>(),
              networkInfo: context.read<NetworkInfo>(),
              dio: context.read<Dio>(),
            ),
          ),
          Provider<ProductRepository>(
            create: (context) => ProductRepositoryImpl(
              dbHelper: context.read<DatabaseHelper>(),
              networkInfo: context.read<NetworkInfo>(),
              dio: context.read<Dio>(),
            ),
          ),
          Provider<CustomerRepository>(
            create: (context) => CustomerRepositoryImpl(
              dbHelper: context.read<DatabaseHelper>(),
              networkInfo: context.read<NetworkInfo>(),
              dio: context.read<Dio>(),
            ),
          ),
          Provider<CartRepository>(
            create: (context) => CartRepositoryImpl(
              dbHelper: context.read<DatabaseHelper>(),
              networkInfo: context.read<NetworkInfo>(),
              dio: context.read<Dio>(),
            ),
          ),
          Provider<OrderRepository>(
            create: (context) => OrderRepositoryImpl(
              dbHelper: context.read<DatabaseHelper>(),
              networkInfo: context.read<NetworkInfo>(),
              dio: context.read<Dio>(),
            ),
          ),
          Provider<TransactionRepository>(
            create: (context) => TransactionRepositoryImpl(
              dbHelper: context.read<DatabaseHelper>(),
              networkInfo: context.read<NetworkInfo>(),
              dio: context.read<Dio>(),
            ),
          ),
          Provider<SyncRepository>(
            create: (context) => SyncRepositoryImpl(
              dbHelper: context.read<DatabaseHelper>(),
              networkInfo: context.read<NetworkInfo>(),
              dio: context.read<Dio>(),
              productRepository: context.read<ProductRepository>(),
              customerRepository: context.read<CustomerRepository>(),
              orderRepository: context.read<OrderRepository>(),
              transactionRepository: context.read<TransactionRepository>(),
            ),
          ),

          // State providers - Repository ile entegre edilmiş
          ChangeNotifierProvider<UserProvider>(
            create: (context) => UserProvider(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          ChangeNotifierProvider<SalesCustomerProvider>(create: (_) => SalesCustomerProvider()),
          ChangeNotifierProvider<CartProvider>(
            create: (context) => CartProvider(
              cartRepository: context.read<CartRepository>(),
            ),
          ),
          ChangeNotifierProvider<RCartProvider>(create: (_) => RCartProvider()),
          ChangeNotifierProvider<OrderInfoProvider>(create: (_) => OrderInfoProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'POS Terminal',
          theme: AppTheme.lightTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: StartupView(), // Giriş kontrolü burada yapılacak
        );
      },
    );
  }
}
