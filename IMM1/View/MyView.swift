//
//  MyView.swift
//  Graduation_Project
//
//  Created by Mac on 2023/9/15.
//

// MARK: 設置View
import SwiftUI
import PhotosUI

struct MyView: View
{
    @AppStorage("userImage") private var userImage: Data?
    @AppStorage("colorScheme") private var colorScheme: Bool=true
    @AppStorage("signin") private var signin: Bool = false
    
    @Binding var select: Int
    
    @State private var realTime: RealTime = RealTime() //創建 RealTime 對象
    @State private var pickImage: PhotosPickerItem?
    @State var isDarkMode: Bool = false
    @State private var isNameSheetPresented = false //更新名字完後會自動關掉ＳＨＥＥＴ
    
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var user: User //提供所有View使用的User結構
    
    private let label: [InformationLabel]=[
        InformationLabel(image: "person.fill", label: "名稱"),
        InformationLabel(image: "figure.arms.open", label: "性別"),
        InformationLabel(image: "birthday.cake.fill", label: "生日"),
    ]
    
    //    private let tag: [String]=["高血壓", "尿酸", "高血脂", "美食尋寶家", "7日打卡"]
    
    // MARK: 設定顯示資訊
    private func setInformation(index: Int) -> String
    {
        switch(index)
        {
        case 0:
            return self.user.name
        case 1:
            return self.user.gender
        case 2:
            return self.user.birthday
        default:
            return ""
        }
    }
    
