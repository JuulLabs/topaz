import Foundation

class BluetoothUuid {

    private enum bluetoothServices: Int {
        case alert_notification = 0x1811
        case automation_io = 0x1815
        case battery_service = 0x180F
        case blood_pressure = 0x1810
        case body_composition = 0x181B
        case bond_management = 0x181E
        case continuous_glucose_monitoring = 0x181F
        case current_time = 0x1805
        case cycling_power = 0x1818
        case cycling_speed_and_cadence = 0x1816
        case device_information = 0x180A
        case environmental_sensing = 0x181A
        case generic_access = 0x1800
        case generic_attribute = 0x1801
        case glucose = 0x1808
        case health_thermometer = 0x1809
        case heart_rate = 0x180D
        case human_interface_device = 0x1812
        case immediate_alert = 0x1802
        case indoor_positioning = 0x1821
        case internet_protocol_support = 0x1820
        case link_loss = 0x1803
        case location_and_navigation = 0x1819
        case next_dst_change = 0x1807
        case phone_alert_status = 0x180E
        case pulse_oximeter = 0x1822
        case reference_time_update = 0x1806
        case running_speed_and_cadence = 0x1814
        case scan_parameters = 0x1813
        case tx_power = 0x1804
        case user_data = 0x181C
        case weight_scale = 0x181D
    }

    func canonicalUuid(alias: Int) -> UUID {
        canonicalUuid(alias: String(alias, radix: 16))
    }

    func canonicalUuid(alias: String) -> UUID {
        var alias = alias.lowercased()
        if (alias.count <= 8) {
            let lowField = alias.padding(toLength: 8, withPad: "0", startingAt: 0)
            alias = "\(lowField)-0000-1000-8000-00805f9b34fb"
        }
        if (alias.count == 32) {
            let pattern = "/^([0-9a-f]{8})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{12})$/"
            let regex = try! NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: alias, range: NSRange(alias.startIndex..., in: alias))
            matches.dropFirst().enumerated().map({ (index, value) in
                let range = Range(value.range(at: index + 1), in: alias)!
                String(alias[range])
            })
        }
    }

    func canonicalUUID = (alias: string | number): string => {
        if (typeof alias === 'number') alias = alias.toString(16);
        alias = alias.toLowerCase();
        if (alias.length <= 8) alias = ('00000000' + alias).slice(-8) + '-0000-1000-8000-00805f9b34fb';
        if (alias.length === 32) alias = alias.match(/^([0-9a-f]{8})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{12})$/).splice(1).join('-');
        return alias;
    };
}