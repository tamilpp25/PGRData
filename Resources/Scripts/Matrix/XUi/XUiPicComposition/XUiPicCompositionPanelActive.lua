XUiPicCompositionPanelActive = XClass(nil, "XUiPicCompositionPanelActive")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPicCompositionPanelActive:Ctor(ui,rootUi,index,parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.rootUi = rootUi
    self.Parent = parent
    self.index = index
    XTool.InitUiObject(self)
    self.BtnActive.CallBack = function() self:OnBtnActiveClick() end
end

function XUiPicCompositionPanelActive:Refresh()

end

function XUiPicCompositionPanelActive:UpdateActiveness(dailyActiveness,dActiveness)
    if dailyActiveness <= dActiveness then
        self.rootUi:SetUiSprite(self.BtnActive.image, CS.XGame.ClientConfig:GetString("TaskDailyActiveReach"..self.index))
        self.PanelEffect.gameObject:SetActiveEx(not XDataCenter.MarketingActivityManager.IsGetedScheduleReward(self.index))
        self.ImgRe.gameObject:SetActiveEx(XDataCenter.MarketingActivityManager.IsGetedScheduleReward(self.index))
    else
        self.rootUi:SetUiSprite(self.BtnActive.image, CS.XGame.ClientConfig:GetString("TaskDailyActiveNotReach"..self.index))
        self.PanelEffect.gameObject:SetActiveEx(false)
        self.ImgRe.gameObject:SetActiveEx(false)
    end

    self.TxtValue.text = dailyActiveness
end

function XUiPicCompositionPanelActive:OnBtnActiveClick()
    self:TouchDailyRewardBtn(self.index)
end

function XUiPicCompositionPanelActive:TouchDailyRewardBtn(index)
    local curActiveness = XDataCenter.ItemManager.GetCount(self.Parent.Parent.TaskItem)
    local ActivenesDatas = XMarketingActivityConfigs.GetPicCompositionScheduleRewardInfoConfigs()
    -- local ActivenesTotal = XMarketingActivityConfigs.GetPicCompositionScheduleRewardTotal()
    local data = XRewardManager.GetRewardList(ActivenesDatas[index].RewardId)

    if curActiveness >= ActivenesDatas[index].Schedule then
        if XDataCenter.MarketingActivityManager.IsGetedScheduleReward(ActivenesDatas[index].Id) then
            return
        end
        XDataCenter.MarketingActivityManager.GetCommentScheduleReward(ActivenesDatas[index].Id,function ()
            self.Parent:UpdateActiveness()
        end)
    else
        XUiManager.OpenUiTipReward(data, CSTextManagerGetText("DailyActiveRewardTitle"))
    end

end

return XUiPicCompositionPanelActive