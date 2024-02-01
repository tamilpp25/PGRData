---@class XUiTaskPanelActive
XUiPanelActive = XClass(nil, "XUiPanelActive")

function XUiPanelActive:Ctor(ui, rootUi, index, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.rootUi = rootUi
    self.Parent = parent
    self.index = index
    XTool.InitUiObject(self)
    self.BtnActive.CallBack = function() self:OnBtnActiveClick() end
end

function XUiPanelActive:Refresh()

end

function XUiPanelActive:UpdateActiveness(dailyActiveness, dActiveness)
    if dailyActiveness <= dActiveness then
        self.rootUi:SetUiSprite(self.BtnActive.image, CS.XGame.ClientConfig:GetString("TaskDailyActiveReach" .. self.index))
        self.PanelEffect.gameObject:SetActive(not XPlayer.IsGetDailyActivenessReward(self.index))
        self.ImgRe.gameObject:SetActive(XPlayer.IsGetDailyActivenessReward(self.index))
    else
        self.rootUi:SetUiSprite(self.BtnActive.image, CS.XGame.ClientConfig:GetString("TaskDailyActiveNotReach" .. self.index))
        self.PanelEffect.gameObject:SetActive(false)
        self.ImgRe.gameObject:SetActive(false)
    end

    self.TxtValue.text = dailyActiveness
end

function XUiPanelActive:OnBtnActiveClick()
    self:TouchDailyRewardBtn(self.index)
end

function XUiPanelActive:TouchDailyRewardBtn(index)
    local activeness = XDataCenter.ItemManager.GetDailyActiveness().Count
    local dActiveness = XTaskConfig.GetDailyActiveness()
    local rewardIds = XTaskConfig.GetDailyActivenessRewardIds()
    local data = XRewardManager.GetRewardList(rewardIds[index])
    -- 如果已经领取过了和没有达到目标的，直接弹奖励提示
    if XPlayer.IsGetDailyActivenessReward(index) or activeness < dActiveness[index] then
        XUiManager.OpenUiTipReward(data, CS.XTextManager.GetText("DailyActiveRewardTitle"))
        return
    end

    -- v1.31 【任务日常活跃】一键领取
    XDataCenter.TaskManager.GetActivenessReward(XDataCenter.TaskManager.ActiveRewardType.Daily, function()
        self.Parent:UpdateActiveness()
    end)
end

return XUiPanelActive