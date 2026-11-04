import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ui/components/daily_dashboard.dart';

class HomePage extends StatelessWidget {
	const HomePage({super.key});

	Future<void> _logout(BuildContext context) async {
		try {
			await Supabase.instance.client.auth.signOut();
			if (context.mounted) {
				Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
			}
		} catch (e) {
			if (!context.mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Não foi possível sair. Tente novamente.')),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Zyra'),
				centerTitle: true,
				actions: [
					IconButton(
						icon: const Icon(Icons.logout),
						onPressed: () => _logout(context),
					),
				],
			),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					children: [
						const DailyDashboard(),
						const SizedBox(height: 24),
						SizedBox(
							width: double.infinity,
							height: 52,
							child: ElevatedButton(
								onPressed: () {
									Navigator.pushNamed(context, '/cobranca');
								},
								child: const Text('Cobrar'),
							),
						),
						const SizedBox(height: 12),
						SizedBox(
							width: double.infinity,
							height: 52,
							child: OutlinedButton(
								onPressed: () {
									Navigator.pushNamed(context, '/history');
								},
								child: const Text('Histórico'),
							),
						),
					],
				),
			),
		);
	}
}
