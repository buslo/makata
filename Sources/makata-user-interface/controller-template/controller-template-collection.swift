// controller-template-collection.swift
//
// Code Copyright Buslo Collective
// Created 2/3/23

import Foundation
import UIKit

public protocol CollectionDelegate: AnyObject {
    associatedtype DelegateItemType: Hashable

    @MainActor func collectionItemSelected(at indexPath: IndexPath, _ item: DelegateItemType) async

    @MainActor func collectionContentRectChanged(_ rect: Templates.CollectionContentRect)
}

public extension CollectionDelegate {
    func collectionContentRectChanged(_: Templates.CollectionContentRect) {}
}

public extension Templates {
    struct CollectionContentRect {
        public let offset: CGPoint
        public let offsetAdjusted: CGPoint

        public let size: CGSize
    }

    final class Collection<S: Hashable, E: Hashable>: UIView, HasHeader {
        public typealias SectionLayout = (__shared DataSource, Int, S) -> NSCollectionLayoutSection

        public class DataSource: UICollectionViewDiffableDataSource<S, E> {}

        private(set) weak var headerViewContainer: Header?

        public private(set) weak var headerView: (UIView & ViewHeader)?

        public private(set) weak var collectionView: UICollectionView!

        public var showHairlineBorder = true {
            didSet {
                headerViewContainer?
                    .displayUpdate(showHairlineBorder)
            }
        }

        public let dataSource: DataSource

        let delegate = DelegateProxy<E>()

        public init(
            frame: CGRect,
            header: __owned(UIView & ViewHeader)? = nil,
            footer: __owned UIView? = nil,
            source: (__shared UICollectionView) -> DataSource,
            layout: (_ dataSource: DataSource) -> UICollectionViewCompositionalLayout
        ) {
            headerView = header

            let collectionView = Self.setupCollectionView(delegate: delegate)
            dataSource = Self.setupDataSource(source(collectionView), footer: footer)

            let collectionLayout = Self.setupLayout(layout(dataSource), footer: footer)
            collectionView.setCollectionViewLayout(collectionLayout, animated: false)
            
            super.init(frame: frame)

            self.collectionView = collectionView
            
            addSubview(collectionView
                .defineConstraints { make in
                    make.edges
                        .equalToSuperview()
                })

            if let header {
                setupHeader(content: header)
            }
        }

        public convenience init(
            frame: CGRect,
            header: __owned(UIView & ViewHeader)? = nil,
            footer: __owned UIView? = nil,
            source: (__shared UICollectionView) -> DataSource,
            layout: @escaping SectionLayout
        ) {
            self.init(
                frame: frame,
                header: header,
                footer: footer,
                source: source
            ) { source in
                UICollectionViewCompositionalLayout(sectionProvider: { [unowned source] section, _ in
                    guard let sectionKind = source.sectionIdentifier(for: section) else {
                        fatalError()
                    }

                    return layout(source, section, sectionKind)
                })
            }
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            fatalError()
        }
        
        public override func didMoveToSuperview() {
            super.didMoveToSuperview()
            
            guard superview != nil else {
                return
            }
            
            updateContentInsets()
        }
        
        public override func layoutSubviews() {
            super.layoutSubviews()
            
            updateContentInsets()
        }

        public func setCollectionDelegate<D: CollectionDelegate>(
            _ target: __shared D
        ) where D.DelegateItemType == E {
            delegate.setupDelegate(delegate: target, dataSource: dataSource)
        }

        public func updateLayout(action: (LayoutUpdateContext) -> Void) {
            action(.init(source: self))

            collectionView.collectionViewLayout.invalidateLayout()
        }

        public func setRefresh(action: __owned @escaping @MainActor () async -> Void) {
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
        
        func updateContentInsets() {
            var inset = collectionView.contentInset
            
            if let headerViewContainer {
                inset.top = headerViewContainer.bounds.height - safeAreaInsets.top
            } else {
                inset.top = 0
            }
            
            collectionView.contentInset = inset
        }
        
        func setupHeader(content: __owned(UIView & ViewHeader)) {
            addSubview(
                Header()
                    .setContainingView(content)
                    .displayUpdate(true)
                    .assign(to: &headerViewContainer)
                    .defineConstraints { make in
                        make.horizontalEdges
                            .top
                            .equalToSuperview()
                    }
            )
        }
        
        static func setupCollectionView(delegate: DelegateProxy<E>) -> UICollectionView {
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())

            collectionView.contentInset = .init(top: 0, left: 0, bottom: 8, right: 0)
            collectionView.alwaysBounceVertical = false
            collectionView.delegate = delegate
            collectionView.backgroundColor = .systemBackground

            return collectionView
        }
        
