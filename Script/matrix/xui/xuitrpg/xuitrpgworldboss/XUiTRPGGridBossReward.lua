local XUiTRPGGridBossReward = XClass(nil, "XUiTRPGGridBossReward")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiTRPGGridBossReward:Ctor(ui, updatePanelPhasesRewardCb, id)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UpdatePanelPhasesRewardCb = updatePanelPhasesRewardCb
    self.Id = id
    XTool.InitUiObject(self)

    self:Init()
    self:SetButtonCallBack()
end

function XUiTRPGGridBossReward:Init()
    local icon = XTRPGConfigs.GetBossIcon(self.Id)
    self.ImgActive:SetRawImage(icon)
end

function XUiTRPGGridBossReward:SetButtonCallBack()
    self.BtnActive.CallBack = function()
        self:OnBtnActiveClick()
    end
end

function XUiTRPGGridBossReward:OnBtnActiveClick()
    local rewardId = XTRPGConfigs.GetBossPhasesRewardId(self.Id)
    local isAleardyReceive = XDataCenter.TRPGManager.IsWorldBossAleardyReceiveReward(self.Id)
    local isCanReceive = XDataCenter.TRPGManager.IsWorldBossCanReceiveReward(self.Id)
    local rewardData = XRewardManager.GetRewardList(rewardId)

    if isCanReceive then
        if isAleardyReceive then
            return
        end
        XDataCenter.TRPGManager.RequestTRPGBossPhasesRewardSend(self.Id, function()
            if self.UpdatePanelPhasesRewardCb then
                self.UpdatePanelPhasesRewardCb()
            end
        end)
    else
        XUiManager.OpenUiTipReward(rewardData, CSTextManagerGetText("DailyActiveRewardTitle"))
    end
end

function XUiTRPGGridBossReward:UpdateData()
    local isAleardyReceive = XDataCenter.TRPGManager.IsWorldBossAleardyReceiveReward(self.Id)
    local isCanReceive = XDataCenter.TRPGManager.IsWorldBossCanReceiveReward(self.Id)
    if isCanReceive then
        self.PanelEffect.gameObject:SetActiveEx(not isAleardyReceive)
        self.ImgRe.gameObject:SetActiveEx(isAleardyReceive)
    else
        self.PanelEffect.gameObject:SetActiveEx(false)
        self.ImgRe.gameObject:SetActiveEx(false)
    end

    local hpPercent = XTRPGConfigs.GetBossPhasesRewardPercent(self.Id)
    self.ScheduleCount.text = string.format("%d%s", hpPercent, "%")
end

return XUiTRPGGridBossReward