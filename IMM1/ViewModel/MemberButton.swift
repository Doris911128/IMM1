//  MemberButton.swift
//  Graduation_Project
//
//  Created by Mac on 2023/8/23.
//

import SwiftUI

struct MemberButton: View
{
    var image: String
    var title: String
    var itemContent: String

    var body: some View
    {
        Button
        {

        }
        label:
        {
            HStack
            {
                Image(systemName: self.image)

                Text(self.title)

                Spacer()

                Text(self.itemContent).foregroundColor(.gray)
            }
            .font(.title3)
            .foregroundColor(.black)
            .padding(.vertical, 15)
        }
    }
}
