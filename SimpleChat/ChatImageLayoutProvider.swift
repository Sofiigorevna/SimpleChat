//
//  ChatImageLayoutProvider.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

final class ChatImageLayoutProvider {
    static func makeLayout(for imageCount: Int) -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, env in
            switch min(imageCount, 5) {
                case 1:
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                          heightDimension: .fractionalHeight(1.0))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                           heightDimension: .fractionalHeight(1.0))
                    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                    return NSCollectionLayoutSection(group: group)
                    
                case 2:
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                          heightDimension: .fractionalHeight(1.0))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                           heightDimension: .fractionalHeight(1.0))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
                    return NSCollectionLayoutSection(group: group)
                    
                case 3:
                    let topItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                             heightDimension: .fractionalHeight(0.6))
                    let topItem = NSCollectionLayoutItem(layoutSize: topItemSize)
                    topItem.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    
                    let bottomItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                                heightDimension: .fractionalHeight(1.0))
                    let bottomItem = NSCollectionLayoutItem(layoutSize: bottomItemSize)
                    bottomItem.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    
                    let bottomGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                 heightDimension: .fractionalHeight(0.4))
                    let bottomGroup = NSCollectionLayoutGroup.horizontal(layoutSize: bottomGroupSize, subitems: [bottomItem, bottomItem])
                    
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                           heightDimension: .absolute(220))
                    let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [topItem, bottomGroup])
                    return NSCollectionLayoutSection(group: verticalGroup)
                    
                case 4:
                    let topItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                             heightDimension: .fractionalHeight(0.6))
                    let topItem = NSCollectionLayoutItem(layoutSize: topItemSize)
                    topItem.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    
                    let bottomItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / 3.0),
                                                                heightDimension: .fractionalHeight(1.0))
                    let bottomItem = NSCollectionLayoutItem(layoutSize: bottomItemSize)
                    bottomItem.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    
                    let bottomGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                 heightDimension: .fractionalHeight(0.4))
                    let bottomGroup = NSCollectionLayoutGroup.horizontal(layoutSize: bottomGroupSize, subitem: bottomItem, count: 3)
                    
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                           heightDimension: .absolute(220))
                    let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [topItem, bottomGroup])
                    return NSCollectionLayoutSection(group: verticalGroup)
                    
                case 5:
                    let topItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                             heightDimension: .absolute(120))
                    let topItem1 = NSCollectionLayoutItem(layoutSize: topItemSize)
                    topItem1.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    let topItem2 = NSCollectionLayoutItem(layoutSize: topItemSize)
                    topItem2.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    let topGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                              heightDimension: .absolute(120))
                    let topGroup = NSCollectionLayoutGroup.horizontal(layoutSize: topGroupSize, subitems: [topItem1, topItem2])
                    
                    let bottomItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / 3.0),
                                                                heightDimension: .absolute(120))
                    let bottomItem1 = NSCollectionLayoutItem(layoutSize: bottomItemSize)
                    bottomItem1.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    let bottomItem2 = NSCollectionLayoutItem(layoutSize: bottomItemSize)
                    bottomItem2.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    let bottomItem3 = NSCollectionLayoutItem(layoutSize: bottomItemSize)
                    bottomItem3.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    let bottomGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                 heightDimension: .absolute(120))
                    let bottomGroup = NSCollectionLayoutGroup.horizontal(layoutSize: bottomGroupSize,
                                                                         subitems: [bottomItem1, bottomItem2, bottomItem3])
                    
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                           heightDimension: .absolute(240))
                    let verticalGroup = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [topGroup, bottomGroup])
                    return NSCollectionLayoutSection(group: verticalGroup)
                    
                default:
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / 3.0),
                                                          heightDimension: .fractionalHeight(1.0))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                           heightDimension: .absolute(150))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
                    return NSCollectionLayoutSection(group: group)
            }
        }
    }
}
