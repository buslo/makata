// controller-template-collection.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import UIKit

public protocol CollectionDelegate: AnyObject {
    associatedtype DelegateItemType: Hashable

    @MainActor func collectionItemSelected(at indexPath: IndexPath, _ item: DelegateItemType) async
}

public extension Templates {
    final class Collection<S: Hashable, E: Hashable>: UIView {
        public typealias SectionLayout = (DataSource, Int, S) -> NSCollectionLayoutSection

        public class DataSource: UICollectionViewDiffableDataSource<S, E> {}

        public let dataSource: DataSource

        public private(set) weak var collectionView: UICollectionView!

        let delegate = DelegateProxy<E>()

        public init(
            header: UIView? = nil,
            footer: UIView? = nil,
            source: (UICollectionView) -> DataSource,
            layout: @escaping SectionLayout
        ) {
            let headerRegistration = Header.Registration
            let footerRegistration = Footer.Registration

            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())

            collectionView.contentInset = .init(top: 0, left: 0, bottom: 8, right: 0)
            collectionView.alwaysBounceVertical = false
            collectionView.delegate = delegate
            collectionView.backgroundColor = .systemBackground

            let source = source(collectionView)
            dataSource = source

            super.init(frame: .zero)

            let initialSupplementaryProvider = source.supplementaryViewProvider

            source.supplementaryViewProvider = { cv, ek, ip in
                switch ek {
                case CollectionHeaderElementType:
                    return cv
                        .dequeueConfiguredReusableSupplementary(using: headerRegistration, for: ip)
                        .setContainingView(header!)
                case CollectionFooterElementType:
                    return cv
                        .dequeueConfiguredReusableSupplementary(using: footerRegistration, for: ip)
                        .setContainingView(footer!)
                default:
                    if let initialSupplementaryProvider {
                        return initialSupplementaryProvider(cv, ek, ip)
                    } else {
                        fatalError("Called for a supplementary view, but no provider.")
                    }
                }
            }

            addSubview(view: collectionView) { make in
                make.edges
                    .equalToSuperview()
            }

            let configuration = UICollectionViewCompositionalLayoutConfiguration()
            configuration.contentInsetsReference = .layoutMargins

            if header != nil {
                let headerSupplementaryItem = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .estimated(120)
                    ),
                    elementKind: CollectionHeaderElementType,
                    alignment: .top
                )

                headerSupplementaryItem.pinToVisibleBounds = true

                configuration.boundarySupplementaryItems.append(headerSupplementaryItem)
            }

            if footer != nil {
                let footerSupplementaryItem = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .estimated(30)
                    ),
                    elementKind: CollectionFooterElementType,
                    alignment: .bottom
                )

                footerSupplementaryItem.pinToVisibleBounds = true

                configuration.boundarySupplementaryItems.append(footerSupplementaryItem)
            }

            collectionView.setCollectionViewLayout(
                UICollectionViewCompositionalLayout(sectionProvider: { section, _ in
                    guard let sectionKind = source.sectionIdentifier(for: section) else {
                        fatalError()
                    }

                    return layout(source, section, sectionKind)
                }, configuration: configuration),
                animated: false
            )

            self.collectionView = collectionView
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError()
        }

        public func setCollectionDelegate<D: CollectionDelegate>(_ target: D) where D.DelegateItemType == E {
            delegate.setupDelegate(delegate: target, dataSource: dataSource)
        }

        public func updateLayout(action: (LayoutUpdateContext) -> Void) {
            action(.init(source: self))

            collectionView.collectionViewLayout.invalidateLayout()
        }

        public func setRefresh(action: @escaping @MainActor () async -> Void) {
            #if !targetEnvironment(macCatalyst)
                let refreshControl = UIRefreshControl(frame: .zero)
                refreshControl.layer.zPosition = 10000

                refreshControl.addAction(UIAction { [unowned refreshControl] _ in
                    Task {
                        await action()
                        refreshControl.endRefreshing()
                    }
                }, for: .primaryActionTriggered)

                collectionView.refreshControl = refreshControl
            #endif
        }

        public func createSnapsot() -> NSDiffableDataSourceSnapshot<S, E> {
            .init()
        }
    }
}

extension Templates.Collection {
    public struct LayoutUpdateContext {
        weak var source: Templates.Collection<S, E>!

        public func cell<View>(
            for item: E,
            dequeuedAs _: View.Type
        ) -> View? where View: UICollectionViewCell {
            guard let formIndexPath = source.dataSource.indexPath(for: item) else {
                return nil
            }

            return source.collectionView.cellForItem(at: formIndexPath) as? View
        }
    }

