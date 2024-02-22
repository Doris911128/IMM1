//
//  MenuView.swift暫時沒問題檔
//  StickyHeaderExample
//
//  Created by 曾品瑞 on 2023/12/11.
//

import SwiftUI

struct MenuView: View
{
    // MARK: 封面畫面
    @ViewBuilder
    private func CoverView(safeArea: EdgeInsets, size: CGSize) -> some View
    {
        let height: CGFloat=size.height*0.5
        
        GeometryReader
        {reader in
            let minY: CGFloat=reader.frame(in: .named("SCROLL")).minY //ScrollView的最小Y值
            let size: CGSize=reader.size //當前畫面的大小
            let progress: CGFloat=minY/(height*(minY>0 ? 0.5:0.8)) //滑動狀態的數值
            
            Image(.泡麵)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height+(minY>0 ? minY:0)) //圖片根據size及minY改變長度
                .clipped()
                .overlay
            {
                ZStack(alignment: .bottom)
                {
                    Rectangle()
                        .fill(
                            .linearGradient( //根據progress值改變覆蓋在圖片上的陰影
                                colors: [
                                    Color("menusheetbackgroundcolor").opacity(0-progress),
                                    Color("menusheetbackgroundcolor").opacity(0.2-progress),
                                    Color("menusheetbackgroundcolor").opacity(0.4-progress),
                                    Color("menusheetbackgroundcolor").opacity(0.6-progress),
                                    Color("menusheetbackgroundcolor").opacity(0.8-progress),
                                    Color("menusheetbackgroundcolor")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                                           )
                        )
                    
                    VStack(spacing: 0)
                    {
                        // MARK: 滑動前顯示的料理名稱
                        Text("料理名稱")
                            .bold()
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        
                        HStack(spacing: 5)
                        {
                            Image(systemName: "timer")
                            Text("時間：")
                            Text("一輩子")
                        }
                        .bold()
                        .font(.body)
                        .foregroundStyle(.gray)
                        .padding(.top)
                    }
                    .opacity(1.1+(progress>0 ? -progress:progress)) //利用progress的數值變化改變透明度 1.1會讓標題在HeaderView的位置消失
                    .padding(.bottom, 50)
                    .offset(y: minY<0 ? minY:0)
                }
            }
            .offset(y: -minY) //往上滑動的時候 圖片及陰影也要跟著往上滑動
            // MARK: CoverView的progress
            .onChange(of: progress)
            {
                print("CoverView的progress值: \(progress)")
            }
        }
        .frame(height: height+safeArea.top)
    }
    // MARK: 標題畫面
    @ViewBuilder
    private func HeaderView(size: CGSize) -> some View
    {
        GeometryReader
        {reader in
            let minY: CGFloat=reader.frame(in: .named("SCROLL")).minY //ScrollView的最小Y值
            let height: CGFloat=size.height*0.5
            let progress: CGFloat=minY/(height*(minY>0 ? 0.5:0.8)) //滑動狀態的數值
            
            HStack(spacing: 20)
            {
                if(progress > 6 ) //在 HeaderView 的 ViewBuilder 中
                {
                    Spacer(minLength: 0)
                }
                else // 利用progress的數值變化改變透明度 15會讓專輯標題在HeaderView的位置时 出现以下内容
                {
                    Spacer(minLength: 0)
                    // MARK: 滑動後顯示的料理名稱
                    Text("料理名稱")
                        .bold()
                        .font(.title3)
                        .transition(.opacity.animation(.smooth))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                    
                    Spacer(minLength: 0)
                }
            }
            .foregroundStyle(.orange) //控制最愛追蹤按鈕的顏色
            .padding()
            .background(Color("menusheetbackgroundcolor").opacity(progress > 6 ? 0 : 1)) //利用progress的數值變化改變透明度 11會讓專輯標題在HeaderView的位置時 出現背景顏色
            .animation(.smooth.speed(2), value: progress<6)
            .offset(y: -minY)
            // MARK: HeaderView的progress
            .onChange(of: progress)
            {
                print("HeaderView的progress值: \(progress)")
            }
        }
    }
    
    // MARK: 烹飪書畫面
    @ViewBuilder
    private func CookbookView(safeArea: EdgeInsets) -> some View
    {
        VStack(spacing: 20)
        {
            Text("所需食材")
                .foregroundStyle(.orange)
                .font(.title2)
                .offset(x:-130)
            Text("在遙遠的未來，科技的進步達到了前所未有的高度。人類已經探索了遠至外太空，建立了一個巨大的宇宙帝國。然而，儘管科技的進步，人類的內心世界卻仍然充滿了謎團和未知。")
            
            Text("在這個時代，一個名為“心靈網絡”的技術被發明出來。這是一種能夠讓人們直接共享思想和情感的技術。通過這個網絡，人們可以深入了解彼此，消除誤解，建立更加緊密的關係。")
            Text("料理方法")
                .foregroundStyle(.orange)
                .font(.title2)
                .offset(x:-130)
            Text("然而，隨著心靈網絡的普及，也帶來了一系列的問題。某些人開始濫用這項技術，入侵他人的隱私，甚至控制他人的思想。社會分裂，人與人之間的信任逐漸崩潰。")
            
            Text("在這個動盪不安的時代，一群年輕的反抗者站了出來。他們被稱為“自由騎士”，試圖對抗那些濫用心靈網絡的勢力。他們的目標是恢復人類的自由和尊嚴，保護每個人的思想和情感不受侵犯。")
            Text("影片教學")
                .foregroundStyle(.orange)
                .font(.title2)
                .offset(x:-130)
            Text("隨著時間的推移，自由騎士們遭遇了無數的挑戰和困難。他們必須面對強大的敵人，經歷艱難的戰鬥。但是，他們從未放棄，因為他們深知，這場戰鬥關乎的不僅僅是他們自己，還有整個人類的未來。")
            
            Text("最終，經過多年的努力和犧牲，自由騎士們終於取得了勝利。他們成功地阻止了那些濫用心靈網絡的勢力，恢復了社會的和諧與穩定。人們重新找回了對彼此的信任和理解，建立了一個更加美好的未來。")
            
            Text("然而，這個故事並沒有結束。因為人類的冒險和探索永遠不會停止。在這個無盡的宇宙中，新的挑戰和冒險正等待著人類去探索和發現。而自由騎士們，將繼續守護這個美麗的星球，保護每一個人的夢想和希望。")
        }
    }
    
    var body: some View
    {
        GeometryReader
        {
            let safeArea: EdgeInsets=$0.safeAreaInsets //當前畫面的safeArea
            let size: CGSize=$0.size //GeometryReader的大小
            
            ScrollView(.vertical, showsIndicators: false)
            {
                VStack
                {
                    // MARK: CoverView
                    self.CoverView(safeArea: safeArea, size: size)
                    
                    // MARK: CookbookView
                    self.CookbookView(safeArea: safeArea).padding(.top)
                    
                    // MARK: HeaderView
                    self.HeaderView(size: size)
                }
            }
            .coordinateSpace(name: "SCROLL") //抓取ScrollView的各項數值
        }
        .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)
        .toolbar
        {
            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button(action: {
                    //您的操作代碼在這裡
                }) {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundStyle(.orange) //設定愛心為橘色
                    
                }
                .animation(.none) //移除這行如果不需要動畫
            }
        }
    }
}
#Preview {
    MenuView()
}
