import Foundation
import XCTest

@testable import FinderFavoritesCore

final class ConfigurationFuzzTests: XCTestCase {
  func testBoundedJSONMutations() throws {
    let seeds = [
      #"{"schemaVersion":1,"placement":"bottom","entries":[]}"#,
      #"{"schemaVersion":1,"placement":"top","entries":[{"id":"a","label":"A","path":"/tmp/a","onMissing":"skip"}]}"#,
      #"{"schemaVersion":1,"placement":"bottom","entries":[{"id":"a","label":"A","path":"/tmp/a","onMissing":"error"},{"id":"b","label":"B","path":"/tmp/b","onMissing":"createDirectory"}]}"#,
      #"{"schemaVersion":2,"placement":"bottom","entries":[]}"#,
      #"{"schemaVersion":1,"placement":"bottom","entries":[],"unknown":true}"#,
      "",
      "[]",
    ]
    var random = JSONMutationRandom(state: 0xF17D_2026_5EED)

    for iteration in 0..<1_000 {
      var bytes = Array(seeds[Int(random.next() % UInt64(seeds.count))].utf8)
      let offset = Int(random.next() % UInt64(bytes.count + 1))
      switch random.next() % 3 {
      case 0 where !bytes.isEmpty:
        bytes.remove(at: min(offset, bytes.count - 1))
      case 1 where bytes.count < 512:
        bytes.insert(UInt8(truncatingIfNeeded: random.next()), at: offset)
      default:
        if !bytes.isEmpty {
          bytes[min(offset, bytes.count - 1)] = UInt8(truncatingIfNeeded: random.next())
        }
      }

      guard let configuration = try? ConfigurationLoader.decode(Data(bytes)) else { continue }
      XCTAssertEqual(configuration.schemaVersion, 1, "case \(iteration)")
      XCTAssertLessThanOrEqual(
        configuration.entries.count, ConfigurationLoader.maximumEntries, "case \(iteration)"
      )
      let encoded = try JSONEncoder().encode(configuration)
      let roundTrip = try ConfigurationLoader.decode(encoded)
      XCTAssertEqual(roundTrip, configuration, "case \(iteration)")
    }
  }
}

private struct JSONMutationRandom {
  var state: UInt64

  mutating func next() -> UInt64 {
    state ^= state << 13
    state ^= state >> 7
    state ^= state << 17
    return state
  }
}
