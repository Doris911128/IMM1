//
//  dismissKeyboard.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/11/26.
//

// MARK: 和註冊登入有關的東西，但不知道是什麼
import SwiftUI

extension View
{
    func dismissKeyboard()
    {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