        static func setupDataSource(
            _ dataSource: DataSource,
            footer: UIView?
        ) -> DataSource {
            let footerRegistration = Footer.Registration
            let initialSupplementaryProvider = dataSource.supplementaryViewProvider

            dataSource.supplementaryViewProvider = { cv, ek, ip in
                switch ek {
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

            return dataSource
        }
        
        static func setupLayout(
            _ collectionLayout: UICollectionViewCompositionalLayout,
            footer: UIView?
        ) -> UICollectionViewCompositionalLayout {
            let configuration = collectionLayout.configuration

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

            collectionLayout.configuration = configuration

            return collectionLayout
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

    class Header: UIView{
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

        @discardableResult
        func setContainingView(_ content: UIView) -> Self {
            addSubview(
                UIVisualEffectView(effect: UIBlurEffect(style: .regular))
                    .assign(to: &visualEffect)
                    .hidden()
                    .defineConstraints { make in
                        make.leading
                            .bottom
                            .trailing
                            .equalToSuperview()
                        make.top
                            .equalToSuperview()
                            .inset(-300)
                    }
            )

            addSubview(
                content
                    .defineConstraints { [unowned self] make in
                        make.edges
                            .equalTo(safeAreaLayoutGuide)
                    }
            )

            addSubview(
                UIView()
                    .backgroundColor(.separator)
                    .hidden()
                    .assign(to: &border)
                    .defineConstraints { make in
                        make.horizontalEdges
                            .bottom
                            .equalToSuperview()

                        make.height
                            .equalTo(1 / UIScreen.main.scale)
                    }
            )

            traitCollectionDidChange(nil)

            return self
        }

        @discardableResult
        func displayUpdate(_ showBorder: Bool) -> Self {
            layer.shadowOffset = .init(width: 0, height: 1 / UIScreen.main.scale)
            layer.shadowColor = UIColor.black.cgColor

            border.isHidden = !showBorder
            visualEffect.isHidden = !showBorder
            
            return self
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
                UIVisualEffectView(effect: UIBlurEffect(style: .regular))
                    .assign(to: &visualEffect)
                    .hidden()
                    .defineConstraints { make in
                        make.leading
                            .top
                            .trailing
                            .equalToSuperview()
                        make.bottom
                            .equalToSuperview()
                            .inset(-300)
                    }
            )

            addSubview(
                content
                    .defineConstraints { make in
                        make.edges
                            .equalToSuperview()
                    }
            )

            traitCollectionDidChange(nil)

            return self
        }
    }
}

extension Templates.Collection {
    class DelegateProxy<_E: Hashable>: NSObject, UICollectionViewDelegate {
        typealias DataSource<Section: Hashable> = UICollectionViewDiffableDataSource<Section, _E>

        var itemSelected: (IndexPath) -> Void = { _ in }

        var contentRectChanged: (Templates.CollectionContentRect) -> Void = { _ in }
        
        func setupDelegate<D: CollectionDelegate>(
            delegate: D,
            dataSource: DataSource<some Hashable>
        ) where _E == D.DelegateItemType {
            itemSelected = { [unowned delegate, unowned dataSource] ip in
                Task(priority: .high) { @MainActor [unowned delegate, unowned dataSource] () in
                    await delegate.collectionItemSelected(at: ip, dataSource.itemIdentifier(for: ip)!)
                }
            }

            contentRectChanged = { [unowned delegate] rect in
                delegate.collectionContentRectChanged(rect)
            }
        }

        func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            itemSelected(indexPath)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let ypos = scrollView.contentOffset.y + scrollView.safeAreaInsets.top

            if let collectionView = scrollView.superview as? Templates.Collection<S, E> {
                collectionView
                    .headerViewContainer?
                    .displayUpdate(ypos >= -collectionView.safeAreaInsets.top)
            }

            contentRectChanged(
                .init(
                    offset: scrollView.contentOffset,
                    offsetAdjusted: .init(x: 0, y: ypos),
                    size: scrollView.contentSize
                )
            )
        }
    }
}

public extension Templates.CollectionContentRect {
    func interpolate(
        from input: ClosedRange<CGFloat>,
        mapsTo output: ClosedRange<CGFloat>
    ) -> (_ value: CGFloat) -> CGFloat {
        let length = (input.upperBound - input.lowerBound)

        return { value in
            let ratio = (value - input.lowerBound) / length
            return min(output.upperBound, max(output.lowerBound, output.lowerBound + output.upperBound * ratio))
        }
    }
}

let CollectionHeaderElementType = "guni__header"
let CollectionFooterElementType = "guni__footer"
