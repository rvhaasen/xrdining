//
//  VideoConfig.swift
//  XRDining
//
//  Created by Rick van Haasen on 04/08/2025.
//
struct VideoInfo {
    enum World: CustomStringConvertible, CaseIterable, Identifiable {
        case
            visvijver,
            visvijver_qoocam_topaz,
            lanciaDag,
            none
        var id: Self { self }
        
        var description: String {
            switch self {
                case .visvijver_qoocam_topaz: return "visvijver_qoocam_8k30_8k_topaz"
                case .visvijver: return "philips-visvijver"
                case .lanciaDag: return "lancia_dag_360"
                case .none: return "none"
            }
        }
    }
    var rotationDegrees: Float
}
