const transformToDOMException = (error) => {
    try {
        const decoded = JSON.parse(error.message);
        return new DOMException(decoded.msg, decoded.name);
    }
    catch (e) {
        return new TypeError(`${e} when decoding "${error}"`);
    }
};
const rethrowAsDOMException = (error) => {
    throw transformToDOMException(error);
};

const bluetoothRequest = function (action, data) {
    return window.webkit.messageHandlers.bluetooth.postMessage({
        action: action,
        data: data
    }).catch(rethrowAsDOMException);
};
const appLog = function (msg) {
    return window.webkit.messageHandlers.logging.postMessage(msg).catch(rethrowAsDOMException);
};

const uint8ArrayToBase64 = (uint8array) => {
    return btoa(String.fromCharCode(...uint8array));
};
const base64ToUint8Array = (base64) => {
    return Uint8Array.from(atob(base64), (m) => m.codePointAt(0));
};
const arrayBufferToBase64 = (buffer) => {
    return uint8ArrayToBase64(new Uint8Array(buffer));
};
const base64ToDataView = (base64) => {
    return new DataView(base64ToUint8Array(base64).buffer);
};
function copyOf(data) {
    return new DataView(data.buffer.slice(0));
}

class BluetoothRemoteGATTDescriptor {
    constructor(characteristic, uuid) {
        this.characteristic = characteristic;
        this.uuid = uuid;
        this.readValue = async () => {
            const response = await bluetoothRequest('readDescriptor', {
                device: this.characteristic.service.device.id,
                service: this.characteristic.service.uuid,
                characteristic: this.characteristic.uuid,
                instance: this.characteristic.instance,
                descriptor: this.uuid
            });
            this.value = base64ToDataView(response);
            return copyOf(this.value);
        };
        this.value = null;
    }
}

