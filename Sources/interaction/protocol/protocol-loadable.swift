// protocol-loadable.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation

public protocol Loadable: Stateable where State == LoadableDataState<LoadableData> {
    associatedtype LoadableData

    func loadData() async throws -> LoadableData

    func invalidate()
}

public extension Loadable {
    func invalidate() async {
        let previousData: LoadableData?

        if case let .success(pd) = stateHandler.current {
            previousData = pd
        } else {
            previousData = nil
        }

        await updateState(to: .pending(previousData))

        do {
            let newData = try await loadData()

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
