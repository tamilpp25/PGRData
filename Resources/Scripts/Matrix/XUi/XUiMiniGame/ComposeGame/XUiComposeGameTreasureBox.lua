-- 组合小游戏进度宝箱控件
local XUiComposeGameTreasureBox = XClass(nil, "XUiComposeGameTreasureBox")
--================
--构造函数
--@param ui:星级面板GameObject
--@gameId gameId:小游戏GameId ComposeGame表ID
--================
function XUiComposeGameTreasureBox:Ctor(ui, gameId)
    self.GameId = gameId
    XTool.InitUiObjectByUi(self, ui)
    self:InitUIs()
end
--================
--初始化UI的基础组件
--================
function XUiComposeGameTreasureBox:InitUIs()
    self.ImgReceived.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
    self.BtnTreasureBox.CallBack = function() self:OnClick() end
end
--================
--更新控件数据
--@param treasureBox:进度宝箱数据
--================
function XUiComposeGameTreasureBox:RefreshData(treasureBox)
    self.Box = treasureBox
    self.TxtValue.text = self.Box:GetSchedule()
    self:SetIsReceive()
    self:SetCanReceive()
end
--================
--设置已领取UI状态
--================
function XUiComposeGameTreasureBox:SetIsReceive()
    self.ImgReceived.gameObject:SetActiveEx(self.Box:CheckIsReceive())
end
--================
--设置宝箱领取状态UI
--================
function XUiComposeGameTreasureBox:SetCanReceive()
    self.PanelEffect.gameObject:SetActiveEx(self.Box:CheckCanReceive())
end
--================
--点击事件
--================
function XUiComposeGameTreasureBox:OnClick()
    if not self.Box then return end
    if self.Box:CheckCanReceive() then
        XDataCenter.ComposeGameManager.GetReward(self.GameId, self.Box)
    else
        local rewardId = self.Box:GetRewardId()
        if rewardId and rewardId > 0 then
            local data = XRewardManager.GetRewardList(rewardId)
            if not data then return end
            XUiManager.OpenUiTipReward(data)
        end
    end
end

return XUiComposeGameTreasureBox