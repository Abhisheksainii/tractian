import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tractian/common/colors.dart';
import 'package:tractian/features/core_tree/presentation/core_tree.dart';
import 'package:tractian/features/home/controllers/home_page_controller.dart';
import 'package:tractian/features/home/models/company_model.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.watch(homepageController).fetchApiData();
      ref.watch(homepageController).loadCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homepageController);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Kcolors.darkBlue,
        centerTitle: true,
        title: const Text(
          "TRACTIAN",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(30),
        child: ListView.separated(
          separatorBuilder: (context, index) {
            return const SizedBox(
              height: 30,
            );
          },
          itemBuilder: (context, index) {
            final company = homeState.companies[index];
            return CompanyWidget(company: company);
          },
          itemCount: homeState.companies.length,
        ),
      ),
    );
  }
}

class CompanyWidget extends StatelessWidget {
  const CompanyWidget({
    super.key,
    required this.company,
  });

  final Company company;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return CoreTree(companyId: company.id);
        }));
      },
      child: Container(
        width: 317,
        height: 76,
        decoration: BoxDecoration(
            color: Kcolors.blue, borderRadius: BorderRadius.circular(7)),
        child: CompanyRow(
          company: company,
          icon: Icons.business,
        ),
      ),
    );
  }
}

class CompanyRow extends StatelessWidget {
  const CompanyRow({
    super.key,
    required this.company,
    required this.icon,
  });

  final Company company;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.white,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          company.companyName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
