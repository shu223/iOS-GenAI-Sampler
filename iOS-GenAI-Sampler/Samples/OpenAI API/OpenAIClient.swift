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
    typealias Content = Message.UserMessageParam.Content
    typealias Detail = Content.VisionContent.ChatCompletionContentPartImageParam.ImageURL.Detail

    enum ImageSource {
        case data(Data)
        case url(URL)
    }

    let openAI = OpenAI(apiToken: apiKeyOpenAI)

    // MARK: - Private Methods

    private func send(messages: [ChatQuery.ChatCompletionMessageParam], maxTokens: Int? = nil) async throws -> ChatResult {
        let query = ChatQuery(messages: messages, model: .gpt4_o, maxTokens: maxTokens)
        return try await openAI.chats(query: query)
    }

    private func sendStream(messages: [ChatQuery.ChatCompletionMessageParam], maxTokens: Int? = nil) -> AsyncThrowingStream<ChatStreamResult, Error> {
        let query = ChatQuery(messages: messages, model: .gpt4_o, maxTokens: maxTokens)
        return openAI.chatsStream(query: query)
    }

    private static func buildVisionContents(withImages images: [Data], text: String, detail: Detail = .auto) -> [Content.VisionContent] {
        var visionContents: [Content.VisionContent] = [.init(chatCompletionContentPartTextParam: .init(text: text))]
        for data in images {
            visionContents.append(
                .init(chatCompletionContentPartImageParam: .init(imageUrl: .init(url: data, detail: detail)))
            )
        }
        return visionContents
    }

    private static func buildVisionContents(withImage imageSource: ImageSource, text: String, detail: Detail = .auto) -> [Content.VisionContent] {
        var visionContents: [Content.VisionContent] = [.init(chatCompletionContentPartTextParam: .init(text: text))]
        switch imageSource {
        case let .data(imageData):
            visionContents.append(
                .init(chatCompletionContentPartImageParam: .init(imageUrl: .init(url: imageData, detail: detail)))
            )
        case let .url(imageURL):
            visionContents.append(
                .init(chatCompletionContentPartImageParam: .init(imageUrl: .init(url: imageURL.path, detail: detail)))
            )
        }
        return visionContents
    }

    private static func buildMessages(userMessage: String, image: ImageSource? = nil, systemMessage: String? = nil) -> [ChatQuery.ChatCompletionMessageParam] {
        var messages: [ChatQuery.ChatCompletionMessageParam] = []
        if let image {
            messages.append(.init(role: .user, content: OpenAIClient.buildVisionContents(withImage: image, text: userMessage))!)
        } else {
            messages.append(.init(role: .user, content: userMessage)!)
        }
        if let systemMessage {
            messages.append(.init(role: .system, content: systemMessage)!)
        }
        return messages
    }

    private static func buildMessages(userMessage: String, images: [Data], systemMessage: String? = nil, detail: Detail = .auto) -> [ChatQuery.ChatCompletionMessageParam] {
        let visionContents = buildVisionContents(withImages: images, text: userMessage, detail: detail)
        var messages: [ChatQuery.ChatCompletionMessageParam] = [.init(role: .user, content: visionContents)!]
        if let systemMessage {
            messages.append(.init(role: .system, content: systemMessage)!)
        }
        return messages
    }

    // MARK: - Public Methods

    public func send(userMessage: String, image: ImageSource? = nil, systemMessage: String? = nil) async throws -> String {
        let messages = OpenAIClient.buildMessages(userMessage: userMessage, image: image, systemMessage: systemMessage)
        return try await send(messages: messages).choices.first?.message.content?.string ?? ""
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
