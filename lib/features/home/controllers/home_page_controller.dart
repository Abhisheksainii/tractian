import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tractian/features/core_tree/helpers/tree_helper.dart';
import 'package:tractian/features/core_tree/tree_node.dart';
import 'package:tractian/features/home/models/company_model.dart';

final homepageController =
    ChangeNotifierProvider((ref) => HomePageController());

class HomePageController extends ChangeNotifier {
  Map<String, dynamic> _apiData = {};

  Map<String, dynamic> get apiData => _apiData;

  final _treeControllerSubject = BehaviorSubject<TreeController<MyNode>>();
  ValueStream<TreeController<MyNode>> get treeControllerStream =>
      _treeControllerSubject.stream;

  final _searchSubject = BehaviorSubject<String>.seeded("");
  ValueStream<String> get searchStream => _searchSubject.stream;

  final _energySensorFilterSubject = BehaviorSubject<bool>.seeded(false);
  ValueStream<bool> get energySensorFilterStream =>
      _energySensorFilterSubject.stream;

  final _criticalSensorStatusFilterSubject =
      BehaviorSubject<bool>.seeded(false);
  ValueStream<bool> get criticalSensorStatusFilterStream =>
      _criticalSensorStatusFilterSubject.stream;

  void addSearchQuery(String query) {
    _searchSubject.add(query);
  }

  void enableEnergySensorFilter(bool val) {
    _energySensorFilterSubject.add(val);
  }

  void enableCriticalSensorStatusFilter(bool val) {
    _criticalSensorStatusFilterSubject.add(val);
  }

  void addTreeController() {
    _treeControllerSubject.add(TreeController<MyNode>(
      roots: roots,
      childrenProvider: (MyNode node) => node.children,
    ));
  }

  ValueStream<TreeController<MyNode>> get filteredRootsStream =>
      Rx.combineLatest4(_searchSubject, _treeControllerSubject,
          _criticalSensorStatusFilterSubject, _energySensorFilterSubject,
          (query, controller, isAlertStatus, enableEnergySensor) {
        print("filtering: energy:$enableEnergySensor alert:$isAlertStatus");
        return TreeController<MyNode>(
          roots: searchTreeByFilter(
              searchTree(roots, query), isAlertStatus, enableEnergySensor),
          childrenProvider: (MyNode node) => node.children,
        );
      }).shareValue();

  List<MyNode> _roots = List<MyNode>.empty(growable: true);
  List<MyNode> get roots => _roots;

  set roots(List<MyNode> val) {
    _roots = val;
    notifyListeners();
  }

  bool _companiesLoading = false;
  bool get companiesLoading => _companiesLoading;
  set companiesLoading(val) {
    _companiesLoading = val;
  }

  TreeController<MyNode>? treeController;

  initializeTreecontroller() {
    // treeController = ;
  }

  List<Company> _companies = List<Company>.empty(growable: true);
  List<Company> get companies => _companies;

  set companies(List<Company> val) {
    _companies = val;
    notifyListeners();
  }

  Future<void> fetchApiData() async {
    final data = jsonDecode(await rootBundle.loadString("assets/data.json"))
        as Map<String, dynamic>;
    _apiData = data;
  }

  void loadCompanies() {
    final companiesData = apiData["companies"] as List;
    companiesData.map((e) => e as Map<String, dynamic>).toList();

    _companies.addAll(companiesData.map((e) => Company.fromJson(e)).toList());
    notifyListeners();
  }

  void fetchCompanySpecificData({required String companyId}) {
    final locations = apiData[companyId]["locations"] as List;
    final assets = apiData[companyId]["assets"] as List;
    buildTree(locations.map((e) => e as Map<String, dynamic>).toList(),
        assets.map((e) => e as Map<String, dynamic>).toList());
  }

