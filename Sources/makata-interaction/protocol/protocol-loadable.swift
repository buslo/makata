// protocol-loadable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Loadable: Stateable where State == LoadableDataState<LoadableData> {
    associatedtype LoadableData

    func loadData(previousData: LoadableData?) async throws -> LoadableData

    func invalidate() async
}

public extension Loadable {
    func invalidate() async {
        let previousData = stateHandler.current.value
        await updateState(to: .pending(previousData))

        if Task.isCancelled {
            return
        }

        do {
            let newData = try await loadData(previousData: previousData)
            await updateState(to: .success(newData))
        } catch {
            await updateState(to: .failure(previousData, error))
        }
    }
}

public enum LoadableDataState<Data> {
    case success(Data)
    case pending(Data?)
    case failure(Data?, Error)
}

public extension LoadableDataState {
    var value: Data? {
        switch self {
        case .success(let data):
            return data
        case .pending(let data), .failure(let data, _):
            return data
        }
    }
    
    var error: Error? {
        switch self {
        case .failure(_, let error):
            return error
        default:
            return nil
        }
    }
}
