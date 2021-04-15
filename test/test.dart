import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:test/test.dart';
import 'package:upower/upower.dart';

class MockUPowerObject extends DBusObject {
  final MockUPowerServer server;

  MockUPowerObject(this.server)
      : super(DBusObjectPath('/org/freedesktop/UPower'));

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    var properties = <String, DBusValue>{};
    if (interface == 'org.freedesktop.UPower') {
      properties['LidIsClosed'] = DBusBoolean(server.lidIsClosed);
      properties['LidIsPresent'] = DBusBoolean(server.lidIsPresent);
      properties['OnBattery'] = DBusBoolean(server.onBattery);
      properties['DaemonVersion'] = DBusString(server.daemonVersion);
    }
    return DBusGetAllPropertiesResponse(properties);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.UPower') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'EnumerateDevices':
        return DBusMethodSuccessResponse([
          DBusArray(
              DBusSignature('o'), server.devices.map((device) => device.path))
        ]);
      case 'GetCriticalAction':
        return DBusMethodSuccessResponse([DBusString(server.criticalAction)]);
      case 'GetDisplayDevice':
        return DBusMethodSuccessResponse(
            [DBusObjectPath('/org/freedesktop/UPower/devices/DisplayDevice')]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class HistoryEntry {
  final int time;
  final double value;
  final int state;
  final int resolution;

  const HistoryEntry(this.time, this.value, this.state, this.resolution);
}

class StatEntry {
  final double value;
  final double accuracy;

  const StatEntry(this.value, this.accuracy);
}

class MockUPowerDevice extends DBusObject {
  final int batteryLevel;
  final double capacity;
  final double energy;
  final double energyEmpty;
  final double energyFull;
  final double energyFullDesign;
  final double energyRate;
  final bool hasHistory;
  final bool hasStatistics;
  final String iconName;
  final bool isPresent;
  final bool isRechargeable;
  final double luminosity;
  final String model;
  final String nativePath;
  final bool online;
  final double percentage;
  final bool powerSupply;
  final String serial;
  final int state;
  final int technology;
  final double temperature;
  final int timeToEmpty;
  final int timeToFull;
  final int type;
  final int updateTime;
  final String vendor;
  final double voltage;
  final int warningLevel;

  final Map<String, List<HistoryEntry>> history;
  final Map<String, List<StatEntry>> statistics;

  var refreshed = false;

  MockUPowerDevice(String name,
      {this.batteryLevel = 0,
      this.capacity = 0,
      this.energy = 0,
      this.energyEmpty = 0,
      this.energyFull = 0,
      this.energyFullDesign = 0,
      this.energyRate = 0,
      this.hasHistory = false,
      this.hasStatistics = false,
      this.iconName = '',
      this.isPresent = false,
      this.isRechargeable = false,
      this.luminosity = 0,
      this.model = '',
      this.nativePath = '',
      this.online = false,
      this.percentage = 0,
      this.powerSupply = false,
      this.serial = '',
      this.state = 0,
      this.technology = 0,
      this.temperature = 0,
      this.timeToEmpty = 0,
      this.timeToFull = 0,
      this.type = 0,
      this.updateTime = 0,
      this.vendor = '',
      this.voltage = 0,
      this.warningLevel = 0,
      this.history = const {},
      this.statistics = const {}})
      : super(DBusObjectPath('/org/freedesktop/UPower/devices/$name'));

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    var properties = <String, DBusValue>{};
    if (interface == 'org.freedesktop.UPower.Device') {
      properties['BatteryLevel'] = DBusUint32(batteryLevel);
      properties['Capacity'] = DBusDouble(capacity);
      properties['Energy'] = DBusDouble(energy);
      properties['EnergyEmpty'] = DBusDouble(energyEmpty);
      properties['EnergyFull'] = DBusDouble(energyFull);
      properties['EnergyFullDesign'] = DBusDouble(energyFullDesign);
      properties['EnergyRate'] = DBusDouble(energyRate);
      properties['HasHistory'] = DBusBoolean(hasHistory);
      properties['HasStatistics'] = DBusBoolean(hasStatistics);
      properties['IconName'] = DBusString(iconName);
      properties['IsPresent'] = DBusBoolean(isPresent);
      properties['IsRechargeable'] = DBusBoolean(isRechargeable);
      properties['Luminosity'] = DBusDouble(luminosity);
      properties['Model'] = DBusString(model);
      properties['NativePath'] = DBusString(nativePath);
      properties['Online'] = DBusBoolean(online);
      properties['Percentage'] = DBusDouble(percentage);
      properties['PowerSupply'] = DBusBoolean(powerSupply);
      properties['Serial'] = DBusString(serial);
      properties['State'] = DBusUint32(state);
      properties['Technology'] = DBusUint32(technology);
      properties['Temperature'] = DBusDouble(temperature);
      properties['TimeToEmpty'] = DBusInt64(timeToEmpty);
      properties['TimeToFull'] = DBusInt64(timeToFull);
      properties['Type'] = DBusUint32(type);
      properties['UpdateTime'] = DBusUint64(updateTime);
      properties['Vendor'] = DBusString(vendor);
      properties['Voltage'] = DBusDouble(voltage);
      properties['WarningLevel'] = DBusUint32(warningLevel);
    }
    return DBusGetAllPropertiesResponse(properties);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.freedesktop.UPower.Device') {
      return DBusMethodErrorResponse.unknownInterface();
    }

    switch (methodCall.name) {
      case 'GetHistory':
        var type = (methodCall.values[0] as DBusString).value;
        var timespan = (methodCall.values[1] as DBusUint32).value;
        var resolution = (methodCall.values[2] as DBusUint32).value;
        var h = history[type] ?? [];
        return DBusMethodSuccessResponse([
          DBusArray(
              DBusSignature('(udu)'),
              h
                  .where((entry) =>
                      entry.time >= timespan && entry.resolution >= resolution)
                  .map((entry) => DBusStruct([
                        DBusUint32(entry.time),
                        DBusDouble(entry.value),
                        DBusUint32(entry.state)
                      ])))
        ]);
      case 'GetStatistics':
        var type = (methodCall.values[0] as DBusString).value;
        var s = statistics[type] ?? [];
        return DBusMethodSuccessResponse([
          DBusArray(
              DBusSignature('(dd)'),
              s.map((entry) => DBusStruct(
                  [DBusDouble(entry.value), DBusDouble(entry.accuracy)])))
        ]);
      case 'Refresh':
        refreshed = true;
        return DBusMethodSuccessResponse([]);
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}

class MockUPowerServer extends DBusClient {
  late final MockUPowerObject _root;
  final devices = <MockUPowerDevice>[];

  final bool lidIsClosed;
  final bool lidIsPresent;
  final bool onBattery;
  final String daemonVersion;
  final String criticalAction;

  MockUPowerServer(DBusAddress clientAddress,
      {this.lidIsClosed = false,
      this.lidIsPresent = false,
      this.onBattery = false,
      this.daemonVersion = '',
      this.criticalAction = ''})
      : super(clientAddress);

  Future<void> start() async {
    await requestName('org.freedesktop.UPower');
    _root = MockUPowerObject(this);
    await registerObject(_root);

    var displayDevice = MockUPowerDevice('DisplayDevice');
    await registerObject(displayDevice);
  }

  Future<MockUPowerDevice> addDevice(String name,
      {int batteryLevel = 0,
      double capacity = 0,
      double energy = 0,
      double energyEmpty = 0,
      double energyFull = 0,
      double energyFullDesign = 0,
      double energyRate = 0,
      bool hasHistory = false,
      bool hasStatistics = false,
      String iconName = '',
      bool isPresent = false,
      bool isRechargeable = false,
      double luminosity = 0,
      String model = '',
      String nativePath = '',
      bool online = false,
      double percentage = 0,
      bool powerSupply = false,
      String serial = '',
      int state = 0,
      int technology = 0,
      double temperature = 0,
      int timeToEmpty = 0,
      int timeToFull = 0,
      int type = 0,
      int updateTime = 0,
      String vendor = '',
      double voltage = 0,
      int warningLevel = 0,
      Map<String, List<HistoryEntry>> history = const {},
      Map<String, List<StatEntry>> statistics = const {}}) async {
    var device = MockUPowerDevice(name,
        batteryLevel: batteryLevel,
        capacity: capacity,
        energy: energy,
        energyEmpty: energyEmpty,
        energyFull: energyFull,
        energyFullDesign: energyFullDesign,
        energyRate: energyRate,
        hasHistory: hasHistory,
        hasStatistics: hasStatistics,
        iconName: iconName,
        isPresent: isPresent,
        isRechargeable: isRechargeable,
        luminosity: luminosity,
        model: model,
        nativePath: nativePath,
        online: online,
        percentage: percentage,
        powerSupply: powerSupply,
        serial: serial,
        state: state,
        technology: technology,
        temperature: temperature,
        timeToEmpty: timeToEmpty,
        timeToFull: timeToFull,
        type: type,
        updateTime: updateTime,
        vendor: vendor,
        voltage: voltage,
        warningLevel: warningLevel,
        history: history,
        statistics: statistics);
    await registerObject(device);
    devices.add(device);
    _root.emitSignal('org.freedesktop.UPower', 'DeviceAdded', [device.path]);
    return device;
  }

  void removeDevice(MockUPowerDevice device) {
    devices.remove(device);
    _root.emitSignal('org.freedesktop.UPower', 'DeviceRemoved', [device.path]);
  }
}

void main() {
  test('daemon version', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress, daemonVersion: '1.2.3');
    await upower.start();

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.daemonVersion, equals('1.2.3'));

    await client.close();
  });

  test('lid is closed', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower =
        MockUPowerServer(clientAddress, lidIsPresent: true, lidIsClosed: true);
    await upower.start();

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.lidIsPresent, isTrue);
    expect(client.lidIsClosed, isTrue);

    await client.close();
  });

  test('on battery', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress, onBattery: true);
    await upower.start();

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.onBattery, isTrue);

    await client.close();
  });

  test('critical action', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress, criticalAction: 'PowerOff');
    await upower.start();

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(await client.getCriticalAction(), equals('PowerOff'));

    await client.close();
  });

  test('no devices', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress);
    await upower.start();

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.devices, isEmpty);

    await client.close();
  });

  test('devices', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress);
    await upower.start();
    await upower.addDevice('battery_BAT0', serial: 'SERIAL1');
    await upower.addDevice('battery_BAT1', serial: 'SERIAL2');
    await upower.addDevice('line_power', serial: 'SERIAL3');

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.devices, hasLength(3));
    expect(client.devices[0].serial, equals('SERIAL1'));
    expect(client.devices[1].serial, equals('SERIAL2'));
    expect(client.devices[2].serial, equals('SERIAL3'));

    await client.close();
  });

  test('device added', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress);
    await upower.start();

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    client.deviceAdded.listen(expectAsync1((device) {
      expect(device.serial, equals('SERIAL'));
    }));

    await upower.addDevice('battery_BAT0', serial: 'SERIAL');
  });

  test('device removed', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress);
    await upower.start();
    var d = await upower.addDevice('battery_BAT0', serial: 'SERIAL');

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    client.deviceRemoved.listen(expectAsync1((device) {
      expect(device.serial, equals('SERIAL'));
    }));

    upower.removeDevice(d);
  });

  test('device properties', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress);
    await upower.start();
    await upower.addDevice('battery_BAT0',
        batteryLevel: 5,
        capacity: 90,
        energy: 31.5,
        energyFull: 42,
        energyFullDesign: 45,
        energyRate: 2.4,
        hasHistory: true,
        hasStatistics: true,
        iconName: 'battery-good-symbolic',
        isPresent: true,
        isRechargeable: true,
        luminosity: 123,
        model: 'MODEL',
        nativePath: 'BAT0',
        online: true,
        percentage: 75,
        powerSupply: true,
        serial: 'SERIAL',
        state: 2,
        technology: 2,
        temperature: 21,
        timeToEmpty: 240,
        timeToFull: 5,
        type: 2,
        updateTime: 123456789,
        vendor: 'VENDOR',
        voltage: 12.2,
        warningLevel: 2);

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.devices, hasLength(1));
    var device = client.devices[0];
    expect(device.batteryLevel, equals(UPowerDeviceBatteryLevel.high));
    expect(device.capacity, equals(90));
    expect(device.energy, equals(31.5));
    expect(device.energyFull, equals(42));
    expect(device.energyFullDesign, equals(45));
    expect(device.energyRate, equals(2.4));
    expect(device.hasHistory, isTrue);
    expect(device.hasStatistics, isTrue);
    expect(device.iconName, equals('battery-good-symbolic'));
    expect(device.isPresent, isTrue);
    expect(device.isRechargeable, isTrue);
    expect(device.luminosity, equals(123));
    expect(device.model, equals('MODEL'));
    expect(device.nativePath, equals('BAT0'));
    expect(device.online, isTrue);
    expect(device.percentage, equals(75));
    expect(device.powerSupply, isTrue);
    expect(device.serial, equals('SERIAL'));
    expect(device.state, equals(UPowerDeviceState.discharging));
    expect(device.technology, equals(UPowerDeviceTechnology.lithiumPolymer));
    expect(device.temperature, equals(21));
    expect(device.timeToEmpty, equals(240));
    expect(device.timeToFull, equals(5));
    expect(device.type, equals(UPowerDeviceType.battery));
    expect(device.updateTime, equals(123456789));
    expect(device.vendor, equals('VENDOR'));
    expect(device.voltage, equals(12.2));
    expect(device.warningLevel, equals(UPowerDeviceWarningLevel.discharging));

    await client.close();
  });

  test('device history', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress);
    await upower.start();
    await upower.addDevice('battery_BAT0', history: {
      'charge': [
        HistoryEntry(0, 0, 0, 20), // Will be filtered out due to timespan.
        HistoryEntry(1, 50, 1, 20),
        HistoryEntry(2, 75, 1, 10), // Will be filtered out due to resolution.
        HistoryEntry(3, 100, 4, 20),
        HistoryEntry(4, 80, 2, 20),
        HistoryEntry(5, 40, 2, 10), // Will be filtered out due to resolution.
        HistoryEntry(6, 0, 3, 20)
      ]
    });

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.devices, hasLength(1));
    var device = client.devices[0];
    expect(
        await device.getHistory('charge', 20, timespan: 1),
        equals([
          UPowerDeviceHistoryRecord(1, 50, UPowerDeviceState.charging),
          UPowerDeviceHistoryRecord(3, 100, UPowerDeviceState.fullyCharged),
          UPowerDeviceHistoryRecord(4, 80, UPowerDeviceState.discharging),
          UPowerDeviceHistoryRecord(6, 0, UPowerDeviceState.empty)
        ]));

    await client.close();
  });

  test('device statistics', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress);
    await upower.start();
    await upower.addDevice('battery_BAT0', statistics: {
      'charging': [StatEntry(1, 0.1), StatEntry(2, 0.1), StatEntry(3, 0.1)]
    });

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.devices, hasLength(1));
    var device = client.devices[0];
    expect(
        await device.getStatistics('charging'),
        equals([
          UPowerDeviceStatisticsRecord(1.0, 0.1),
          UPowerDeviceStatisticsRecord(2.0, 0.1),
          UPowerDeviceStatisticsRecord(3.0, 0.1)
        ]));

    await client.close();
  });

  test('refresh', () async {
    var server = DBusServer();
    var clientAddress =
        await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));

    var upower = MockUPowerServer(clientAddress);
    await upower.start();
    var d = await upower.addDevice('battery_BAT0');

    var client = UPowerClient(bus: DBusClient(clientAddress));
    await client.connect();

    expect(client.devices, hasLength(1));
    var device = client.devices[0];
    expect(d.refreshed, isFalse);
    await device.refresh();
    expect(d.refreshed, isTrue);

    await client.close();
  });
}
