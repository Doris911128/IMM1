//  DynamicView.swift
//  GP110IM
//
//  Created by 朝陽資管 on 2023/10/27.

// MARK: 動態View（BMI 血壓 BP 血糖 BS 血脂 BL）
import SwiftUI
import Charts

struct DynamicView: View {
    enum DynamicRecordType: CaseIterable {
        case BMI, hypertension, hyperglycemia, hyperlipidemia
    }
    
    @State private var selectedRecord: DynamicRecordType = .BMI
    @GestureState private var dragOffset: CGSize = .zero
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer(minLength: 44)
            // 按鈕選擇器
            HStack(spacing: 0) {
                recordButton(.BMI, title: "BMI")
                recordButton(.hypertension, title: "血壓")
                recordButton(.hyperglycemia, title: "血糖")
                recordButton(.hyperlipidemia, title: "血脂")
            }
            .frame(maxWidth: .infinity, maxHeight: 50)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: 360, height: 38)
            )
            .padding(.horizontal, 15)
            
            Spacer()
            
            // 使用 ZStack 進行視圖切換
            ZStack {
                switch selectedRecord {
                case .BMI:
                    BMIView()
                case .hypertension:
                    HypertensionView()
                case .hyperglycemia:
                    HyperglycemiaView()
                case .hyperlipidemia:
                    HyperlipidemiaView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(colorScheme == .dark ? Color.black : Color.white)
            .offset(x: dragOffset.width) // 追蹤拖動中的位移
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation // 追蹤手勢拖動的距離
                    }
                    .onEnded { value in
                        // 判斷滑動方向
                        if value.translation.width < -100 {
                            withAnimation(.easeInOut) {
                                switchToNextRecord()
                            }
                        } else if value.translation.width > 100 {
                            withAnimation(.easeInOut) {
                                switchToPreviousRecord()
                            }
                        }
                    }
            )
        }.onTapGesture {
            dismissKeyboard()
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    // 自定義按鈕
    func recordButton(_ type: DynamicRecordType, title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedRecord == type ? Color.orange : Color.clear)
            )
            .foregroundColor(selectedRecord == type ? .black : .gray)
        
            .onTapGesture {
                withAnimation {
                    selectedRecord = type
                }
            }
            .padding(.horizontal, 0)
    }
    
    // 切換到下一個記錄
    func switchToNextRecord() {
        if let currentIndex = DynamicRecordType.allCases.firstIndex(of: selectedRecord),
           currentIndex < DynamicRecordType.allCases.count - 1 {
            selectedRecord = DynamicRecordType.allCases[currentIndex + 1]
        }
    }
    
    // 切換到上一個記錄
    func switchToPreviousRecord() {
        if let currentIndex = DynamicRecordType.allCases.firstIndex(of: selectedRecord),
           currentIndex > 0 {
            selectedRecord = DynamicRecordType.allCases[currentIndex - 1]
        }
    }
}


struct DynamicView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicView()
    }
}