var bluetoothServices;
(function (bluetoothServices) {
    bluetoothServices[bluetoothServices["alert_notification"] = 6161] = "alert_notification";
    bluetoothServices[bluetoothServices["automation_io"] = 6165] = "automation_io";
    bluetoothServices[bluetoothServices["battery_service"] = 6159] = "battery_service";
    bluetoothServices[bluetoothServices["blood_pressure"] = 6160] = "blood_pressure";
    bluetoothServices[bluetoothServices["body_composition"] = 6171] = "body_composition";
    bluetoothServices[bluetoothServices["bond_management"] = 6174] = "bond_management";
    bluetoothServices[bluetoothServices["continuous_glucose_monitoring"] = 6175] = "continuous_glucose_monitoring";
    bluetoothServices[bluetoothServices["current_time"] = 6149] = "current_time";
    bluetoothServices[bluetoothServices["cycling_power"] = 6168] = "cycling_power";
    bluetoothServices[bluetoothServices["cycling_speed_and_cadence"] = 6166] = "cycling_speed_and_cadence";
    bluetoothServices[bluetoothServices["device_information"] = 6154] = "device_information";
    bluetoothServices[bluetoothServices["environmental_sensing"] = 6170] = "environmental_sensing";
    bluetoothServices[bluetoothServices["fitness_machine"] = 6182] = "fitness_machine";
    bluetoothServices[bluetoothServices["generic_access"] = 6144] = "generic_access";
    bluetoothServices[bluetoothServices["generic_attribute"] = 6145] = "generic_attribute";
    bluetoothServices[bluetoothServices["glucose"] = 6152] = "glucose";
    bluetoothServices[bluetoothServices["health_thermometer"] = 6153] = "health_thermometer";
    bluetoothServices[bluetoothServices["heart_rate"] = 6157] = "heart_rate";
    bluetoothServices[bluetoothServices["http_proxy"] = 6179] = "http_proxy";
    bluetoothServices[bluetoothServices["human_interface_device"] = 6162] = "human_interface_device";
    bluetoothServices[bluetoothServices["immediate_alert"] = 6146] = "immediate_alert";
    bluetoothServices[bluetoothServices["indoor_positioning"] = 6177] = "indoor_positioning";
    bluetoothServices[bluetoothServices["internet_protocol_support"] = 6176] = "internet_protocol_support";
    bluetoothServices[bluetoothServices["link_loss"] = 6147] = "link_loss";
    bluetoothServices[bluetoothServices["location_and_navigation"] = 6169] = "location_and_navigation";
    bluetoothServices[bluetoothServices["mesh_provisioning"] = 6183] = "mesh_provisioning";
    bluetoothServices[bluetoothServices["mesh_proxy"] = 6184] = "mesh_proxy";
    bluetoothServices[bluetoothServices["next_dst_change"] = 6151] = "next_dst_change";
    bluetoothServices[bluetoothServices["object_transfer"] = 6181] = "object_transfer";
    bluetoothServices[bluetoothServices["phone_alert_status"] = 6158] = "phone_alert_status";
    bluetoothServices[bluetoothServices["pulse_oximeter"] = 6178] = "pulse_oximeter";
    bluetoothServices[bluetoothServices["reconnection_configuration"] = 6185] = "reconnection_configuration";
    bluetoothServices[bluetoothServices["reference_time_update"] = 6150] = "reference_time_update";
    bluetoothServices[bluetoothServices["running_speed_and_cadence"] = 6164] = "running_speed_and_cadence";
    bluetoothServices[bluetoothServices["scan_parameters"] = 6163] = "scan_parameters";
    bluetoothServices[bluetoothServices["transport_discovery"] = 6180] = "transport_discovery";
    bluetoothServices[bluetoothServices["tx_power"] = 6148] = "tx_power";
    bluetoothServices[bluetoothServices["user_data"] = 6172] = "user_data";
    bluetoothServices[bluetoothServices["weight_scale"] = 6173] = "weight_scale";
})(bluetoothServices || (bluetoothServices = {}));
var bluetoothCharacteristics;
(function (bluetoothCharacteristics) {
    bluetoothCharacteristics[bluetoothCharacteristics["aerobic_heart_rate_lower_limit"] = 10878] = "aerobic_heart_rate_lower_limit";
    bluetoothCharacteristics[bluetoothCharacteristics["aerobic_heart_rate_upper_limit"] = 10884] = "aerobic_heart_rate_upper_limit";
    bluetoothCharacteristics[bluetoothCharacteristics["aerobic_threshold"] = 10879] = "aerobic_threshold";
    bluetoothCharacteristics[bluetoothCharacteristics["age"] = 10880] = "age";
    bluetoothCharacteristics[bluetoothCharacteristics["aggregate"] = 10842] = "aggregate";
    bluetoothCharacteristics[bluetoothCharacteristics["alert_category_id"] = 10819] = "alert_category_id";
    bluetoothCharacteristics[bluetoothCharacteristics["alert_category_id_bit_mask"] = 10818] = "alert_category_id_bit_mask";
    bluetoothCharacteristics[bluetoothCharacteristics["alert_level"] = 10758] = "alert_level";
    bluetoothCharacteristics[bluetoothCharacteristics["alert_notification_control_point"] = 10820] = "alert_notification_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["alert_status"] = 10815] = "alert_status";
    bluetoothCharacteristics[bluetoothCharacteristics["altitude"] = 10931] = "altitude";
    bluetoothCharacteristics[bluetoothCharacteristics["anaerobic_heart_rate_lower_limit"] = 10881] = "anaerobic_heart_rate_lower_limit";
    bluetoothCharacteristics[bluetoothCharacteristics["anaerobic_heart_rate_upper_limit"] = 10882] = "anaerobic_heart_rate_upper_limit";
    bluetoothCharacteristics[bluetoothCharacteristics["anaerobic_threshold"] = 10883] = "anaerobic_threshold";
    bluetoothCharacteristics[bluetoothCharacteristics["analog"] = 10840] = "analog";
    bluetoothCharacteristics[bluetoothCharacteristics["analog_output"] = 10841] = "analog_output";
    bluetoothCharacteristics[bluetoothCharacteristics["apparent_wind_direction"] = 10867] = "apparent_wind_direction";
    bluetoothCharacteristics[bluetoothCharacteristics["apparent_wind_speed"] = 10866] = "apparent_wind_speed";
    bluetoothCharacteristics[bluetoothCharacteristics["barometric_pressure_trend"] = 10915] = "barometric_pressure_trend";
    bluetoothCharacteristics[bluetoothCharacteristics["battery_level"] = 10777] = "battery_level";
    bluetoothCharacteristics[bluetoothCharacteristics["battery_level_state"] = 10779] = "battery_level_state";
    bluetoothCharacteristics[bluetoothCharacteristics["battery_power_state"] = 10778] = "battery_power_state";
    bluetoothCharacteristics[bluetoothCharacteristics["blood_pressure_feature"] = 10825] = "blood_pressure_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["blood_pressure_measurement"] = 10805] = "blood_pressure_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["body_composition_feature"] = 10907] = "body_composition_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["body_composition_measurement"] = 10908] = "body_composition_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["body_sensor_location"] = 10808] = "body_sensor_location";
    bluetoothCharacteristics[bluetoothCharacteristics["bond_management_control_point"] = 10916] = "bond_management_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["bond_management_feature"] = 10917] = "bond_management_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["boot_keyboard_input_report"] = 10786] = "boot_keyboard_input_report";
    bluetoothCharacteristics[bluetoothCharacteristics["boot_keyboard_output_report"] = 10802] = "boot_keyboard_output_report";
    bluetoothCharacteristics[bluetoothCharacteristics["boot_mouse_input_report"] = 10803] = "boot_mouse_input_report";
    bluetoothCharacteristics[bluetoothCharacteristics["cgm_feature"] = 10920] = "cgm_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["cgm_measurement"] = 10919] = "cgm_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["cgm_session_run_time"] = 10923] = "cgm_session_run_time";
    bluetoothCharacteristics[bluetoothCharacteristics["cgm_session_start_time"] = 10922] = "cgm_session_start_time";
    bluetoothCharacteristics[bluetoothCharacteristics["cgm_specific_ops_control_point"] = 10924] = "cgm_specific_ops_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["cgm_status"] = 10921] = "cgm_status";
    bluetoothCharacteristics[bluetoothCharacteristics["cross_trainer_data"] = 10958] = "cross_trainer_data";
    bluetoothCharacteristics[bluetoothCharacteristics["csc_feature"] = 10844] = "csc_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["csc_measurement"] = 10843] = "csc_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["current_time"] = 10795] = "current_time";
    bluetoothCharacteristics[bluetoothCharacteristics["cycling_power_control_point"] = 10854] = "cycling_power_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["cycling_power_feature"] = 10853] = "cycling_power_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["cycling_power_measurement"] = 10851] = "cycling_power_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["cycling_power_vector"] = 10852] = "cycling_power_vector";
    bluetoothCharacteristics[bluetoothCharacteristics["database_change_increment"] = 10905] = "database_change_increment";
    bluetoothCharacteristics[bluetoothCharacteristics["date_of_birth"] = 10885] = "date_of_birth";
    bluetoothCharacteristics[bluetoothCharacteristics["date_of_threshold_assessment"] = 10886] = "date_of_threshold_assessment";
    bluetoothCharacteristics[bluetoothCharacteristics["date_time"] = 10760] = "date_time";
    bluetoothCharacteristics[bluetoothCharacteristics["date_utc"] = 10989] = "date_utc";
    bluetoothCharacteristics[bluetoothCharacteristics["day_date_time"] = 10762] = "day_date_time";
    bluetoothCharacteristics[bluetoothCharacteristics["day_of_week"] = 10761] = "day_of_week";
    bluetoothCharacteristics[bluetoothCharacteristics["descriptor_value_changed"] = 10877] = "descriptor_value_changed";
    bluetoothCharacteristics[bluetoothCharacteristics["dew_point"] = 10875] = "dew_point";
    bluetoothCharacteristics[bluetoothCharacteristics["digital"] = 10838] = "digital";
    bluetoothCharacteristics[bluetoothCharacteristics["digital_output"] = 10839] = "digital_output";
    bluetoothCharacteristics[bluetoothCharacteristics["dst_offset"] = 10765] = "dst_offset";
    bluetoothCharacteristics[bluetoothCharacteristics["elevation"] = 10860] = "elevation";
    bluetoothCharacteristics[bluetoothCharacteristics["email_address"] = 10887] = "email_address";
    bluetoothCharacteristics[bluetoothCharacteristics["exact_time_100"] = 10763] = "exact_time_100";
    bluetoothCharacteristics[bluetoothCharacteristics["exact_time_256"] = 10764] = "exact_time_256";
    bluetoothCharacteristics[bluetoothCharacteristics["fat_burn_heart_rate_lower_limit"] = 10888] = "fat_burn_heart_rate_lower_limit";
    bluetoothCharacteristics[bluetoothCharacteristics["fat_burn_heart_rate_upper_limit"] = 10889] = "fat_burn_heart_rate_upper_limit";
    bluetoothCharacteristics[bluetoothCharacteristics["firmware_revision_string"] = 10790] = "firmware_revision_string";
    bluetoothCharacteristics[bluetoothCharacteristics["first_name"] = 10890] = "first_name";
    bluetoothCharacteristics[bluetoothCharacteristics["fitness_machine_control_point"] = 10969] = "fitness_machine_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["fitness_machine_feature"] = 10956] = "fitness_machine_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["fitness_machine_status"] = 10970] = "fitness_machine_status";
    bluetoothCharacteristics[bluetoothCharacteristics["five_zone_heart_rate_limits"] = 10891] = "five_zone_heart_rate_limits";
    bluetoothCharacteristics[bluetoothCharacteristics["floor_number"] = 10930] = "floor_number";
    bluetoothCharacteristics[bluetoothCharacteristics["gap.appearance"] = 10753] = "gap.appearance";
    bluetoothCharacteristics[bluetoothCharacteristics["gap.central_address_resolution_support"] = 10918] = "gap.central_address_resolution_support";
    bluetoothCharacteristics[bluetoothCharacteristics["gap.device_name"] = 10752] = "gap.device_name";
    bluetoothCharacteristics[bluetoothCharacteristics["gap.peripheral_preferred_connection_parameters"] = 10756] = "gap.peripheral_preferred_connection_parameters";
    bluetoothCharacteristics[bluetoothCharacteristics["gap.peripheral_privacy_flag"] = 10754] = "gap.peripheral_privacy_flag";
    bluetoothCharacteristics[bluetoothCharacteristics["gap.reconnection_address"] = 10755] = "gap.reconnection_address";
    bluetoothCharacteristics[bluetoothCharacteristics["gatt.service_changed"] = 10757] = "gatt.service_changed";
    bluetoothCharacteristics[bluetoothCharacteristics["gender"] = 10892] = "gender";
    bluetoothCharacteristics[bluetoothCharacteristics["glucose_feature"] = 10833] = "glucose_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["glucose_measurement"] = 10776] = "glucose_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["glucose_measurement_context"] = 10804] = "glucose_measurement_context";
    bluetoothCharacteristics[bluetoothCharacteristics["gust_factor"] = 10868] = "gust_factor";
    bluetoothCharacteristics[bluetoothCharacteristics["hardware_revision_string"] = 10791] = "hardware_revision_string";
    bluetoothCharacteristics[bluetoothCharacteristics["heart_rate_control_point"] = 10809] = "heart_rate_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["heart_rate_max"] = 10893] = "heart_rate_max";
    bluetoothCharacteristics[bluetoothCharacteristics["heart_rate_measurement"] = 10807] = "heart_rate_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["heat_index"] = 10874] = "heat_index";
    bluetoothCharacteristics[bluetoothCharacteristics["height"] = 10894] = "height";
    bluetoothCharacteristics[bluetoothCharacteristics["hid_control_point"] = 10828] = "hid_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["hid_information"] = 10826] = "hid_information";
    bluetoothCharacteristics[bluetoothCharacteristics["hip_circumference"] = 10895] = "hip_circumference";
    bluetoothCharacteristics[bluetoothCharacteristics["http_control_point"] = 10938] = "http_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["http_entity_body"] = 10937] = "http_entity_body";
    bluetoothCharacteristics[bluetoothCharacteristics["http_headers"] = 10935] = "http_headers";
    bluetoothCharacteristics[bluetoothCharacteristics["http_status_code"] = 10936] = "http_status_code";
    bluetoothCharacteristics[bluetoothCharacteristics["https_security"] = 10939] = "https_security";
    bluetoothCharacteristics[bluetoothCharacteristics["humidity"] = 10863] = "humidity";
    bluetoothCharacteristics[bluetoothCharacteristics["ieee_11073-20601_regulatory_certification_data_list"] = 10794] = "ieee_11073-20601_regulatory_certification_data_list";
    bluetoothCharacteristics[bluetoothCharacteristics["indoor_bike_data"] = 10962] = "indoor_bike_data";
    bluetoothCharacteristics[bluetoothCharacteristics["indoor_positioning_configuration"] = 10925] = "indoor_positioning_configuration";
    bluetoothCharacteristics[bluetoothCharacteristics["intermediate_blood_pressure"] = 10806] = "intermediate_blood_pressure";
    bluetoothCharacteristics[bluetoothCharacteristics["intermediate_cuff_pressure"] = 10806] = "intermediate_cuff_pressure";
    bluetoothCharacteristics[bluetoothCharacteristics["intermediate_temperature"] = 10782] = "intermediate_temperature";
    bluetoothCharacteristics[bluetoothCharacteristics["irradiance"] = 10871] = "irradiance";
    bluetoothCharacteristics[bluetoothCharacteristics["language"] = 10914] = "language";
    bluetoothCharacteristics[bluetoothCharacteristics["last_name"] = 10896] = "last_name";
    bluetoothCharacteristics[bluetoothCharacteristics["latitude"] = 10926] = "latitude";
    bluetoothCharacteristics[bluetoothCharacteristics["ln_control_point"] = 10859] = "ln_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["ln_feature"] = 10858] = "ln_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["local_east_coordinate.xml"] = 10929] = "local_east_coordinate.xml";
    bluetoothCharacteristics[bluetoothCharacteristics["local_north_coordinate"] = 10928] = "local_north_coordinate";
    bluetoothCharacteristics[bluetoothCharacteristics["local_time_information"] = 10767] = "local_time_information";
    bluetoothCharacteristics[bluetoothCharacteristics["location_and_speed"] = 10855] = "location_and_speed";
    bluetoothCharacteristics[bluetoothCharacteristics["location_name"] = 10933] = "location_name";
    bluetoothCharacteristics[bluetoothCharacteristics["longitude"] = 10927] = "longitude";
    bluetoothCharacteristics[bluetoothCharacteristics["magnetic_declination"] = 10796] = "magnetic_declination";
    bluetoothCharacteristics[bluetoothCharacteristics["magnetic_flux_density_2D"] = 10912] = "magnetic_flux_density_2D";
    bluetoothCharacteristics[bluetoothCharacteristics["magnetic_flux_density_3D"] = 10913] = "magnetic_flux_density_3D";
    bluetoothCharacteristics[bluetoothCharacteristics["manufacturer_name_string"] = 10793] = "manufacturer_name_string";
    bluetoothCharacteristics[bluetoothCharacteristics["maximum_recommended_heart_rate"] = 10897] = "maximum_recommended_heart_rate";
    bluetoothCharacteristics[bluetoothCharacteristics["measurement_interval"] = 10785] = "measurement_interval";
    bluetoothCharacteristics[bluetoothCharacteristics["model_number_string"] = 10788] = "model_number_string";
    bluetoothCharacteristics[bluetoothCharacteristics["navigation"] = 10856] = "navigation";
    bluetoothCharacteristics[bluetoothCharacteristics["network_availability"] = 10814] = "network_availability";
    bluetoothCharacteristics[bluetoothCharacteristics["new_alert"] = 10822] = "new_alert";
    bluetoothCharacteristics[bluetoothCharacteristics["object_action_control_point"] = 10949] = "object_action_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["object_changed"] = 10952] = "object_changed";
    bluetoothCharacteristics[bluetoothCharacteristics["object_first_created"] = 10945] = "object_first_created";
    bluetoothCharacteristics[bluetoothCharacteristics["object_id"] = 10947] = "object_id";
    bluetoothCharacteristics[bluetoothCharacteristics["object_last_modified"] = 10946] = "object_last_modified";
    bluetoothCharacteristics[bluetoothCharacteristics["object_list_control_point"] = 10950] = "object_list_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["object_list_filter"] = 10951] = "object_list_filter";
    bluetoothCharacteristics[bluetoothCharacteristics["object_name"] = 10942] = "object_name";
    bluetoothCharacteristics[bluetoothCharacteristics["object_properties"] = 10948] = "object_properties";
    bluetoothCharacteristics[bluetoothCharacteristics["object_size"] = 10944] = "object_size";
    bluetoothCharacteristics[bluetoothCharacteristics["object_type"] = 10943] = "object_type";
    bluetoothCharacteristics[bluetoothCharacteristics["ots_feature"] = 10941] = "ots_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["plx_continuous_measurement"] = 10847] = "plx_continuous_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["plx_features"] = 10848] = "plx_features";
    bluetoothCharacteristics[bluetoothCharacteristics["plx_spot_check_measurement"] = 10846] = "plx_spot_check_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["pnp_id"] = 10832] = "pnp_id";
    bluetoothCharacteristics[bluetoothCharacteristics["pollen_concentration"] = 10869] = "pollen_concentration";
    bluetoothCharacteristics[bluetoothCharacteristics["position_2d"] = 10799] = "position_2d";
    bluetoothCharacteristics[bluetoothCharacteristics["position_3d"] = 10800] = "position_3d";
    bluetoothCharacteristics[bluetoothCharacteristics["position_quality"] = 10857] = "position_quality";
    bluetoothCharacteristics[bluetoothCharacteristics["pressure"] = 10861] = "pressure";
    bluetoothCharacteristics[bluetoothCharacteristics["protocol_mode"] = 10830] = "protocol_mode";
    bluetoothCharacteristics[bluetoothCharacteristics["pulse_oximetry_control_point"] = 10850] = "pulse_oximetry_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["rainfall"] = 10872] = "rainfall";
    bluetoothCharacteristics[bluetoothCharacteristics["record_access_control_point"] = 10834] = "record_access_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["reference_time_information"] = 10772] = "reference_time_information";
    bluetoothCharacteristics[bluetoothCharacteristics["removable"] = 10810] = "removable";
    bluetoothCharacteristics[bluetoothCharacteristics["report"] = 10829] = "report";
    bluetoothCharacteristics[bluetoothCharacteristics["report_map"] = 10827] = "report_map";
    bluetoothCharacteristics[bluetoothCharacteristics["resolvable_private_address_only"] = 10953] = "resolvable_private_address_only";
    bluetoothCharacteristics[bluetoothCharacteristics["resting_heart_rate"] = 10898] = "resting_heart_rate";
    bluetoothCharacteristics[bluetoothCharacteristics["ringer_control_point"] = 10816] = "ringer_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["ringer_setting"] = 10817] = "ringer_setting";
    bluetoothCharacteristics[bluetoothCharacteristics["rower_data"] = 10961] = "rower_data";
    bluetoothCharacteristics[bluetoothCharacteristics["rsc_feature"] = 10836] = "rsc_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["rsc_measurement"] = 10835] = "rsc_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["sc_control_point"] = 10837] = "sc_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["scan_interval_window"] = 10831] = "scan_interval_window";
    bluetoothCharacteristics[bluetoothCharacteristics["scan_refresh"] = 10801] = "scan_refresh";
    bluetoothCharacteristics[bluetoothCharacteristics["scientific_temperature_celsius"] = 10812] = "scientific_temperature_celsius";
    bluetoothCharacteristics[bluetoothCharacteristics["secondary_time_zone"] = 10768] = "secondary_time_zone";
    bluetoothCharacteristics[bluetoothCharacteristics["sensor_location"] = 10845] = "sensor_location";
    bluetoothCharacteristics[bluetoothCharacteristics["serial_number_string"] = 10789] = "serial_number_string";
    bluetoothCharacteristics[bluetoothCharacteristics["service_required"] = 10811] = "service_required";
    bluetoothCharacteristics[bluetoothCharacteristics["software_revision_string"] = 10792] = "software_revision_string";
    bluetoothCharacteristics[bluetoothCharacteristics["sport_type_for_aerobic_and_anaerobic_thresholds"] = 10899] = "sport_type_for_aerobic_and_anaerobic_thresholds";
    bluetoothCharacteristics[bluetoothCharacteristics["stair_climber_data"] = 10960] = "stair_climber_data";
    bluetoothCharacteristics[bluetoothCharacteristics["step_climber_data"] = 10959] = "step_climber_data";
    bluetoothCharacteristics[bluetoothCharacteristics["string"] = 10813] = "string";
    bluetoothCharacteristics[bluetoothCharacteristics["supported_heart_rate_range"] = 10967] = "supported_heart_rate_range";
    bluetoothCharacteristics[bluetoothCharacteristics["supported_inclination_range"] = 10965] = "supported_inclination_range";
    bluetoothCharacteristics[bluetoothCharacteristics["supported_new_alert_category"] = 10823] = "supported_new_alert_category";
    bluetoothCharacteristics[bluetoothCharacteristics["supported_power_range"] = 10968] = "supported_power_range";
    bluetoothCharacteristics[bluetoothCharacteristics["supported_resistance_level_range"] = 10966] = "supported_resistance_level_range";
    bluetoothCharacteristics[bluetoothCharacteristics["supported_speed_range"] = 10964] = "supported_speed_range";
    bluetoothCharacteristics[bluetoothCharacteristics["supported_unread_alert_category"] = 10824] = "supported_unread_alert_category";
    bluetoothCharacteristics[bluetoothCharacteristics["system_id"] = 10787] = "system_id";
    bluetoothCharacteristics[bluetoothCharacteristics["tds_control_point"] = 10940] = "tds_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["temperature"] = 10862] = "temperature";
    bluetoothCharacteristics[bluetoothCharacteristics["temperature_celsius"] = 10783] = "temperature_celsius";
    bluetoothCharacteristics[bluetoothCharacteristics["temperature_fahrenheit"] = 10784] = "temperature_fahrenheit";
    bluetoothCharacteristics[bluetoothCharacteristics["temperature_measurement"] = 10780] = "temperature_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["temperature_type"] = 10781] = "temperature_type";
    bluetoothCharacteristics[bluetoothCharacteristics["three_zone_heart_rate_limits"] = 10900] = "three_zone_heart_rate_limits";
    bluetoothCharacteristics[bluetoothCharacteristics["time_accuracy"] = 10770] = "time_accuracy";
    bluetoothCharacteristics[bluetoothCharacteristics["time_broadcast"] = 10773] = "time_broadcast";
    bluetoothCharacteristics[bluetoothCharacteristics["time_source"] = 10771] = "time_source";
    bluetoothCharacteristics[bluetoothCharacteristics["time_update_control_point"] = 10774] = "time_update_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["time_update_state"] = 10775] = "time_update_state";
    bluetoothCharacteristics[bluetoothCharacteristics["time_with_dst"] = 10769] = "time_with_dst";
    bluetoothCharacteristics[bluetoothCharacteristics["time_zone"] = 10766] = "time_zone";
    bluetoothCharacteristics[bluetoothCharacteristics["training_status"] = 10963] = "training_status";
    bluetoothCharacteristics[bluetoothCharacteristics["treadmill_data"] = 10957] = "treadmill_data";
    bluetoothCharacteristics[bluetoothCharacteristics["true_wind_direction"] = 10865] = "true_wind_direction";
    bluetoothCharacteristics[bluetoothCharacteristics["true_wind_speed"] = 10864] = "true_wind_speed";
    bluetoothCharacteristics[bluetoothCharacteristics["two_zone_heart_rate_limit"] = 10901] = "two_zone_heart_rate_limit";
    bluetoothCharacteristics[bluetoothCharacteristics["tx_power_level"] = 10759] = "tx_power_level";
    bluetoothCharacteristics[bluetoothCharacteristics["uncertainty"] = 10932] = "uncertainty";
    bluetoothCharacteristics[bluetoothCharacteristics["unread_alert_status"] = 10821] = "unread_alert_status";
    bluetoothCharacteristics[bluetoothCharacteristics["uri"] = 10934] = "uri";
    bluetoothCharacteristics[bluetoothCharacteristics["user_control_point"] = 10911] = "user_control_point";
    bluetoothCharacteristics[bluetoothCharacteristics["user_index"] = 10906] = "user_index";
    bluetoothCharacteristics[bluetoothCharacteristics["uv_index"] = 10870] = "uv_index";
    bluetoothCharacteristics[bluetoothCharacteristics["vo2_max"] = 10902] = "vo2_max";
    bluetoothCharacteristics[bluetoothCharacteristics["waist_circumference"] = 10903] = "waist_circumference";
    bluetoothCharacteristics[bluetoothCharacteristics["weight"] = 10904] = "weight";
    bluetoothCharacteristics[bluetoothCharacteristics["weight_measurement"] = 10909] = "weight_measurement";
    bluetoothCharacteristics[bluetoothCharacteristics["weight_scale_feature"] = 10910] = "weight_scale_feature";
    bluetoothCharacteristics[bluetoothCharacteristics["wind_chill"] = 10873] = "wind_chill";
})(bluetoothCharacteristics || (bluetoothCharacteristics = {}));
var bluetoothDescriptors;
(function (bluetoothDescriptors) {
    bluetoothDescriptors[bluetoothDescriptors["es_configuration"] = 10507] = "es_configuration";
    bluetoothDescriptors[bluetoothDescriptors["es_measurement"] = 10508] = "es_measurement";
    bluetoothDescriptors[bluetoothDescriptors["es_trigger_setting"] = 10509] = "es_trigger_setting";
    bluetoothDescriptors[bluetoothDescriptors["external_report_reference"] = 10503] = "external_report_reference";
    bluetoothDescriptors[bluetoothDescriptors["gatt.characteristic_aggregate_format"] = 10501] = "gatt.characteristic_aggregate_format";
    bluetoothDescriptors[bluetoothDescriptors["gatt.characteristic_extended_properties"] = 10496] = "gatt.characteristic_extended_properties";
    bluetoothDescriptors[bluetoothDescriptors["gatt.characteristic_presentation_format"] = 10500] = "gatt.characteristic_presentation_format";
    bluetoothDescriptors[bluetoothDescriptors["gatt.characteristic_user_description"] = 10497] = "gatt.characteristic_user_description";
    bluetoothDescriptors[bluetoothDescriptors["gatt.client_characteristic_configuration"] = 10498] = "gatt.client_characteristic_configuration";
    bluetoothDescriptors[bluetoothDescriptors["gatt.server_characteristic_configuration"] = 10499] = "gatt.server_characteristic_configuration";
    bluetoothDescriptors[bluetoothDescriptors["number_of_digitals"] = 10505] = "number_of_digitals";
    bluetoothDescriptors[bluetoothDescriptors["report_reference"] = 10504] = "report_reference";
    bluetoothDescriptors[bluetoothDescriptors["time_trigger_setting"] = 10510] = "time_trigger_setting";
    bluetoothDescriptors[bluetoothDescriptors["valid_range"] = 10502] = "valid_range";
    bluetoothDescriptors[bluetoothDescriptors["value_trigger_setting"] = 10506] = "value_trigger_setting";
})(bluetoothDescriptors || (bluetoothDescriptors = {}));
const canonicalUUID = (alias) => {
    if (typeof alias === 'number')
        alias = alias.toString(16);
    alias = alias.toLowerCase();
    if (alias.length <= 8)
        alias = ('00000000' + alias).slice(-8) + '-0000-1000-8000-00805f9b34fb';
    if (alias.length === 32)
        alias = alias.match(/^([0-9a-f]{8})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{12})$/).splice(1).join('-');
    return alias;
};
const getService = (name) => {
    if (typeof name === 'string' && bluetoothServices[name]) {
        name = bluetoothServices[name];
    }
    return canonicalUUID(name);
};
const getCharacteristic = (name) => {
    if (typeof name === 'string' && bluetoothCharacteristics[name]) {
        name = bluetoothCharacteristics[name];
    }
    return canonicalUUID(name);
};
const getDescriptor = (name) => {
    if (typeof name === 'string' && bluetoothDescriptors[name]) {
        name = bluetoothDescriptors[name];
    }
    return canonicalUUID(name);
};
const BluetoothUUID = {
    getService,
    getCharacteristic,
    getDescriptor,
    canonicalUUID
};

