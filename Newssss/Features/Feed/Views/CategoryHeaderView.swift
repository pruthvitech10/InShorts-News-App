//
//  CategoryHeaderView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI


// MARK: - CategoryHeaderView

struct CategoryHeaderView: View {
    @Binding var selectedCategory: NewsCategory
    let onCategoryChange: (NewsCategory) -> Void
    let onCategoryDoubleClick: (NewsCategory) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category,
                        onSingleTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                onCategoryChange(category)
                                HapticFeedback.light()
                            }
                        },
                        onDoubleTap: {
                            onCategoryDoubleClick(category)
                            HapticFeedback.heavy()
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - CategoryPill

struct CategoryPill: View {
    let category: NewsCategory
    let isSelected: Bool
    let onSingleTap: () -> Void
    let onDoubleTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon for the category
            if isSelected {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            Text(category.displayName)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
        }
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, isSelected ? 20 : 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.black : Color(.systemGray6))
        .clipShape(Capsule())
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .onTapGesture(count: 1) {
            onSingleTap()
        }
    }
}