    class Header: UICollectionReusableView {
        static var Registration: UICollectionView.SupplementaryRegistration<Header> {
            .init(elementKind: CollectionHeaderElementType) { supplementaryView, _, _ in
                supplementaryView.subviews.forEach { $0.removeFromSuperview() }
                supplementaryView.layer.zPosition = 1000
            }
        }

        weak var border: UIView!
        weak var visualEffect: UIVisualEffectView!

        weak var keyvalueObx: NSKeyValueObservation?

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                _ = visualEffect
                    .contentView
                    .backgroundColor(.clear)
            default:
                _ = visualEffect
                    .contentView
                    .backgroundColor(.white.withAlphaComponent(0.65))
            }

            super.traitCollectionDidChange(previousTraitCollection)
        }

        func setContainingView(_ content: UIView) -> Self {
            addSubview(
                view: UIVisualEffectView(
                    effect: UIBlurEffect(style: .regular)
                )
                .assign(to: &visualEffect)
                .hidden()
            ) { make in
                make.leading
                    .bottom
                    .trailing
                    .equalToSuperview()
                make.top
                    .equalToSuperview()
                    .inset(-300)
            }

            addSubview(view: content) { make in
                make.edges
                    .equalToSuperview()
            }

            addSubview(
                view: UIView()
                    .backgroundColor(.separator)
                    .hidden()
                    .assign(to: &border)
            ) { make in
                make.horizontalEdges
                    .bottom
                    .equalToSuperview()

                make.height
                    .equalTo(1 / UIScreen.main.scale)
            }

            traitCollectionDidChange(nil)

            return self
        }

        func displayUpdate(_ showBorder: Bool) {
            layer.shadowOffset = .init(width: 0, height: 1 / UIScreen.main.scale)
            layer.shadowColor = UIColor.black.cgColor

            border.isHidden = !showBorder
            visualEffect.isHidden = !showBorder
        }
    }

    class Footer: UICollectionReusableView {
        static var Registration: UICollectionView.SupplementaryRegistration<Footer> {
            .init(elementKind: CollectionFooterElementType) { supplementaryView, _, _ in
                supplementaryView.subviews.forEach { $0.removeFromSuperview() }
                supplementaryView.layer.zPosition = 1000
            }
        }

        weak var visualEffect: UIVisualEffectView!

        var keyvalueObx: NSKeyValueObservation?

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                _ = visualEffect
                    .contentView
                    .backgroundColor(.clear)
            default:
                _ = visualEffect
                    .contentView
                    .backgroundColor(.white.withAlphaComponent(0.65))
            }

            super.traitCollectionDidChange(previousTraitCollection)
        }

        func setContainingView(_ content: UIView) -> Self {
            addSubview(
                view: UIVisualEffectView(
                    effect: UIBlurEffect(style: .regular)
                )
                .assign(to: &visualEffect)
                .hidden()
            ) { make in
                make.leading
                    .top
                    .trailing
                    .equalToSuperview()
                make.bottom
                    .equalToSuperview()
                    .inset(-300)
            }

            addSubview(view: content) { make in
                make.edges
                    .equalToSuperview()
            }

            traitCollectionDidChange(nil)

            return self
        }
    }
}

extension Templates.Collection {
    class DelegateProxy<E: Hashable>: NSObject, UICollectionViewDelegate {
        typealias DataSource<Section: Hashable> = UICollectionViewDiffableDataSource<Section, E>

        var itemSelected: (IndexPath) -> Void = { _ in }

        func setupDelegate<D: CollectionDelegate>(
            delegate: D,
            dataSource: DataSource<some Hashable>
        ) where E == D.DelegateItemType {
            itemSelected = { [unowned delegate, unowned dataSource] ip in
                Task(priority: .high) { @MainActor [unowned delegate, unowned dataSource] () in
                    await delegate.collectionItemSelected(at: ip, dataSource.itemIdentifier(for: ip)!)
                }
            }
        }

        func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            itemSelected(indexPath)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let ypos = scrollView.contentOffset.y + scrollView.safeAreaInsets.top

            if let collectionView = scrollView as? UICollectionView {
                for view in collectionView.visibleSupplementaryViews(ofKind: CollectionHeaderElementType) {
                    guard let header = view as? Header else {
                        continue
                    }

                    header.displayUpdate(ypos >= 1)
                }
            }
        }
    }
}

let CollectionHeaderElementType = "guni__header"
let CollectionFooterElementType = "guni__footer"
