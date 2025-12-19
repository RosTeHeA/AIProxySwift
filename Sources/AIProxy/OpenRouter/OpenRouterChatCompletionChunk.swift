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
        
        /// OpenRouter reasoning details - contains signatures and thinking blocks that must be preserved
        public let reasoningDetails: [ReasoningDetail]?
        
        /// Extra content that may contain provider-specific data
        public let extraContent: ExtraContent?

        public init(
            role: String,
            content: String? = nil,
            reasoning: String? = nil,
            toolCalls: [OpenRouterChatCompletionChunk.Choice.Delta.ToolCall]? = nil,
            thoughtSignature: String? = nil,
            reasoningDetails: [ReasoningDetail]? = nil,
            extraContent: ExtraContent? = nil
        ) {
            self.role = role
            self.content = content
            self.reasoning = reasoning
            self.toolCalls = toolCalls
            self.thoughtSignature = thoughtSignature
            self.reasoningDetails = reasoningDetails
            self.extraContent = extraContent
        }

        private enum CodingKeys: String, CodingKey {
            case role
            case content
            case reasoning
            case toolCalls = "tool_calls"
            case thoughtSignature = "thought_signature"
            case reasoningDetails = "reasoning_details"
            case extraContent = "extra_content"
        }
        
        /// Helper to get thought signature from any location
        public var effectiveThoughtSignature: String? {
            thoughtSignature ?? extraContent?.google?.thoughtSignature
        }
    }
    
    /// Extra content wrapper for provider-specific data at delta level
    nonisolated public struct ExtraContent: Codable, Sendable {
        public let google: GoogleContent?
        
        nonisolated public struct GoogleContent: Codable, Sendable {
            public let thoughtSignature: String?
            
            private enum CodingKeys: String, CodingKey {
                case thoughtSignature = "thought_signature"
            }
        }
    }
}

// MARK: Chunk.Choice.Delta.ReasoningDetail
extension OpenRouterChatCompletionChunk.Choice.Delta {
    nonisolated public struct ReasoningDetail: Codable, Sendable {
        public let type: String?
        public let thinking: String?
        /// The thought signature that must be preserved and sent back (legacy field name)
        public let signature: String?
        /// Encrypted reasoning data (for type="reasoning.encrypted") - THIS is the thought signature for Gemini
        public let data: String?
        /// Unique identifier for the reasoning detail
        public let id: String?
        /// Format of the reasoning detail (e.g., "anthropic-claude-v1", "openai-responses-v1")
        public let format: String?
        /// Sequential index
        public let index: Int?
        
        public init(type: String? = nil, thinking: String? = nil, signature: String? = nil, data: String? = nil, id: String? = nil, format: String? = nil, index: Int? = nil) {
            self.type = type
            self.thinking = thinking
            self.signature = signature
            self.data = data
            self.id = id
            self.format = format
            self.index = index
        }
        
        /// Get the effective signature - checks both signature field and data field for encrypted types
        public var effectiveSignature: String? {
            signature ?? (type == "reasoning.encrypted" ? data : nil)
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
        /// Extra content that may contain provider-specific data like google.thought_signature
        public let extraContent: ExtraContent?
        
        private enum CodingKeys: String, CodingKey {
            case index
            case function
            case thoughtSignature = "thought_signature"
            case extraContent = "extra_content"
        }
        
        /// Helper to get thought signature from any location
        public var effectiveThoughtSignature: String? {
            thoughtSignature ?? extraContent?.google?.thoughtSignature
        }
    }
    
    /// Extra content wrapper for provider-specific data
    nonisolated public struct ExtraContent: Codable, Sendable {
        public let google: GoogleContent?
        
        nonisolated public struct GoogleContent: Codable, Sendable {
            public let thoughtSignature: String?
            
            private enum CodingKeys: String, CodingKey {
                case thoughtSignature = "thought_signature"
            }
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
