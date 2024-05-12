//
//  ForgetPassword.swift
//
//  Created  on 2023/8/18.
//

// MARK: 忘記密碼View
import SwiftUI

struct ForgetPasswordView: View
{
    @State private var mail: String=""

    var body: some View
    {
        VStack(spacing: 50)
        {
            Text("忘記密碼")
                .bold()
                .font(.largeTitle)

            VStack(alignment: .leading)
            {
                Text("請輸入註冊的電子郵件：")
                    .bold()
                    .font(.title3)

                TextField("電子郵件...", text: self.$mail)
                    .font(.title)
                    .padding(10)
                    .cornerRadius(20)
                    .overlay
                    {
                        RoundedRectangle(cornerRadius: 30).stroke(.gray, lineWidth: 1)
                    }
            }

            Button
            {
                //點擊「傳送驗證碼」之後要執行的動作
            }
            label:
            {
                Text("傳送驗證碼")
                    .bold()
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding()
                    .background(.black)
                    .cornerRadius(20)
            }

            Text("-我們將立即幫您尋找密碼-").font(.title3)
        }
        .padding(.top, 50)
        .padding(.horizontal, 30)
    }
}

struct ForgetPasswordView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ForgetPasswordView()
    }
}
