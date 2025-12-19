//
//  OpenRouterChatCompletionChunk.swift
//  AIProxy
//
//  Created by Lou Zell on 12/30/24.
//

nonisolated public struct OpenRouterChatCompletionChunk: Decodable, Sendable {
    /// A list of chat completion choices. Can contain more than one elements if
    /// OpenRouterChatCompletionRequestBody's `n` property is greater than 1. Can also be empty for
    /// the last chunk, which contains usage information only.
    public let choices: [Choice]

    /// The model used for the chat completion.
    public let model: String?

    /// The provider used to fulfill the chat completion.
    public let provider: String?

    /// This property is nil for all chunks except for the last chunk, which contains the token
    /// usage statistics for the entire request.
    public let usage: OpenRouterChatCompletionResponseBody.Usage?
    
    /// Gemini thought signature - may be at chunk level
    public let thoughtSignature: String?
    
    private enum CodingKeys: String, CodingKey {
        case choices
        case model
        case provider
        case usage
        case thoughtSignature = "thought_signature"
    }
    
    public init(choices: [Choice], model: String?, provider: String?, usage: OpenRouterChatCompletionResponseBody.Usage?, thoughtSignature: String? = nil) {
        self.choices = choices
        self.model = model
        self.provider = provider
        self.usage = usage
        self.thoughtSignature = thoughtSignature
    }
}

// MARK: Chunk.Choice
extension OpenRouterChatCompletionChunk {
    nonisolated public struct Choice: Decodable, Sendable {
        public let delta: Delta
        public let finishReason: String?
        /// Gemini thought signature - may be at choice level
        public let thoughtSignature: String?

        public init(delta: Delta, finishReason: String?, thoughtSignature: String? = nil) {
            self.delta = delta
            self.finishReason = finishReason
            self.thoughtSignature = thoughtSignature
        }

        private enum CodingKeys: String, CodingKey {
            case delta
            case finishReason = "finish_reason"
            case thoughtSignature = "thought_signature"
        }
    }
}

// MARK: Chunk.Choice.Delta
extension OpenRouterChatCompletionChunk.Choice {
    nonisolated public struct Delta: Codable, Sendable {
        public let role: String

        /// Output content. For reasoning models, these chunks arrive after `reasoning` has finished.
        public let content: String?

        /// Reasoning content. For reasoning models, these chunks arrive before `content`.
        public let reasoning: String?

        public let toolCalls: [ToolCall]?
        
        /// Gemini thought signature for function calling. This encrypted signature must be preserved
        /// and sent back in subsequent requests to maintain reasoning context during multi-turn tool use.
        public let thoughtSignature: String?

        public init(
            role: String,
            content: String? = nil,
            reasoning: String? = nil,
            toolCalls: [OpenRouterChatCompletionChunk.Choice.Delta.ToolCall]? = nil,
            thoughtSignature: String? = nil
        ) {
            self.role = role
            self.content = content
            self.reasoning = reasoning
            self.toolCalls = toolCalls
            self.thoughtSignature = thoughtSignature
        }

        private enum CodingKeys: String, CodingKey {
            case role
            case content
            case reasoning
            case toolCalls = "tool_calls"
            case thoughtSignature = "thought_signature"
        }
    }
}

extension OpenRouterChatCompletionChunk.Choice.Delta {
    nonisolated public struct ToolCall: Codable, Sendable {
        public let index: Int?
        /// The function that the model instructs us to call
        public let function: Function?
        /// Gemini thought signature - may be included with each tool call
        public let thoughtSignature: String?
        
        private enum CodingKeys: String, CodingKey {
            case index
            case function
            case thoughtSignature = "thought_signature"
        }
    }
}

extension OpenRouterChatCompletionChunk.Choice.Delta.ToolCall {
    nonisolated public struct Function: Codable, Sendable {
        /// The name of the function to call.
        public let name: String?

        /// The arguments to call the function with.
        public let arguments: String?
        
        /// Gemini thought signature - may be included with each function call
        public let thoughtSignature: String?
        
        private enum CodingKeys: String, CodingKey {
            case name
            case arguments
            case thoughtSignature = "thought_signature"
        }
    }
}
