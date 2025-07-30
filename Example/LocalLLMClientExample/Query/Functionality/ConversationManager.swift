import Foundation

@Observable @MainActor
public final class ConversationManager {
    public private(set) var messages: [[String: Any]] = []
    private let maxContextTokens: Int
    private let maxToolResponseTokens: Int = 800
    
    public init(maxContextTokens: Int = 3500) {
        self.maxContextTokens = maxContextTokens
    }

    // MARK: - Simple API
    
    public func addUserMessage(_ content: String) {
        let message = ["role": "user", "content": content, "id": UUID().uuidString]
        addMessage(message)
    }
    
    public func addAssistantMessage(_ content: String) {
        let message = ["role": "assistant", "content": content, "id": UUID().uuidString]
        addMessage(message)
    }
    
    public func addSystemMessage(_ content: String) {
        let message = ["role": "system", "content": content, "id": UUID().uuidString]
        addMessage(message)
    }
    
    public func addToolResponseSafely(_ content: String) {
        // Chunk if too big
        if content.count > maxToolResponseTokens * 4 {
            let chunks = chunkText(content)
            for chunk in chunks {
                let message = ["role": "tool", "content": chunk, "id": UUID().uuidString]
                messages.append(message) // Add directly, don't auto-compress yet
            }
        } else {
            let message = ["role": "tool", "content": content, "id": UUID().uuidString]
            messages.append(message) // Add directly, don't auto-compress yet
        }
        // Note: No checkAndCompress() here - we'll do it before LLM call
    }
    
    private func addMessage(_ message: [String: Any]) {
        messages.append(message)
        // Note: No checkAndCompress() here either for user/assistant messages
    }
    
    /// Call this BEFORE sending to LLM - compresses if needed
    public func prepareForLLM() -> [[String: Any]] {
        checkAndCompress() // Compress here, after all tool responses are added
        return messages
    }

    // MARK: - Simple Compression
    
    private func checkAndCompress() {
        let tokenCount = estimateTokens()
        
        if tokenCount > maxContextTokens {
            // Keep system + query log + last exchange
            let system = messages.filter { ($0["role"] as? String) == "system" }
            let nonSystem = messages.filter {
                let role = $0["role"] as? String
                return role != "system" && role != "tool"
            }
            
            // Get the last exchange (user + assistant)
            var lastExchange: [[String: Any]] = []
            for msg in nonSystem.reversed() {
                lastExchange.insert(msg, at: 0)
                if (msg["role"] as? String) == "user" { break }
            }
            
            // Create simple list of previous user queries (excluding the last one)
            let allUserQueries = nonSystem.filter { ($0["role"] as? String) == "user" }
                .compactMap { $0["content"] as? String }
            
            let previousQueries = allUserQueries.dropLast() // Exclude the current/last query
            let queryList = previousQueries.joined(separator: "\n- ")
            
            let queryLog = [
                "role": "system",
                "content": previousQueries.isEmpty ?
                    "Tool cache contains historical data." :
                    "Previous queries:\n- \(queryList)\n\nTool cache contains historical data.",
                "id": UUID().uuidString
            ]
            
            messages = system + [queryLog] + lastExchange
            print("[ConversationManager] Compressed to \(estimateTokens()) tokens")
        }
    }
    
    // MARK: - Helpers
    
    private func chunkText(_ text: String) -> [String] {
        let chunkSize = maxToolResponseTokens * 4
        var chunks: [String] = []
        var start = text.startIndex
        var chunkNum = 1
        
        while start < text.endIndex {
            let end = text.index(start, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            let chunk = String(text[start..<end])
            chunks.append("[CHUNK \(chunkNum)] \(chunk)")
            start = end
            chunkNum += 1
        }
        
        return chunks
    }
    
    private func estimateTokens() -> Int {
        return messages.reduce(0) { sum, msg in
            let content = msg["content"] as? String ?? ""
            return sum + content.count
        } / 4
    }
    
    // MARK: - Public Interface
    
    public func clearConversation() {
        messages.removeAll()
    }
    
    public var displayMessages: [[String: Any]] {
        return messages.filter {
            let role = $0["role"] as? String
            return role != "system" && role != "tool"
        }
    }
}
