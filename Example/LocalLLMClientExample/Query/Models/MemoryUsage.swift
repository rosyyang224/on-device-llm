//
//  MemoryUsage.swift
//  LocalLLMClientExample
//
//  Created by Rosemary Yang on 8/13/25.
//


import MachO
import Darwin.Mach

struct MemoryUsage {
    static func residentMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0, &count)
            }
        }
        guard kerr == KERN_SUCCESS else { return -1 }
        return Double(info.resident_size) / (1024.0 * 1024.0)
    }
}
