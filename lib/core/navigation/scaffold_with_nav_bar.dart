import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qa3ty_app/core/services/locator/get_it_locator.dart';
import 'package:qa3ty_app/features/halls/presentation/cubits/halls_cubit.dart';
import 'package:qa3ty_app/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:qa3ty_app/core/utils/widgets/app_bottom_nav.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: navigationShell,
      bottomNavigationBar: StreamBuilder<AuthState>(
        stream: ServicesLocator.authCubit.stream,
        initialData: ServicesLocator.authCubit.state,
        builder: (context, _) => AppBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            if (index == 0) {
              context.read<HallsCubit>().loadHalls();
            }
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}