    var body: some View
    {
        NavigationStack
        {
            ZStack
            {
                VStack(spacing: 20)
                {
                    // MARK: 編輯
                    //                HStack
                    //                {
                    //                    Spacer()
                    //                    NavigationLink(destination: MydataView(information: self.$information))
                    //                    {
                    //                        Text("編輯")
                    //                            .frame(maxWidth: .infinity, alignment: .trailing)
                    //                    }
                    //                    .transition(.opacity.animation(.easeInOut.speed(2)))
                    //                }
                    // MARK: 頭像
                    VStack(spacing: 20)
                    {
                        if let userImage=self.userImage,
                           let image=UIImage(data: userImage)
                        {
                            PhotosPicker(selection: self.$pickImage, matching: .any(of: [.images, .livePhotos]))
                            {
                                Circle()
                                    .fill(.gray)
                                    .scaledToFit()
                                    .frame(width: 160)
                                    .overlay
                                {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(Circle())
                                }
                            }
                            .onChange(of: self.pickImage)
                            {
                                image in
                                Task
                                {
                                    if let data=try? await image?.loadTransferable(type: Data.self)
                                    {
                                        self.userImage=data
                                    }
                                }
                            }
                        }else
                        {
                            PhotosPicker(selection: self.$pickImage, matching: .any(of: [.images, .livePhotos]))
                            {
                                Circle()
                                    .fill(.gray)
                                    .scaledToFit()
                                    .frame(width: 160)
                            }
                            .onChange(of: self.pickImage)
                            {
                                image in
                                Task
                                {
                                    if let data=try? await image?.loadTransferable(type: Data.self)
                                    {
                                        self.userImage=data
                                    }
                                }
                            }
                        }
                    }
                    
                    // MARK: 標籤
                    //                VStack(spacing: 20)
                    //                {
                    //                    HStack(spacing: 20)
                    //                    {
                    //                        ForEach(0..<3)
                    //                        {index in
                    //                            Capsule()
                    //                                .fill(Color("tagcolor"))
                    //                                .frame(width: 100, height: 30)
                    //                                .shadow(color: .gray, radius: 3, y: 3)
                    //                                .overlay(Text(self.tag[index]))
                    //                        }
                    //                    }
                    //
                    //                    HStack(spacing: 20)
                    //                    {
                    //                        ForEach(3..<5)
                    //                        {index in
                    //                            Capsule()
                    //                                .fill(Color("tagcolor"))
                    //                                .frame(width: 100, height: 30)
                    //                                .shadow(color: .gray, radius: 3, y: 3)
                    //                                .overlay(Text(self.tag[index]))
                    //                        }
                    //                    }
                    //                }
                    //MARK: 下方資訊(個人資訊＋設置)
                    List
                    {
                        Section(header:Text("個人資訊"))
                        {
                            // MARK: 用戶名稱
                            HStack
                            {
                                VStack
                                {
                                    Button(action:
                                            {
                                        isNameSheetPresented.toggle()
                                    }) {
                                        HStack
                                        {
                                            InformationLabel(image: "person.fill", label: "姓名")
                                            Text(self.user.name) //傳遞0或1作為參數，根據需要的索引
                                                .foregroundColor(.gray)
                                            
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle()) //可選：將按鈕樣式這是為普通按鈕
                                    .cornerRadius(8) //可選：添加圓角
                                }
                                .sheet(isPresented: $isNameSheetPresented) {
                                    NameSheetView(name: $user.name, isPresented: $isNameSheetPresented, realTime: realTime)
                                }
                                //                            NavigationLink(destination: MenuView())
                                //                            {
                                //                                InformationLabel(image: "person.fill", label: "用戶名稱")
                                //                            }
                            }
                            // MARK: 性別/生日
                            ForEach(1..<3, id: \.self)
                            {
                                index in
                                HStack
                                {
                                    self.label[index]
                                    Text(self.setInformation(index: index)).foregroundColor(.gray)
                                }
                                .frame(height: 30)
                            }
                        }
                        .listRowSeparator(.hidden)
                        
                        // MARK: 設定_內容
                        Section(header:Text("設置"))
                        {
                            // MARK: 過往食譜
                            HStack
                            {
                                NavigationLink(destination: MenuView()) {
                                    InformationLabel(image: "clock.arrow.circlepath", label: "過往食譜")
                                }
                            }
                            // MARK: 食材紀錄
                            HStack
                            {
                                NavigationLink(destination: StockView()) {
                                    InformationLabel(image: "doc.on.clipboard", label: "檢視庫存")
                                }
                            }
                            // MARK: 飲食偏好
                            HStack
                            {
                                NavigationLink(destination: MenuView()) {
                                    InformationLabel(image: "fork.knife", label: "飲食偏好")
                                }
                            }
                            // MARK: 我的最愛
                            HStack
                            {
                                NavigationLink(destination: FavoriteView()) {
                                    InformationLabel(image: "heart.fill", label: "我的最愛")
                                }
                            }
                            // MARK: 深淺模式
                            HStack
                            {
                                HStack
                                {
                                    Image(systemName: self.isDarkMode ? "moon.fill" : "sun.max.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                    
                                    Text(self.isDarkMode ? "  深色模式" : "   淺色模式")
                                        .bold()
                                        .font(.body)
                                        .alignmentGuide(.leading) { d in d[.leading] }
                                    
                                }
                                Toggle("", isOn: self.$colorScheme)
                                    .tint(Color("sidebuttomcolor"))
                                    .scaleEffect(0.75)
                                    .offset(x: 30)
                            }
                            // MARK: 登出
                            Button(action:
                                    {
                                withAnimation(.easeInOut)
                                {
                                    self.signin = false
                                }
                            }) {
                                HStack
                                {
                                    Image(systemName: "power")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25, height: 25)
                                        .offset(x: 2)
                                    
                                    Text("    登出")
                                        .bold()
                                        .font(.body)
                                        .alignmentGuide(.leading)
                                    {
                                        d in d[.leading]
                                    }
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .listStyle(InsetListStyle())
                    .preferredColorScheme(self.colorScheme ? .light:.dark) //控制深淺模式切換
                    .onChange(of: self.colorScheme)
                    {
                        newValue in
                        self.isDarkMode = !self.colorScheme
                    }
                    .onAppear {
                        // MARK: 從 RealTime 獲取用戶信息
                        realTime.getUser(account: "用户的帳號") { userInfo, error in
                            if let userInfo = userInfo {
                                //更新 MyView 中的用戶信息
                                self.user.name = userInfo[3]
                                self.user.gender=userInfo[4]
                                self.user.birthday=userInfo[5] //請根據實際情況修改索引
                                // MARK: 更新其他用戶信息，根據需要
                            } else if let error = error {
                                print("Error getting user information: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct NameSheetView: View 
{
    @Binding var name: String
    @Binding var isPresented: Bool
    
    @State private var newName = ""
    
    var realTime: RealTime //添加 RealTime 屬性

    var body: some View 
    {
        NavigationStack 
        {
            Form 
            {
                Section(header: Text("更改姓名")) 
                {
                    TextField("新的姓名", text: $newName)
                }
            }
            .navigationBarItems(
                leading: Button("取消") 
                {
                    isPresented = false
                },
                trailing: Button("保存") 
                {
                    //保存新的姓名到 RealTime，並刪除舊信息
                    realTime.updateUserNameAndDelete(id:"", name: newName)
                    {
                        self.name=self.newName
                    }
                }
            )
        }
    }
}

//struct NameSheetView: View
//{
//    @Binding var name: String
//    @Binding var isPresented: Bool
//    @State private var newName = ""
//
//    var body: some View
//    {
//        NavigationStack
//        {
//            Form
//            {
//                Section(header: Text("更改姓名"))
//                {
//                    TextField("新的姓名", text: $newName)
//                }
//            }
//            .navigationBarItems(
//                leading: Button("取消")
//                {
//                    isPresented = false
//                },
//                trailing: Button("保存")
//                {
//                    name = newName
//                    isPresented = false
//                }
//            )
//        }
//    }
//}

struct MyView_Previews: PreviewProvider
{
    static var previews: some View
    {
        NavigationStack
        {
            MyView(
                select: .constant(2)
            )
        }
    }
}

