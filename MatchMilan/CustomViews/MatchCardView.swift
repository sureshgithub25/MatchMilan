//
//  MatchCardView.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct MatchCardView: View {
    @Binding var data: MatchUser
    
    var matchResult: MatchResult {
        MatchResult(rawValue: data.status) ?? .pending
    }
    
    var body: some View {
        VStack(spacing: 18) {
            WebImage(url: URL(string: data.profileImage)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.2))
            }
            .indicator(.activity)
            .clipShape(Circle())
            .frame(width: screenWidth / 3, height: screenWidth / 3)
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
            
            Text(data.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(data.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 10)
            
            switch matchResult {
            case .accepted:
                statusBadge(text: "Matched ❤️", color: .green)
            case .declined:
                statusBadge(text: "Not Interested", color: .red)
            case .pending:
                HStack(spacing: 40) {
                    actionButton(icon: "xmark", color: .red) {
                        updateStatus(to: .declined)
                    }
                    actionButton(icon: "checkmark", color: .green) {
                        updateStatus(to: .accepted)
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(colors: [.white, Color(UIColor.systemGray6)],
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: .infinity, maxHeight: 420)
        .padding(.horizontal, 8)
    }
    
    var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private func updateStatus(to status: MatchResult) {
        data.status = status.rawValue
        let matchedObjects =
        CoreDataManager.shared.objectExists(
            ofType: UserMatch.self,
            matchingID: data.id,
            withKey: "id").1
        matchedObjects.forEach { $0.status = status.rawValue }
        CoreDataManager.shared.saveChanges()
    }
    
    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2.weight(.bold))
            }
        }
    }
    
    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.callout)
            .fontWeight(.medium)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.95))
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.top, 8)
    }
}

#Preview {
    MatchCardView(
        data: .constant(MatchUser(
            id: "1",
            profileImage: "",
            name: "Jane Smith",
            address: "123 Street, New York, USA",
            status: MatchResult.pending.rawValue
        ))
    )
}