/******************************************************************************
Copyright (c) Microsoft Corporation.

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
***************************************************************************** */
/* global Reflect, Promise, SuppressedError, Symbol, Iterator */


function __classPrivateFieldGet(receiver, state, kind, f) {
    if (kind === "a" && !f) throw new TypeError("Private accessor was defined without a getter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver)) throw new TypeError("Cannot read private member from an object whose class did not declare it");
    return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state.get(receiver);
}

function __classPrivateFieldSet(receiver, state, value, kind, f) {
    if (kind === "m") throw new TypeError("Private method is not writable");
    if (kind === "a" && !f) throw new TypeError("Private accessor was defined without a setter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver)) throw new TypeError("Cannot write private member to an object whose class did not declare it");
    return (kind === "a" ? f.call(receiver, value) : f ? f.value = value : state.set(receiver, value)), value;
}

typeof SuppressedError === "function" ? SuppressedError : function (error, suppressed, message) {
    var e = new Error(message);
    return e.name = "SuppressedError", e.error = error, e.suppressed = suppressed, e;
};

var _Store_devices;
const characteristicKey = (uuid, instance) => {
    return uuid + '.' + instance;
};
const keyForCharacteristic = (characteristic) => {
    return characteristicKey(characteristic.uuid, characteristic.instance);
};
class Store {
    constructor() {
        _Store_devices.set(this, void 0);
        this.getDevice = (uuid) => {
            var _a;
            return (_a = __classPrivateFieldGet(this, _Store_devices, "f").get(uuid)) === null || _a === void 0 ? void 0 : _a.device;
        };
        this.addDevice = (device) => {
            this.removeDevice(device.id);
            __classPrivateFieldGet(this, _Store_devices, "f").set(device.id, { uuid: device.id, device, services: new Map() });
        };
        this.removeDevice = (uuid) => {
            const deviceRecord = __classPrivateFieldGet(this, _Store_devices, "f").get(uuid);
            __classPrivateFieldGet(this, _Store_devices, "f").delete(uuid);
            return deviceRecord === null || deviceRecord === void 0 ? void 0 : deviceRecord.device;
        };
        this.getService = (deviceUuid, serviceUuid) => {
            var _a, _b;
            return (_b = (_a = __classPrivateFieldGet(this, _Store_devices, "f").get(deviceUuid)) === null || _a === void 0 ? void 0 : _a.services.get(serviceUuid)) === null || _b === void 0 ? void 0 : _b.service;
        };
        this.addService = (service) => {
            const deviceRecord = __classPrivateFieldGet(this, _Store_devices, "f").get(service.device.id);
            if (!deviceRecord) {
                throw new ReferenceError(`Device ${service.device.id} not found`);
            }
            deviceRecord.services.set(service.uuid, { uuid: service.uuid, service, characteristics: new Map() });
        };
        this.getCharacteristic = (service, uuid, instance) => {
            var _a, _b, _c;
            return (_c = (_b = (_a = __classPrivateFieldGet(this, _Store_devices, "f").get(service.device.id)) === null || _a === void 0 ? void 0 : _a.services.get(service.uuid)) === null || _b === void 0 ? void 0 : _b.characteristics.get(characteristicKey(uuid, instance))) === null || _c === void 0 ? void 0 : _c.characteristic;
        };
        this.addCharacteristic = (service, characteristic) => {
            var _a;
            const serviceRecord = (_a = __classPrivateFieldGet(this, _Store_devices, "f").get(service.device.id)) === null || _a === void 0 ? void 0 : _a.services.get(service.uuid);
            if (!serviceRecord) {
                throw new ReferenceError(`Service ${service.uuid} not found`);
            }
            serviceRecord.characteristics.set(keyForCharacteristic(characteristic), { uuid: characteristic.uuid, characteristic, descriptors: new Map() });
        };
        this.updateCharacteristicValue = (deviceUuid, serviceUuid, uuid, instance, value) => {
            var _a, _b, _c;
            const characteristic = (_c = (_b = (_a = __classPrivateFieldGet(this, _Store_devices, "f").get(deviceUuid)) === null || _a === void 0 ? void 0 : _a.services.get(serviceUuid)) === null || _b === void 0 ? void 0 : _b.characteristics.get(characteristicKey(uuid, instance))) === null || _c === void 0 ? void 0 : _c.characteristic;
            if (!characteristic) {
                throw new ReferenceError(`Characteristic ${uuid} not found`);
            }
            characteristic.value = value;
            return characteristic;
        };
        this.getDescriptor = (characteristic, uuid) => {
            var _a, _b, _c;
            return (_c = (_b = (_a = __classPrivateFieldGet(this, _Store_devices, "f")
                .get(characteristic.service.device.id)) === null || _a === void 0 ? void 0 : _a.services.get(characteristic.service.uuid)) === null || _b === void 0 ? void 0 : _b.characteristics.get(characteristicKey(characteristic.uuid, characteristic.instance))) === null || _c === void 0 ? void 0 : _c.descriptors.get(uuid);
        };
        this.addDescriptor = (characteristic, descriptor) => {
            var _a, _b;
            const characteristicRecord = (_b = (_a = __classPrivateFieldGet(this, _Store_devices, "f")
                .get(characteristic.service.device.id)) === null || _a === void 0 ? void 0 : _a.services.get(characteristic.service.uuid)) === null || _b === void 0 ? void 0 : _b.characteristics.get(keyForCharacteristic(characteristic));
            if (!characteristicRecord) {
                throw new ReferenceError(`Characteristic ${characteristic.uuid} not found`);
            }
            characteristicRecord.descriptors.set(descriptor.uuid, descriptor);
        };
        __classPrivateFieldSet(this, _Store_devices, new Map(), "f");
    }
}
_Store_devices = new WeakMap();
const store = new Store();

const getOrCreateDescriptor = (characteristic, uuid) => {
    const existingDescriptor = store.getDescriptor(characteristic, uuid);
    if (existingDescriptor) {
        return existingDescriptor;
    }
    const descriptor = new BluetoothRemoteGATTDescriptor(characteristic, uuid);
    store.addDescriptor(characteristic, descriptor);
    return descriptor;
};
class BluetoothRemoteGATTCharacteristic extends EventTarget {
    constructor(service, uuid, properties, instance) {
        super();
        this.service = service;
        this.uuid = uuid;
        this.properties = properties;
        this.instance = instance;
        this.GetGATTChildren = async (single, descriptor) => {
            const response = await bluetoothRequest('discoverDescriptors', {
                device: this.service.device.id,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.instance,
                descriptor: descriptor ? BluetoothUUID.getDescriptor(descriptor) : null,
                single: single
            });
            return response.map(uuid => getOrCreateDescriptor(this, uuid));
        };
        this.getDescriptor = async (descriptor) => {
            if (typeof descriptor === "undefined") {
                throw new TypeError("Missing 'descriptor' UUID parameter.");
            }
            const descriptors = await this.GetGATTChildren(true, descriptor);
            return descriptors[0];
        };
        this.getDescriptors = async (descriptor) => {
            return this.GetGATTChildren(false, descriptor);
        };
        this.readValue = async () => {
            await bluetoothRequest('readCharacteristic', {
                device: this.service.device.id,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.instance
            });
            return copyOf(this.value);
        };
        this.startNotifications = async () => {
            await bluetoothRequest('startNotifications', {
                device: this.service.device.id,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.instance
            });
            return this;
        };
        this.stopNotifications = async () => {
            await bluetoothRequest('stopNotifications', {
                device: this.service.device.id,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.instance
            });
            return this;
        };
        this._writeValue = async (value, withResponse) => {
            const arrayBuffer = isView(value) ? value.buffer : value;
            const base64 = arrayBufferToBase64(arrayBuffer);
            await bluetoothRequest('writeCharacteristic', {
                device: this.service.device.id,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.instance,
                value: base64,
                withResponse: withResponse
            });
        };
        this.writeValueWithResponse = async (value) => {
            return this._writeValue(value, true);
        };
        this.writeValueWithoutResponse = async (value) => {
            return this._writeValue(value, false);
        };
        this.value = null;
    }
}
const isView = (source) => source.buffer !== undefined;

const getOrCreateCharacteristic = (service, uuid, properties, instance) => {
    const existingCharacteristic = store.getCharacteristic(service, uuid, instance);
    if (existingCharacteristic) {
        return existingCharacteristic;
    }
    const characteristic = new BluetoothRemoteGATTCharacteristic(service, uuid, properties, instance);
    store.addCharacteristic(service, characteristic);
    return characteristic;
};
class BluetoothRemoteGATTService extends EventTarget {
    constructor(device, uuid, isPrimary) {
        super();
        this.GetGATTChildren = async (single, characteristic) => {
            const response = await bluetoothRequest('discoverCharacteristics', {
                device: this.device.id,
                service: this.uuid,
                characteristic: characteristic ? BluetoothUUID.getCharacteristic(characteristic) : null,
                single: single
            });
            return response.characteristics.map(characteristic => getOrCreateCharacteristic(this, characteristic.uuid, characteristic.properties, characteristic.instance));
        };
        this.getCharacteristic = async (characteristic) => {
            if (typeof characteristic === "undefined") {
                throw new TypeError("Missing 'characteristic' UUID parameter.");
            }
            const characteristics = await this.GetGATTChildren(true, characteristic);
            return characteristics[0];
        };
        this.getCharacteristics = async (characteristic) => {
            return this.GetGATTChildren(false, characteristic);
        };
        this.device = device;
        this.uuid = uuid;
        this.isPrimary = isPrimary;
    }
}

const getOrCreateService = (device, uuid, isPrimary) => {
    const existingService = store.getService(device.id, uuid);
    if (existingService) {
        return existingService;
    }
    const service = new BluetoothRemoteGATTService(device, uuid, isPrimary);
    store.addService(service);
    return service;
};
class BluetoothRemoteGATTServer {
    constructor(device) {
        this.connect = async () => {
            const response = await bluetoothRequest('connect', { uuid: this.device.id });
            this.connected = response.connected;
            return this;
        };
        this.disconnect = async () => {
            const response = await bluetoothRequest('disconnect', { uuid: this.device.id });
            this.connected = !response.disconnected;
        };
        this.GetGATTChildren = async (single, service) => {
            const response = await bluetoothRequest('discoverServices', {
                device: this.device.id,
                service: service ? BluetoothUUID.getService(service) : null,
                single: single
            });
            return response.services.map(service => getOrCreateService(this.device, service, true));
        };
        this.getPrimaryService = async (bluetoothServiceUUID) => {
            if (typeof bluetoothServiceUUID === "undefined") {
                throw new TypeError("Missing 'bluetoothServiceUUID' parameter.");
            }
            const services = await this.GetGATTChildren(true, bluetoothServiceUUID);
            return services[0];
        };
        this.getPrimaryServices = async (bluetoothServiceUUID) => {
            return this.GetGATTChildren(false, bluetoothServiceUUID);
        };
        this.device = device;
        this.connected = false;
    }
}

class BluetoothDevice extends EventTarget {
    constructor(id, name) {
        super();
        this.forget = async () => {
            await bluetoothRequest('forgetDevice', { uuid: this.id });
            store.removeDevice(this.id);
        };
        this.watchAdvertisements = async (options) => {
            let signal = options === null || options === void 0 ? void 0 : options.signal;
            if (signal) {
                if (signal.aborted) {
                    await this._toggleWatchingAdvertisements(false);
                    return;
                }
                signal.addEventListener('abort', () => {
                    this._toggleWatchingAdvertisements(false);
                });
            }
            if (!this.watchingAdvertisements) {
                await this._toggleWatchingAdvertisements(true);
            }
        };
        this._toggleWatchingAdvertisements = async (isWatching) => {
            await bluetoothRequest('watchAdvertisements', { uuid: this.id, enable: isWatching });
            this.watchingAdvertisements = isWatching;
        };
        this.id = id;
        this.name = name;
        this.gatt = new BluetoothRemoteGATTServer(this);
        this.watchingAdvertisements = false;
    }
}

const addToActiveScans = (scan) => {
    const bluetooth = globalThis.topaz.bluetooth;
    removeFromActiveScans(scan.scanId);
    bluetooth.activeScans.push(scan);
};
const removeFromActiveScans = (scanId) => {
    const bluetooth = globalThis.topaz.bluetooth;
    bluetooth.activeScans = bluetooth.activeScans.filter((s) => s.scanId !== scanId);
};
class BluetoothLEScan {
    constructor(scanId, filters, keepRepeatedDevices, acceptAllAdvertisements, active) {
        this.scanId = scanId;
        this.filters = filters;
        this.keepRepeatedDevices = keepRepeatedDevices;
        this.acceptAllAdvertisements = acceptAllAdvertisements;
        this.active = active;
        this.stop = () => {
            this.active = false;
            removeFromActiveScans(this.scanId);
            bluetoothRequest('requestLEScan', { scanId: this.scanId, stop: true });
        };
    }
}
const doRequestLEScan = async (options) => {
    const response = await bluetoothRequest('requestLEScan', { options: options });
    const newScan = new BluetoothLEScan(response.scanId, options.filters, response.keepRepeatedDevices, response.acceptAllAdvertisements, response.active);
    addToActiveScans(newScan);
    return newScan;
};

const getOrCreateDevice = (uuid, name) => {
    const existing = store.getDevice(uuid);
    if (existing) {
        return existing;
    }
    const device = new BluetoothDevice(uuid, name);
    store.addDevice(device);
    return device;
};
class Bluetooth extends EventTarget {
    constructor() {
        super();
        this.activeScans = [];
        this.getAvailability = async () => {
            const response = await bluetoothRequest('getAvailability');
            return response.isAvailable;
        };
        this.getDevices = async () => {
            const response = await bluetoothRequest('getDevices');
            return response.map(device => getOrCreateDevice(device.uuid, device.name));
        };
        this.requestDevice = async (options) => {
            const response = await bluetoothRequest('requestDevice', { options: options });
            return getOrCreateDevice(response.uuid, response.name);
        };
        this.requestLEScan = async (options) => {
            return doRequestLEScan(options);
        };
    }
}

class BluetoothAdvertisingEvent extends Event {
    constructor(type, eventInitDict) {
        var _a, _b;
        super(type, eventInitDict);
        this.device = eventInitDict.device;
        this.uuids = eventInitDict.uuids;
        this.name = eventInitDict.name;
        this.appearance = eventInitDict.appearance;
        this.txPower = eventInitDict.txPower;
        this.rssi = eventInitDict.rssi;
        this.manufacturerData = (_a = eventInitDict.manufacturerData) !== null && _a !== void 0 ? _a : new Map();
        this.serviceData = (_b = eventInitDict.serviceData) !== null && _b !== void 0 ? _b : new Map();
    }
}
const convertToAdvertisingEvent = (event) => {
    const payload = event.data;
    const device = getOrCreateDevice(payload.device.uuid, payload.device.name);
    let manufacturerData = new Map();
    if (payload.advertisement.manufacturerData) {
        manufacturerData.set(payload.advertisement.manufacturerData.code, base64ToDataView(payload.advertisement.manufacturerData.data));
    }
    let serviceData = new Map();
    for (const [key, value] of Object.entries(payload.advertisement.serviceData)) {
        serviceData.set(key, base64ToDataView(value));
    }
    return new BluetoothAdvertisingEvent(event.name, {
        device: device,
        uuids: payload.advertisement.uuids,
        name: payload.advertisement.name,
        rssi: payload.advertisement.rssi,
        txPower: payload.advertisement.txPower,
        manufacturerData: manufacturerData,
        serviceData: serviceData,
    });
};

class ValueEvent extends Event {
    constructor(type, eventInitDict) {
        super(type, eventInitDict);
        this.value = eventInitDict === null || eventInitDict === void 0 ? void 0 : eventInitDict.value;
    }
}

const convertToCharacteristicEvent = (event) => {
    const payload = event.data;
    const data = base64ToDataView(payload.value);
    const characteristic = store.updateCharacteristicValue(payload.device, payload.service, payload.characteristic, payload.instance, data);
    return { characteristic, event: new ValueEvent(event.name, { value: data }) };
};

const processEvent = (event) => {
    let eventToSend;
    let targets = [];
    if (event.id === 'bluetooth') {
        targets.push(globalThis.topaz.bluetooth);
    }
    const pushDeviceTarget = () => {
        if (event.id !== 'bluetooth') {
            const device = store.getDevice(event.id);
            if (device) {
                targets.push(device);
            }
        }
    };
    if (event.name === 'gattserverdisconnected') {
        pushDeviceTarget();
    }
    else if (event.name === 'characteristicvaluechanged') {
        const characteristicEvent = convertToCharacteristicEvent(event);
        targets.push(characteristicEvent.characteristic);
        eventToSend = characteristicEvent.event;
    }
    else if (event.name === 'advertisementreceived') {
        eventToSend = convertToAdvertisingEvent(event);
        pushDeviceTarget();
    }
    if (!eventToSend) {
        eventToSend = new ValueEvent(event.name, { value: event.data });
    }
    for (const target of targets) {
        target.dispatchEvent(eventToSend);
        const handler = target['on' + eventToSend.type];
        if (handler) {
            handler(eventToSend);
        }
    }
};

class Topaz {
    constructor() {
        this.sendEvent = (event) => {
            processEvent(event);
        };
        this.bluetooth = new Bluetooth();
    }
}

const safeStringify = (obj) => {
    try {
        return JSON.stringify(obj);
    }
    catch (e) {
        return `Cannot stringify object ${e.message}`;
    }
};
const percentInterpolation = (format, args) => {
    if (typeof (format) !== 'string') {
        return;
    }
    if (args.length === 0) {
        return format;
    }
    if (!/%s|%v|%o|%d|%i|%f/.test(format)) {
        return;
    }
    return args.reduce((str, val) => str.replace(/%s|%v|%o|%d|%i|%f/, val), format);
};
const logOverride = (level, args) => {
    if (args.length === 0) {
        return;
    }
    let formatted = percentInterpolation(args[0], Array.prototype.slice.call(args, 1));
    if (formatted) {
        appLog({
            level: level,
            msg: formatted.substring(0, 2048),
            console: true,
            sensitive: false,
        });
        return;
    }
    let strings = [];
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (typeof (arg) === 'undefined') {
            strings.push('undefined');
        }
        else if (typeof (arg) === 'object') {
            strings.push(safeStringify(arg).substring(0, 2048));
        }
        else if (typeof (arg) === 'string') {
            strings.push(arg.substring(0, 2048));
        }
        else {
            strings.push(arg.toString().substring(0, 2048));
        }
    }
    appLog({
        level: level,
        msg: strings.join(' '),
        console: true,
        sensitive: false,
    });
};
const setupLogging = () => {
    let originalLog = globalThis.console.log;
    let originalWarn = globalThis.console.warn;
    let originalError = globalThis.console.error;
    let originalDebug = globalThis.console.debug;
    globalThis.console.log = function () {
        originalLog.apply(null, arguments);
        logOverride('debug', arguments);
    };
    globalThis.console.warn = function () {
        originalWarn.apply(null, arguments);
        logOverride('warn', arguments);
    };
    globalThis.console.error = function () {
        originalError.apply(null, arguments);
        logOverride('error', arguments);
    };
    globalThis.console.debug = function () {
        originalDebug.apply(null, arguments);
        logOverride('debug', arguments);
    };
    window.addEventListener('error', (e) => {
        appLog({
            level: 'error',
            msg: `Uncaught ${e}`,
            sensitive: false,
        });
    });
};

if (typeof (navigator.bluetooth) === 'undefined') {
    globalThis.topaz = new Topaz();
    navigator.bluetooth = globalThis.topaz.bluetooth;
    setupLogging();
}
if (typeof (window.BluetoothUUID) === 'undefined') {
    globalThis.BluetoothUUID = BluetoothUUID;
    window.BluetoothUUID = globalThis.BluetoothUUID;
}
