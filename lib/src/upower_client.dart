import 'dart:async';

import 'package:dbus/dbus.dart';

/// Type of device.
enum UPowerDeviceType {
  unknown,
  linePower,
  battery,
  ups,
  monitor,
  mouse,
  keyboard,
  pda,
  phone
}

/// Current state of device.
enum UPowerDeviceState {
  unknown,
  charging,
  discharging,
  empty,
  fullyCharged,
  pendingCharge,
  pendingDischarge
}

/// Battery technology type.
enum UPowerDeviceTechnology {
  unknown,
  lithiumIon,
  lithiumPolymer,
  lithiumIronPhosphate,
  leadAcid,
  nickelCadmium,
  nickelMetalHydride,
}

/// Warning state of a device.
enum UPowerDeviceWarningLevel {
  unknown,
  none,
  discharging,
  low,
  critical,
  action
}

/// Current battery level.
enum UPowerDeviceBatteryLevel {
  unknown,
  none,
  low,
  critical,
  normal,
  high,
  full
}

/// A sample point of a device.
class UPowerDeviceHistoryRecord {
  /// Time time this occured in seconds from the epoch.
  final int time;

  /// Sample at this time.
  final double value;

  /// Device state at this time.
  final UPowerDeviceState state;

  const UPowerDeviceHistoryRecord(this.time, this.value, this.state);

  @override
  String toString() =>
      'UPowerDeviceHistoryRecord(time: ${time}, value: ${value}, state: ${state})';
}

/// A statistic sample point of a device.
class UPowerDeviceStatisticsRecord {
  /// Statistical value.
  final double value;

  /// Statistic accuracy in percentage.
  final double accuracy;

  const UPowerDeviceStatisticsRecord(this.value, this.accuracy);

  @override
  String toString() =>
      'UPowerDeviceHistoryRecord(value: ${value}, accuracy: ${accuracy})';
}

/// A device being managed by UPower.
class UPowerDevice extends DBusRemoteObject {
  final _properties = <String, DBusValue>{};
  StreamSubscription _propertiesChangedSubscription;
  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();

  /// OS specific native path of this power source.
  String get nativePath => (_properties['NativePath'] as DBusString).value;

  /// Name of the vendor of the device.
  String get vendor => (_properties['Vendor'] as DBusString).value;

  /// Name of the model of this device.
  String get model => (_properties['Model'] as DBusString).value;

  /// Unique serial number for this device.
  String get serial => (_properties['Serial'] as DBusString).value;

  /// Time this device was last updated
  int get updateTime => (_properties['UpdateTime'] as DBusUint64)
      .value; // FIXME(robert-ancell): Use a time class

  /// Type of power source.
  UPowerDeviceType get type =>
      UPowerDeviceType.values[(_properties['Type'] as DBusUint32).value];

  /// True if this device is used to supply power to the system.
  bool get powerSupply => (_properties['PowerSupply'] as DBusBoolean).value;

  /// True if this device will return history from [getHistory].
  bool get hasHistory => (_properties['HasHistory'] as DBusBoolean).value;

  /// True if this device will return statistics from [getStatistics].
  bool get hasStatistics => (_properties['HasStatistics'] as DBusBoolean).value;

  /// True if this is currently providing power. Only applicable for [UPowerDeviceType.linePower].
  bool get online => (_properties['Online'] as DBusBoolean).value;

  /// Amount of energy available in Wh. Only applicable for [UPowerDeviceType.battery].
  double get energy => (_properties['Energy'] as DBusDouble).value;

  /// Amount of energy available in Wh when this battery is considered empty. Only applicable for [UPowerDeviceType.battery].
  double get energyEmpty => (_properties['EnergyEmpty'] as DBusDouble).value;

  /// Amount of energy available in Wh when this battery is considered full. Only applicable for [UPowerDeviceType.battery].
  double get energyFull => (_properties['EnergyFull'] as DBusDouble).value;

  /// Amount of energy available in Wh this battery is designed to hold when full. Only applicable for [UPowerDeviceType.battery].
  double get energyFullDesign =>
      (_properties['EnergyFullDesign'] as DBusDouble).value;

  /// Amount of energy being drained from this source in Watts.
  double get energyRate => (_properties['EnergyRate'] as DBusDouble).value;

  /// Current voltage of the supply.
  double get voltage => (_properties['Voltage'] as DBusDouble).value;

  /// Current luminosity.
  double get luminosity => (_properties['Luminosity'] as DBusDouble).value;

  /// Estimated time until this source is empty, in seconds.
  int get timeToEmpty => (_properties['TimeToEmpty'] as DBusInt64).value;

  /// Estimated time until this source is full, in seconds.
  int get timeToFull => (_properties['TimeToFull'] as DBusInt64).value;

