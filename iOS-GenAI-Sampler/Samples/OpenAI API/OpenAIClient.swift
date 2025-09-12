//
//  OpenAIClient.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/16.
//

import Foundation
import OpenAI

class OpenAIClient {
    typealias Message = ChatQuery.ChatCompletionMessageParam
    typealias UserContent = Message.UserMessageParam.Content
    typealias ContentPart = UserContent.ContentPart
    typealias TextContent = Message.TextContent
    typealias Detail = Message.ContentPartImageParam.ImageURL.Detail

    enum ImageSource {
        case data(Data)
        case url(URL)
    }

    let openAI = OpenAI(apiToken: apiKeyOpenAI)

    // MARK: - Private Methods

    private func send(messages: [ChatQuery.ChatCompletionMessageParam], maxTokens: Int? = nil) async throws -> ChatResult {
        let query = ChatQuery(messages: messages, model: .gpt4_o, maxCompletionTokens: maxTokens)
        return try await openAI.chats(query: query)
    }

    private func sendStream(messages: [ChatQuery.ChatCompletionMessageParam], maxTokens: Int? = nil) -> AsyncThrowingStream<ChatStreamResult, Error> {
        let query = ChatQuery(messages: messages, model: .gpt4_o, maxCompletionTokens: maxTokens)
        return openAI.chatsStream(query: query)
    }

    private static func buildVisionContents(withImages images: [Data], text: String, detail: Detail = .auto) -> UserContent {
        var contentParts: [ContentPart] = [.text(.init(text: text))]
        for data in images {
            contentParts.append(
                .image(.init(imageUrl: .init(imageData: data, detail: detail)))
            )
        }
        return .contentParts(contentParts)
    }

    private static func buildVisionContents(withImage imageSource: ImageSource, text: String, detail: Detail = .auto) -> UserContent {
        var contentParts: [ContentPart] = [.text(.init(text: text))]
        switch imageSource {
        case let .data(imageData):
            contentParts.append(
                .image(.init(imageUrl: .init(imageData: imageData, detail: detail)))
            )
        case let .url(imageURL):
            contentParts.append(
                .image(.init(imageUrl: .init(url: imageURL.absoluteString, detail: detail)))
            )
        }
        return .contentParts(contentParts)
    }

    private static func buildMessages(userMessage: String, image: ImageSource? = nil, systemMessage: String? = nil) -> [ChatQuery.ChatCompletionMessageParam] {
        var messages: [ChatQuery.ChatCompletionMessageParam] = []
        if let image {
            let content = OpenAIClient.buildVisionContents(withImage: image, text: userMessage)
            messages.append(.user(.init(content: content)))
        } else {
            messages.append(.user(.init(content: .string(userMessage))))
        }
        if let systemMessage {
            messages.append(.system(.init(content: .textContent(systemMessage))))
        }
        return messages
    }

    private static func buildMessages(userMessage: String, images: [Data], systemMessage: String? = nil, detail: Detail = .auto) -> [ChatQuery.ChatCompletionMessageParam] {
        let content = buildVisionContents(withImages: images, text: userMessage, detail: detail)
        var messages: [ChatQuery.ChatCompletionMessageParam] = [.user(.init(content: content))]
        if let systemMessage {
            messages.append(.system(.init(content: .textContent(systemMessage))))
        }
        return messages
    }

    // MARK: - Public Methods

    public func send(userMessage: String, image: ImageSource? = nil, systemMessage: String? = nil) async throws -> String {
        let messages = OpenAIClient.buildMessages(userMessage: userMessage, image: image, systemMessage: systemMessage)
        return try await send(messages: messages).choices.first?.message.content ?? ""
    }

    public func send(userMessage: String, image: ImageSource? = nil, systemMessage: String? = nil) -> AsyncThrowingStream<ChatStreamResult, Error> {
        print("\(type(of: self))/\(#function)")
        let messages = OpenAIClient.buildMessages(userMessage: userMessage, image: image, systemMessage: systemMessage)
        return sendStream(messages: messages)
    }

    public func send(userMessage: String, images: [Data], systemMessage: String? = nil, detail: Detail = .auto, maxTokens: Int? = nil) -> AsyncThrowingStream<ChatStreamResult, Error> {
        print("Sending \(images.count) images. Total size: \(images.reduce(0) { $0 + $1.count }) bytes")
        let messages = OpenAIClient.buildMessages(userMessage: userMessage, images: images, systemMessage: systemMessage, detail: detail)
        return sendStream(messages: messages, maxTokens: maxTokens)
    }
}
