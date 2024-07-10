class MyNode {
  const MyNode({
    required this.name,
    required this.id,
    this.sensorStatus,
    this.sensorType,
    this.children = const <MyNode>[],
  });

  final String name;
  final String id;
  final String? sensorType;
  final String? sensorStatus;
  final List<MyNode> children;

  MyNode copyWith(
      {List<MyNode>? children, String? sensorType, String? status}) {
    return MyNode(
      name: name,
      id: id,
      children: children ?? this.children,
      sensorStatus: status,
      sensorType: sensorType,
    );
  }

  List<MyNode>? search(String searchedName) {
    if (name.toLowerCase().contains(searchedName.toLowerCase())) {
      return [this];
    }

    for (var child in children) {
      var result = child.search(searchedName);
      if (result != null) {
        return [this, ...result];
      }
    }
    return null;
  }

  List<MyNode>? searchByFilter(bool isAlertStatus, bool enableEnergySensor) {
    if (isAlertStatus && !enableEnergySensor) {
      if (sensorStatus == "alert") {
        return [this];
      }

      for (var child in children) {
        var result = child.searchByFilter(isAlertStatus, enableEnergySensor);
        if (result != null && result.isNotEmpty) {
          return [this, ...result];
        }
      }
      return [];
    } else if (enableEnergySensor && !isAlertStatus) {
      if (sensorType == "energy") {
        return [this];
      }

      for (var child in children) {
        var result = child.searchByFilter(isAlertStatus, enableEnergySensor);
        if (result != null && result.isNotEmpty) {
          return [this, ...result];
        }
      }
      return [];
    } else if (enableEnergySensor && isAlertStatus) {
      if (sensorType == "energy" && sensorStatus == "alert") {
        return [this];
      }

      for (var child in children) {
        var result = child.searchByFilter(isAlertStatus, enableEnergySensor);
        if (result != null && result.isNotEmpty) {
          return [this, ...result];
        }
      }
      return [];
    }
    return [];
  }
}
