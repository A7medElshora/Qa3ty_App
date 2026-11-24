import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qa3ty_app/core/cubit/internet/internet_cubit.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';

Widget buildAppWithProviders({required Widget child}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => InternetCubit()..checkStreamConnection(),
      ),
      BlocProvider.value(
        value: ServicesLocator.authCubit,
      ),
    ],
    child: child,
  );
}
