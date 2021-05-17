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
      'UPowerDeviceHistoryRecord(time: $time, value: $value, state: $state)';

  @override
  bool operator ==(other) =>
      other is UPowerDeviceHistoryRecord &&
      other.time == time &&
      other.value == value &&
      other.state == state;
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
      'UPowerDeviceStatisticsRecord(value: $value, accuracy: $accuracy)';

  @override
  bool operator ==(other) =>
      other is UPowerDeviceStatisticsRecord &&
      other.value == value &&
      other.accuracy == accuracy;
}

/// A device being managed by UPower.
class UPowerDevice {
  final DBusRemoteObject _object;

  final _properties = <String, DBusValue>{};
  StreamSubscription? _propertiesChangedSubscription;
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
      : _object = DBusRemoteObject(systemBus, 'org.freedesktop.UPower', path);

  /// Connects to the UPower daemon.
  Future<void> _connect() async {
    _propertiesChangedSubscription = _object.propertiesChanged.listen((signal) {
      if (signal.propertiesInterface == 'org.freedesktop.UPower.Device') {
        _updateProperties(signal.changedProperties);
      }
    });
    _updateProperties(
        await _object.getAllProperties('org.freedesktop.UPower.Device'));
  }

  void _updateProperties(Map<String, DBusValue> properties) {
    _properties.addAll(properties);
    _propertiesChangedController.add(properties.keys.toList());
  }

  Future<void> _close() async {
    if (_propertiesChangedSubscription != null) {
      await _propertiesChangedSubscription!.cancel();
      _propertiesChangedSubscription = null;
    }
  }

  /// Refreshes properties of this device.
  Future<void> refresh() async {
    await _object.callMethod('org.freedesktop.UPower.Device', 'Refresh', [],
        replySignature: DBusSignature(''));
  }

  /// Gets history of [type] ('rate' or 'charge').
  Future<List<UPowerDeviceHistoryRecord>> getHistory(
      String type, int resolution,
      {int timespan = 0}) async {
    var result = await _object.callMethod(
        'org.freedesktop.UPower.Device',
        'GetHistory',
        [DBusString(type), DBusUint32(timespan), DBusUint32(resolution)],
        replySignature: DBusSignature('a(udu)'));
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
    var result = await _object.callMethod(
        'org.freedesktop.UPower.Device', 'GetStatistics', [DBusString(type)],
        replySignature: DBusSignature('a(dd)'));
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
  String toString() => 'UpowerDevice(type: $type)';
}

/// A source of changes to keyboard backlight brightness.
/// [external] if triggered by calling the D-Bus API.
/// [internal] if triggered by the hardware.
enum UPowerKbdBacklightChangeSource { external, internal }

/// Contains updates on keyboard backlight.
class UPowerKbdBacklightChange {
  /// The current keyboard backlight brightness.
  final int brightness;

  /// The source of the change.
  final UPowerKbdBacklightChangeSource source;

  const UPowerKbdBacklightChange(this.brightness, this.source);
}

/// Keyboard backlight settings
class UPowerKbdBacklight {
  final DBusRemoteObject _object;

  late final DBusRemoteObjectSignalStream _brightnessChanged;
  late final DBusRemoteObjectSignalStream _brightnessChangedWithSource;

  Stream<int> get brightnessChanged =>
      _brightnessChanged.map((signal) => (signal.values[0] as DBusInt32).value);

  Stream<UPowerKbdBacklightChange> get brightnessChangedWithSource =>
      _brightnessChangedWithSource.map((signal) => UPowerKbdBacklightChange(
          (signal.values[0] as DBusInt32).value,
          {
            'external': UPowerKbdBacklightChangeSource.external,
            'internal': UPowerKbdBacklightChangeSource.internal
          }[(signal.values[1] as DBusString).value]!));

  UPowerKbdBacklight(DBusClient bus)
      : _object = DBusRemoteObject(bus, 'org.freedesktop.UPower',
            DBusObjectPath('/org/freedesktop/UPower/KbdBacklight')) {
    _brightnessChanged = DBusRemoteObjectSignalStream(
        _object, 'org.freedesktop.UPower.KbdBacklight', 'BrightnessChanged');
    _brightnessChangedWithSource = DBusRemoteObjectSignalStream(_object,
        'org.freedesktop.UPower.KbdBacklight', 'BrightnessChangedWithSource');
  }

  /// Get the current keyboard backlight brightness level.
  Future<int> getBrightness() async {
    var result = await _object.callMethod(
        'org.freedesktop.UPower.KbdBacklight', 'GetBrightness', [],
        replySignature: DBusSignature('i'));
    return (result.returnValues[0] as DBusInt32).value;
  }

  /// Get the maximum keyboard backlight brightness level.
  Future<int> getMaxBrightness() async {
    var result = await _object.callMethod(
        'org.freedesktop.UPower.KbdBacklight', 'GetMaxBrightness', [],
        replySignature: DBusSignature('i'));
    return (result.returnValues[0] as DBusInt32).value;
  }

