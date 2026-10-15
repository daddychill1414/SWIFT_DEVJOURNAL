import XCTest
@testable import DevJournal

final class KeychainServiceTests: XCTestCase {
    let keychain = KeychainService.shared
    let testKey = "test_keychain_key"
    
    override func tearDown() {
        _ = keychain.delete(key: testKey)
        super.tearDown()
    }
    
    func testSaveAndLoadString() {
        let saved = keychain.save(key: testKey, string: "test_token_123")
        XCTAssertTrue(saved)
        
        let loaded = keychain.loadString(key: testKey)
        XCTAssertEqual(loaded, "test_token_123")
    }
    
    func testDeleteKey() {
        _ = keychain.save(key: testKey, string: "to_be_deleted")
        let deleted = keychain.delete(key: testKey)
        XCTAssertTrue(deleted)
        
        let loaded = keychain.loadString(key: testKey)
        XCTAssertNil(loaded)
    }
    
    func testLoadNonexistentKey() {
        let loaded = keychain.loadString(key: "nonexistent_key_xyz")
        XCTAssertNil(loaded)
    }
}
