local XUiGridBossReward = XClass(nil, "XUiGridBossReward")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridBossReward:Ctor(ui,base,areaId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.AreaId = areaId
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
end

function XUiGridBossReward:SetButtonCallBack()
    self.BtnActive.CallBack = function()
        self:OnBtnActiveClick()
    end
end


function XUiGridBossReward:OnBtnActiveClick()
    local rewardData = XRewardManager.GetRewardList(self.Data:GetRewardId())
    if self.Data:GetIsCanGet() then
        if self.Data:GetIsGeted() then
            return
        end
        if not self.AreaId then
            return
        end
        XDataCenter.WorldBossManager.GetBossPhasesReward(self.AreaId, self.Data:GetId(),function ()
                self.Base:UpdatePanelPhasesReward()
            end)
    else
        XUiManager.OpenUiTipReward(rewardData, CSTextManagerGetText("DailyActiveRewardTitle"))
    end
end

function XUiGridBossReward:UpdateData(data)
    self.Data = data
    if data then
        if data:GetIsCanGet() then
            self.ImgActive:SetSprite(CS.XGame.ClientConfig:GetString("TaskDailyActiveReach1"))
            self.PanelEffect.gameObject:SetActiveEx(not data:GetIsGeted())
            self.ImgRe.gameObject:SetActiveEx(data:GetIsGeted())
        else
            self.ImgActive:SetSprite(CS.XGame.ClientConfig:GetString("TaskDailyActiveNotReach1"))
            self.PanelEffect.gameObject:SetActiveEx(false)
            self.ImgRe.gameObject:SetActiveEx(false)
        end
        local hpPercent = data:GetHpPercent()
        self.ScheduleCount.text = string.format("%d%s",hpPercent,"%")
    end
end

return XUiGridBossReward