  TreeItem getIcon(String id, String companyId) {
    final locations = (apiData[companyId]["locations"] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final assets = (apiData[companyId]["assets"] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    if (locations.any((element) => element["id"] == id)) {
      return TreeItem.location;
    }

    if (assets.any((element) {
      if (element["id"] == id && element["sensorType"] == null) {
        return true;
      }
      return false;
    })) {
      return TreeItem.asset;
    }
    return TreeItem.component;
  }

  void buildTree(
      List<Map<String, dynamic>> locations, List<Map<String, dynamic>> assets) {
    Map<String, MyNode> nodeMap = {};
    Map<String, List<MyNode>> childMap = {};

    Map<String, MyNode> nodeAssetMap = {};
    Map<String, List<MyNode>> childAssetMap = {};

    for (var location in locations) {
      final node = MyNode(
        name: location['name'],
        id: location['id'],
      );
      nodeMap[location['id']] = node;
      childMap[location['id']] = [];
    }

    for (var asset in assets) {
      var node = MyNode(
        name: asset['name'],
        id: asset['id'],
        sensorStatus: asset['status'],
        sensorType: asset['sensorType'],
      );

      nodeAssetMap[asset['id']] = node;
      childAssetMap[asset['id']] = [];
    }

    for (var asset in assets) {
      if (asset['parentId'] != null) {
        final parentId = asset['parentId'];

        childAssetMap[parentId]!.add(nodeAssetMap[asset['id']]!);
      }
    }

    for (var entry in nodeAssetMap.entries) {
      final nodeId = entry.key;
      final node = entry.value;
      nodeAssetMap[nodeId] = node.copyWith(
          children: childAssetMap[nodeId],
          sensorType: node.sensorType,
          status: node.sensorStatus);
      print(
          "node: ${nodeAssetMap[nodeId]?.sensorStatus} ${nodeAssetMap[nodeId]?.sensorType}");
    }
    for (var asset in assets) {
      if (asset['parentId'] == null && asset['locationId'] != null) {
        final locationId = asset['locationId'];
        childMap[locationId]!.add(nodeAssetMap[asset['id']]!);
      }
    }

    for (var entry in nodeMap.entries) {
      final nodeId = entry.key;
      final node = entry.value;
      nodeMap[nodeId] = node.copyWith(children: childMap[nodeId]);
    }

    for (var location in locations) {
      if (location['parentId'] != null) {
        final parentId = location['parentId'];
        childMap[parentId]!.add(nodeMap[location['id']]!);
      }
    }

    for (var entry in nodeMap.entries) {
      final nodeId = entry.key;
      final node = entry.value;
      nodeMap[nodeId] = node.copyWith(children: childMap[nodeId]);
    }

    List<MyNode> roots = nodeMap.values
        .where((node) => locations
            .any((loc) => loc['id'] == node.id && loc['parentId'] == null))
        .toList();

    for (var asset in assets) {
      if (asset['parentId'] == null && asset['locationId'] == null) {
        roots.add(nodeAssetMap[asset["id"]]!);
      }
    }

    this.roots = roots;
  }

  List<MyNode> searchTree(
    List<MyNode> tree,
    String name,
  ) {
    if (name.isEmpty) {
      return tree;
    }

    for (var root in tree) {
      var result = root.search(name);
      if (result != null && result.isNotEmpty) {
        return [result.first];
      }
    }
    return [];
  }

  List<MyNode> searchTreeByFilter(
      List<MyNode> tree, bool enableAlertStatus, bool enableEnergySensor) {
    if (enableAlertStatus == false && enableEnergySensor == false) {
      return tree;
    }
    final nodes = <MyNode>[];
    for (var root in tree) {
      var result = root.searchByFilter(enableAlertStatus, enableEnergySensor);
      if (result != null && result.isNotEmpty) {
        nodes.add(result.first);
      }
    }
    return nodes;
  }

  @override
  void dispose() {
    super.dispose();
    treeController?.dispose();
  }
}