  /// Amount of energy left in this source as a percentage.
  double get percentage => (_properties['Percentage'] as DBusDouble).value;

  /// Temperature of this device in degrees Celcius. Only applicable for [UPowerDeviceType.battery].
  double get temperature => (_properties['Temperature'] as DBusDouble).value;

  /// True if there is a battery in the bay. Only applicable for [UPowerDeviceType.battery].
  bool get isPresent => (_properties['IsPresent'] as DBusBoolean).value;

  /// The battery power state. Only applicable for [UPowerDeviceType.battery].
  UPowerDeviceState get state =>
      UPowerDeviceState.values[(_properties['State'] as DBusUint32).value];

  /// True if this battery can be recharged. Only applicable for [UPowerDeviceType.battery].
  bool get isRechargeable =>
      (_properties['IsRechargeable'] as DBusBoolean).value;

  /// The capacity of this battery as a percentage. Only applicable for [UPowerDeviceType.battery].
  double get capacity => (_properties['Capacity'] as DBusDouble).value;

  /// The battery technology. Only applicable for [UPowerDeviceType.battery].
  UPowerDeviceTechnology get technology => UPowerDeviceTechnology
      .values[(_properties['Technology'] as DBusUint32).value];

  UPowerDeviceWarningLevel get warningLevel => UPowerDeviceWarningLevel
      .values[(_properties['WarningLevel'] as DBusUint32).value];

  /// The battery level. Only applicable for [UPowerDeviceType.battery].
  UPowerDeviceBatteryLevel get batteryLevel => UPowerDeviceBatteryLevel
      .values[(_properties['BatteryLevel'] as DBusUint32).value];

  /// An icon to show for this device.
  String get iconName => (_properties['IconName'] as DBusString).value;

  /// Stream of property names as they change.
  Stream<List<String>> get propertiesChanged =>
      _propertiesChangedController.stream;

  UPowerDevice(DBusClient systemBus, DBusObjectPath path)
      : super(systemBus, 'org.freedesktop.UPower', path);

  /// Connects to the UPower daemon.
  Future _connect() async {
    var changedSignals = await subscribePropertiesChanged();
    _propertiesChangedSubscription = changedSignals.listen((signal) {
      if (signal.propertiesInterface == 'org.freedesktop.UPower.Device') {
        _updateProperties(signal.changedProperties);
      }
    });
    _updateProperties(await getAllProperties('org.freedesktop.UPower.Device'));
  }

  void _updateProperties(Map<String, DBusValue> properties) {
    _properties.addAll(properties);
    _propertiesChangedController.add(properties.keys.toList());
  }

  void _close() {
    if (_propertiesChangedSubscription != null) {
      _propertiesChangedSubscription.cancel();
      _propertiesChangedSubscription = null;
    }
  }

  /// Refreshes properties of this device.
  Future refresh() async {
    await callMethod('org.freedesktop.UPower.Device', 'Refresh', []);
  }

  /// Gets history of [type] ('rate' or 'charge').
  Future<List<UPowerDeviceHistoryRecord>> getHistory(
      String type, int resolution,
      {int timespan = 0}) async {
    var result = await callMethod('org.freedesktop.UPower.Device', 'GetHistory',
        [DBusString(type), DBusUint32(timespan), DBusUint32(resolution)]);
    var records = <UPowerDeviceHistoryRecord>[];
    var children = (result.returnValues[0] as DBusArray)
        .children
        .map((e) => e as DBusStruct);
    for (var child in children) {
      var values = child.children.toList();
      var time = (values[0] as DBusUint32).value;
      var value = (values[1] as DBusDouble).value;
      var state = UPowerDeviceState.values[(values[2] as DBusUint32).value];
      records.add(UPowerDeviceHistoryRecord(time, value, state));
    }
    return records;
  }

  /// Gets statistics on this device of [type] ('charging', 'discharging').
  Future<List<UPowerDeviceStatisticsRecord>> getStatistics(String type) async {
    var result = await callMethod(
        'org.freedesktop.UPower.Device', 'GetStatistics', [DBusString(type)]);
    var records = <UPowerDeviceStatisticsRecord>[];
    var children = (result.returnValues[0] as DBusArray)
        .children
        .map((e) => e as DBusStruct);
    for (var child in children) {
      var values = child.children.toList();
      var value = (values[0] as DBusDouble).value;
      var accuracy = (values[1] as DBusDouble).value;
      records.add(UPowerDeviceStatisticsRecord(value, accuracy));
    }
    return records;
  }

  @override
  String toString() => 'UpowerDevice(type: ${type})';
}

