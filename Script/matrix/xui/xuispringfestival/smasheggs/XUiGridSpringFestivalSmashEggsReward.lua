local XUiGridSpringFestivalSmashEggsReward = XClass(nil, "XUiGridSpringFestivalSmashEggsReward")

function XUiGridSpringFestivalSmashEggsReward:Ctor(ui, callback)
    self.GameObject = ui
    self.Transform = ui.transform
    self.Callback = callback
    XTool.InitUiObject(self)
    self.BtnActive.CallBack = function()
        self:OnClickBtnActive()
    end
end

function XUiGridSpringFestivalSmashEggsReward:Refresh(data)
    if not data then
        return
    end
    self.Index = data.Index
    self.TargetScore = data.TargetScore
    self.IsReceive = XDataCenter.SpringFestivalActivityManager.CheckRewardIsReceive(self.Index)
    self.ImgRe.gameObject:SetActiveEx(self.IsReceive)
    if not self.IsReceive then
        local todayScore = XDataCenter.SpringFestivalActivityManager.GetSmashEggsTodayScore()
        if self.PanelEffect then
            self.PanelEffect.gameObject:SetActiveEx(data.TargetScore <= todayScore)
        end
    else
        if self.PanelEffect then
            self.PanelEffect.gameObject:SetActiveEx(false)
        end
    end
    if self.TargetScore and self.TxtValue then
        self.TxtValue.text = self.TargetScore
    end
    local day = XDataCenter.SpringFestivalActivityManager.GetSmashEggsActivityDay()
    local rewards = XRewardManager.GetRewardList(XSpringFestivalActivityConfigs.GetSmashEggsRewardRewardId(day,self.Index))

    if #rewards > 0 then
        local reward = rewards[1]
        if self.TxtNumber then
            self.TxtNumber.text = reward.Count
        end
        if self.RImgIcon then
            local icon = XGoodsCommonManager.GetGoodsIcon(reward.TemplateId)
            if icon then
                self.RImgIcon:SetRawImage(icon)
            end
        end
    end
end

function XUiGridSpringFestivalSmashEggsReward:OnClickBtnActive()
    if self.IsReceive then
        XUiManager.TipText("SpringFestivalHasGetReward")
        return
    end
    if XDataCenter.SpringFestivalActivityManager.GetSmashEggsTodayScore() < self.TargetScore then
        local day = XDataCenter.SpringFestivalActivityManager.GetSmashEggsActivityDay()
        local rewards = XRewardManager.GetRewardList(XSpringFestivalActivityConfigs.GetSmashEggsRewardRewardId(day,self.Index))
        XUiManager.OpenUiTipReward(rewards)
        return 
    end
    
    XDataCenter.SpringFestivalActivityManager.SmashEggsGetActivationDailyRewardRequest(self.Index, function(rewards)
        if not rewards or #rewards == 0 then
            return
        end
        XUiManager.OpenUiTipReward(rewards,CS.XTextManager.GetText("SpringFestivalGetRewardTitle"))
        if self.Callback then
            self.Callback()
        end
    end)
end

return XUiGridSpringFestivalSmashEggsReward