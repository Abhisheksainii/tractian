import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tractian/common/colors.dart';
import 'package:tractian/features/core_tree/helpers/tree_helper.dart';
import 'package:tractian/features/core_tree/tree_node.dart';
import 'package:tractian/features/home/controllers/home_page_controller.dart';

class CoreTree extends ConsumerStatefulWidget {
  const CoreTree({required this.companyId, super.key});

  final String companyId;

  @override
  ConsumerState<CoreTree> createState() => _CoreTreeState();
}

class _CoreTreeState extends ConsumerState<CoreTree> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref
          .watch(homepageController)
          .fetchCompanySpecificData(companyId: widget.companyId);
      ref.watch(homepageController).addTreeController();
      ref.watch(homepageController).addSearchQuery("");
    });
  }

  @override
  void dispose() {
    // ref.watch(homepageController).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homepageController);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Kcolors.darkBlue,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        title: const Text(
          "Assets",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 18, right: 18, top: 18),
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEAEFF3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: (val) {
                  homeState.addSearchQuery(val);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Kcolors.lightGrey,
                  ),
                  labelStyle: TextStyle(color: Kcolors.lightGrey),
                ),
              ),
            ),
            Row(
              children: [
                StreamBuilder<bool>(
                    stream: homeState.energySensorFilterStream,
                    builder: (context, snapshot) {
                      final val = snapshot.data;
                      return GestureDetector(
                        onTap: () {
                          if (val ?? false) {
                            homeState.enableEnergySensorFilter(false);
                          } else {
                            homeState.enableEnergySensorFilter(true);
                          }
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          margin: const EdgeInsets.all(18),
                          height: 32,
                          decoration: BoxDecoration(
                            color: val ?? false
                                ? Kcolors.blue
                                : const Color(0xFFEAEFF3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt,
                                color: val ?? false
                                    ? Colors.white
                                    : Kcolors.lightGrey,
                              ),
                              Text("Energy Sensor",
                                  style: TextStyle(
                                      color: val ?? false
                                          ? Colors.white
                                          : Kcolors.lightGrey)),
                            ],
                          ),
                        ),
                      );
                    }),
                StreamBuilder<bool>(
                    stream: homeState.criticalSensorStatusFilterStream,
                    builder: (context, snapshot) {
                      final val = snapshot.data;
                      return GestureDetector(
                        onTap: () {
                          if (val ?? false) {
                            homeState.enableCriticalSensorStatusFilter(false);
                          } else {
                            homeState.enableCriticalSensorStatusFilter(true);
                          }
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          margin: const EdgeInsets.all(18),
                          height: 32,
                          decoration: BoxDecoration(
                            color: val ?? false
                                ? Kcolors.blue
                                : const Color(0xFFEAEFF3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info,
                                color: val ?? false
                                    ? Colors.white
                                    : Kcolors.lightGrey,
                              ),
                              Text("Critical",
                                  style: TextStyle(
                                      color: val ?? false
                                          ? Colors.white
                                          : Kcolors.lightGrey)),
                            ],
                          ),
                        ),
                      );
                    }),
              ],
            ),
            StreamBuilder<TreeController<MyNode>>(
                stream: homeState.filteredRootsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final controller = snapshot.data;
                    return Flexible(
                      child: TreeView<MyNode>(
                          treeController: controller!,
                          nodeBuilder:
                              (BuildContext context, TreeEntry<MyNode> entry) {
                            return TreeIndentation(
                              entry: entry,
                              guide:
                                  const IndentGuide.connectingLines(indent: 40),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      entry.hasChildren
                                          ? controller
                                              .toggleExpansion(entry.node)
                                          : null;
                                    },
                                    icon: Image.asset(
                                      homeState
                                          .getIcon(
                                              entry.node.id, widget.companyId)
                                          .iconPath,
                                      width: 25,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      entry.node.name,
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                    );
                  }
                  return const CircularProgressIndicator();
                }),
          ],
        ),
      ),
    );
  }
}