  /// Set the keyboard backlight brightness level.
  /// The value is between 0 (off) and the value returned in [getMaxBrightness].
  Future<void> setBrightness(int brightness) async {
    await _object.callMethod('org.freedesktop.UPower.KbdBacklight',
        'SetBrightness', [DBusInt32(brightness)],
        replySignature: DBusSignature(''));
  }
}

/// A client that connects to UPower.
class UPowerClient {
  /// The bus this client is connected to.
  final DBusClient _bus;
  final bool _closeBus;

  /// The root D-Bus UPower object.
  late final DBusRemoteObject _root;

  /// The D-Bus UPower object for display.
  late final UPowerDevice _displayDevice;

  /// The D-Bus UPower object for keyboard backlight.
  late final UPowerKbdBacklight kbdBacklight;

  /// Caches property values.
  final _properties = <String, DBusValue>{};
  StreamSubscription? _propertiesChangedSubscription;
  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();

  /// Devices.
  final _devices = <DBusObjectPath, UPowerDevice>{};
  StreamSubscription? _deviceAddedSubscription;
  final _deviceAddedController = StreamController<UPowerDevice>.broadcast();
  StreamSubscription? _deviceRemovedSubscription;
  final _deviceRemovedController = StreamController<UPowerDevice>.broadcast();

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
  List<UPowerDevice> get devices => _devices.values.toList();

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
  UPowerClient({DBusClient? bus})
      : _bus = bus ?? DBusClient.system(),
        _closeBus = bus == null {
    _root = DBusRemoteObject(_bus, 'org.freedesktop.UPower',
        DBusObjectPath('/org/freedesktop/UPower'));
    _displayDevice = UPowerDevice(
        _bus, DBusObjectPath('/org/freedesktop/UPower/devices/DisplayDevice'));
    kbdBacklight = UPowerKbdBacklight(_bus);
  }

  /// Connects to the UPower daemon.
  Future<void> connect() async {
    _propertiesChangedSubscription = _root.propertiesChanged.listen((signal) {
      if (signal.propertiesInterface == 'org.freedesktop.UPower') {
        _updateProperties(signal.changedProperties);
      }
    });
    _updateProperties(await _root.getAllProperties('org.freedesktop.UPower'));

    var deviceAdded = DBusRemoteObjectSignalStream(
        _root, 'org.freedesktop.UPower', 'DeviceAdded');
    _deviceAddedSubscription = deviceAdded
        .listen((signal) => _deviceAdded((signal.values[0] as DBusObjectPath)));
    var deviceRemoved = DBusRemoteObjectSignalStream(
        _root, 'org.freedesktop.UPower', 'DeviceRemoved');
    _deviceRemovedSubscription = deviceRemoved.listen(
        (signal) => _deviceRemoved((signal.values[0] as DBusObjectPath)));

    var devicePaths = await _enumerateDevices();
    for (var path in devicePaths) {
      await _deviceAdded(path);
    }

    await _displayDevice._connect();
  }

  /// Gets the action the system will take when the power supply is critical.
  Future<String> getCriticalAction() async {
    var result = await _root.callMethod(
        'org.freedesktop.UPower', 'GetCriticalAction', [],
        replySignature: DBusSignature('s'));
    return (result.returnValues[0] as DBusString).value;
  }

  /// Terminates the connection to the UPower daemon. If a client remains unclosed, the Dart process may not terminate.
  Future<void> close() async {
    await _displayDevice._close();
    for (var device in devices) {
      await device._close();
    }
    if (_propertiesChangedSubscription != null) {
      await _propertiesChangedSubscription!.cancel();
      _propertiesChangedSubscription = null;
    }
    if (_deviceAddedSubscription != null) {
      await _deviceAddedSubscription!.cancel();
      _deviceAddedSubscription = null;
    }
    if (_deviceRemovedSubscription != null) {
      await _deviceRemovedSubscription!.cancel();
      _deviceRemovedSubscription = null;
    }
    if (_closeBus) {
      await _bus.close();
    }
  }

  void _updateProperties(Map<String, DBusValue> properties) {
    _properties.addAll(properties);
    _propertiesChangedController.add(properties.keys.toList());
  }

  Future<List<DBusObjectPath>> _enumerateDevices() async {
    var result = await _root.callMethod(
        'org.freedesktop.UPower', 'EnumerateDevices', [],
        replySignature: DBusSignature('ao'));
    return (result.returnValues[0] as DBusArray)
        .children
        .map((child) => child as DBusObjectPath)
        .toList();
  }

  Future<void> _deviceAdded(DBusObjectPath path) async {
    var device = UPowerDevice(_bus, path);
    await device._connect();
    _devices[path] = device;
    _deviceAddedController.add(device);
  }

  void _deviceRemoved(DBusObjectPath path) {
    var device = _devices[path];
    if (device == null) {
      return;
    }
    _devices.remove(path);
    _deviceRemovedController.add(device);
  }
}
