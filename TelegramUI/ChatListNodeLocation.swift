import Foundation
import Postbox
import TelegramCore
import SwiftSignalKit
import Display

enum ChatListNodeLocation: Equatable {
    case initial(count: Int)
    case navigation(index: MessageIndex)
    case scroll(index: MessageIndex, sourceIndex: MessageIndex, scrollPosition: ListViewScrollPosition, animated: Bool)
    
    static func ==(lhs: ChatListNodeLocation, rhs: ChatListNodeLocation) -> Bool {
        switch lhs {
            case let .navigation(index):
                switch rhs {
                    case .navigation(index):
                        return true
                    default:
                        return false
                }
            default:
                return false
        }
    }
}

struct ChatListNodeViewUpdate {
    let view: ChatListView
    let type: ViewUpdateType
    let scrollPosition: ChatListNodeViewScrollPosition?
}

func chatListViewForLocation(_ location: ChatListNodeLocation, account: Account) -> Signal<ChatListNodeViewUpdate, NoError> {
    switch location {
        case let .initial(count):
            let signal: Signal<(ChatListView, ViewUpdateType), NoError>
            signal = account.postbox.tailChatListView(count)
            return signal |> map { view, updateType -> ChatListNodeViewUpdate in
                return ChatListNodeViewUpdate(view: view, type: updateType, scrollPosition: nil)
            }
        case let .navigation(index):
            var first = true
            return account.postbox.aroundChatListView(index, count: 80) |> map { view, updateType -> ChatListNodeViewUpdate in
                let genericType: ViewUpdateType
                if first {
                    first = false
                    genericType = ViewUpdateType.UpdateVisible
                } else {
                    genericType = updateType
                }
                return ChatListNodeViewUpdate(view: view, type: genericType, scrollPosition: nil)
            }
        case let .scroll(index, sourceIndex, scrollPosition, animated):
            let directionHint: ListViewScrollToItemDirectionHint = sourceIndex > index ? .Down : .Up
            let chatScrollPosition: ChatListNodeViewScrollPosition = .index(index: index, position: scrollPosition, directionHint: directionHint, animated: animated)
            var first = true
            return account.postbox.aroundChatListView(index, count: 80) |> map { view, updateType -> ChatListNodeViewUpdate in
                let genericType: ViewUpdateType
                let scrollPosition: ChatListNodeViewScrollPosition? = first ? chatScrollPosition : nil
                if first {
                    first = false
                    genericType = ViewUpdateType.UpdateVisible
                } else {
                    genericType = updateType
                }
                return ChatListNodeViewUpdate(view: view, type: genericType, scrollPosition: scrollPosition)
            }
    }
}
