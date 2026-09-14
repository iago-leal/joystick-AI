import Foundation

/// Relógio monotônico em nanossegundos, base de todos os carimbos `t_*` do log (D-18).
public enum MonotonicClock {
    public static func nowNs() -> UInt64 {
        clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
    }
}
