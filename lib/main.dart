import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/providers/cartcustomer_provider.dart';
import 'package:pos_app/providers/orderinfo_provider.dart';
import 'package:pos_app/providers/user_provider.dart';
import 'package:pos_app/views/startup_view.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/providers/cart_provider_refund.dart';

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

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
          ChangeNotifierProvider(create: (context) => UserProvider()),
          ChangeNotifierProvider(create: (_) => SalesCustomerProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => RCartProvider()),
          ChangeNotifierProvider(create: (_) => OrderInfoProvider()),
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