/// A client that connects to UPower.
class UPowerClient extends DBusRemoteObject {
  final _properties = <String, DBusValue>{};
  StreamSubscription _propertiesChangedSubscription;
  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();
  final _devices = <DBusObjectPath, UPowerDevice>{};
  StreamSubscription _deviceAddedSubscription;
  final _deviceAddedController = StreamController<UPowerDevice>.broadcast();
  StreamSubscription _deviceRemovedSubscription;
  final _deviceRemovedController = StreamController<UPowerDevice>.broadcast();
  UPowerDevice _displayDevice;

  /// The version of the UPower daemon.
  String get daemonVersion =>
      (_properties['DaemonVersion'] as DBusString).value;

  /// True if currently being powered by battery.
  bool get onBattery => (_properties['OnBattery'] as DBusBoolean).value;

  /// True if a lid is present (e.g. on a laptop).
  bool get lidIsPresent => (_properties['LidIsPresent'] as DBusBoolean).value;

  /// True if the lid is closed.
  bool get lidIsClosed => (_properties['LidIsClosed'] as DBusBoolean).value;

  /// Power devices on this system.
  Iterable<UPowerDevice> get devices => _devices.values;

  /// Composite device to get the overall system state.
  UPowerDevice get displayDevice => _displayDevice;

  /// Stream of devices as they are added.
  Stream<UPowerDevice> get deviceAdded => _deviceAddedController.stream;

  /// Stream of devices as they are removed.
  Stream<UPowerDevice> get deviceRemoved => _deviceRemovedController.stream;

  /// Stream of property names as they change.
  Stream<List<String>> get propertiesChanged =>
      _propertiesChangedController.stream;

  /// Creates a new UPower client connected to the system D-Bus.
  UPowerClient(DBusClient systemBus)
      : super(systemBus, 'org.freedesktop.UPower',
            DBusObjectPath('/org/freedesktop/UPower'));

  /// Connects to the UPower daemon.
  Future connect() async {
    var changedSignals = await subscribePropertiesChanged();
    _propertiesChangedSubscription = changedSignals.listen((signal) {
      if (signal.propertiesInterface == 'org.freedesktop.UPower') {
        _updateProperties(signal.changedProperties);
      }
    });
    _updateProperties(await getAllProperties('org.freedesktop.UPower'));

    var addedSignals =
        await subscribeSignal('org.freedesktop.UPower', 'DeviceAdded');
    _deviceAddedSubscription = addedSignals
        .listen((signal) => _deviceAdded((signal.values[0] as DBusObjectPath)));
    var removedSignals =
        await subscribeSignal('org.freedesktop.UPower', 'DeviceRemoved');
    _deviceRemovedSubscription = removedSignals.listen(
        (signal) => _deviceRemoved((signal.values[0] as DBusObjectPath)));

    var devicePaths = await _enumerateDevices();
    for (var path in devicePaths) {
      await _deviceAdded(path);
    }

    _displayDevice = UPowerDevice(client,
        DBusObjectPath('/org/freedesktop/UPower/devices/DisplayDevice'));
    await _displayDevice._connect();
  }

  /// Gets the action the system will take when the power supply is critical.
  Future<String> getCriticalAction() async {
    var result =
        await callMethod('org.freedesktop.UPower', 'GetCriticalAction', []);
    return (result.returnValues[0] as DBusString).value;
  }

  /// Terminates the connection to the UPower daemon. If a client remains unclosed, the Dart process may not terminate.
  void close() {
    _displayDevice._close();
    for (var device in devices) {
      device._close();
    }
    if (_propertiesChangedSubscription != null) {
      _propertiesChangedSubscription.cancel();
      _propertiesChangedSubscription = null;
    }
    if (_deviceAddedSubscription != null) {
      _deviceAddedSubscription.cancel();
      _deviceAddedSubscription = null;
    }
    if (_deviceRemovedSubscription != null) {
      _deviceRemovedSubscription.cancel();
      _deviceRemovedSubscription = null;
    }
  }

  void _updateProperties(Map<String, DBusValue> properties) {
    _properties.addAll(properties);
    _propertiesChangedController.add(properties.keys.toList());
  }

  Future<List<DBusObjectPath>> _enumerateDevices() async {
    var result =
        await callMethod('org.freedesktop.UPower', 'EnumerateDevices', []);
    return (result.returnValues[0] as DBusArray)
        .children
        .map((child) => child as DBusObjectPath)
        .toList();
  }

  void _deviceAdded(DBusObjectPath path) async {
    var device = UPowerDevice(client, path);
    await device._connect();
    _devices[path] = device;
    _deviceAddedController.add(device);
  }

  void _deviceRemoved(DBusObjectPath path) async {
    var device = _devices[path];
    if (device == null) {
      return;
    }
    _devices.remove(path);
    _deviceRemovedController.add(device);
  }
}
