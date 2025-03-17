import Flutter
import HealthKit

class HealthStatisticsPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.idlefit/health_statistics", binaryMessenger: registrar.messenger())
        let instance = HealthStatisticsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "queryStatistics" else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        guard let args = call.arguments as? [String: Any],
              let startTime = args["startTime"] as? Int,
              let endTime = args["endTime"] as? Int,
              let typeString = args["type"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Missing or invalid arguments",
                              details: nil))
            return
        }
        
       
        
        // Get the HKQuantityType based on the type string
        guard let quantityType = getQuantityType(for: typeString),
        let qt = HKQuantityType.quantityType(forIdentifier: quantityType)
        else {
            result(FlutterError(code: "INVALID_TYPE",
                              message: "Invalid health data type: \(typeString)",
                              details: nil))
            return
        }
        
        let startDate = Date(timeIntervalSince1970: TimeInterval(startTime) / 1000)
        let endDate = Date(timeIntervalSince1970: TimeInterval(endTime) / 1000)
        
        // Create and execute the statistics query
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: qt,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { _, statistics, error in
            if let error = error {
                result(FlutterError(code: "QUERY_ERROR",
                                  message: error.localizedDescription,
                                  details: nil))
                return
            }
            
            guard let stats = statistics,
                  let sum = stats.sumQuantity() else {
                result(0.0)
                return
            }
            
            // Convert the quantity to the appropriate unit
            let value: Double
            switch quantityType {
            case .stepCount:
                value = sum.doubleValue(for: .count())
            case .activeEnergyBurned:
                value = sum.doubleValue(for: .kilocalorie())
            case .appleExerciseTime:
                value = sum.doubleValue(for: .minute())
            default:
                value = 0.0
            }
            
            result(value)
        }
        HKHealthStore().execute(query)
    }
    
    private func getQuantityType(for typeString: String) -> HKQuantityTypeIdentifier? {
        switch typeString {
        case "STEPS":
            return .stepCount
        case "ACTIVE_ENERGY_BURNED":
            return .activeEnergyBurned
        case "EXERCISE_TIME":
            return .appleExerciseTime
        default:
            return nil
        }
    }
} 
