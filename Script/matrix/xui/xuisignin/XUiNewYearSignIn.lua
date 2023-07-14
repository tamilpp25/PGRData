local XUiNewYearSignIn = XClass(nil, "XUiNewYearSignIn")

function XUiNewYearSignIn:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:InitAddListen()
    self.PanelEffectZhanBu.gameObject:SetActiveEx(false)
    self.RewardPanelList = {}
end

function XUiNewYearSignIn:InitAddListen()
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
    self.BtnDivining.CallBack = function()
        self:OnBtnDiviningClick()
    end
end

function XUiNewYearSignIn:Refresh(signId, isShow)
    self.SignId = signId or self.SignId
    local todayDiviningState = XDataCenter.SignInManager.GetTodayDiviningState()
    --self.PanelEffectZhanBu.gameObject:SetActiveEx(false)

    if not todayDiviningState then
        self.PanelDiviningGroup.gameObject:SetActiveEx(true)
        self.PanelDiviningSignGroup.gameObject:SetActiveEx(false)
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
        return
    end

    self.PanelEffectGet.gameObject:SetActiveEx(true)
    self.PanelDiviningGroup.gameObject:SetActiveEx(false)
    self.PanelDiviningSignGroup.gameObject:SetActiveEx(true)
    local todayRewardData = XDataCenter.SignInManager.GetDiviningTodayData()
    local rewardConfig = XSignInConfigs.GetDiviningSignRewardConfig(todayRewardData.DailyLotteryRewardId)
    self.TxtSign.text = rewardConfig.RewardText
    self.TxtSign.text = string.gsub(self.TxtSign.text, "\\n", "\n")

    if rewardConfig.RewardSignPath then
        self.ImgSign:SetRawImage(rewardConfig.RewardSignPath)
    else
        self.ImgSign.gameObject:SetActiveEx(false)
    end

    self.TxtAward.text = CS.XTextManager.GetText("DiviningRewardsText")

    --显示奖励
    local rewards = XRewardManager.GetRewardList(rewardConfig.RewardId)
    if not rewards then
        return
    end

    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        if not panel then
            if #self.RewardPanelList == 0 then
                panel = XUiGridCommon.New(self.RootUi, self.GridItem)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridItem)
                ui.transform:SetParent(self.PanelAwardContent, false)
                panel = XUiGridCommon.New(self.RootUi, ui)
            end
            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(rewards[i])
    end

    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

function XUiNewYearSignIn:OnBtnHelpClick()
    XLuaUiManager.Open("UiDiviningLog", self.SignId)
end

function XUiNewYearSignIn:OnBtnDiviningClick()
    local id = XDataCenter.SignInManager.GetDiviningActivityId() or self.SignId
    XDataCenter.SignInManager.RequestNewYearDivining(id, function()
            self.PanelEffectZhanBu.gameObject:SetActiveEx(false)
            self.PanelEffectZhanBu.gameObject:SetActiveEx(true)
            self.PanelAnimationZhanBu.gameObject:SetActiveEx(true)
            self.DrawTipTimeId = CS.XScheduleManager.ScheduleOnce(function ()
                    if self.PanelAnimationZhanBu:Exist() then
                        self.PanelAnimationZhanBu.gameObject:SetActiveEx(false)
                    end
                    if self.PanelEffectZhanBu:Exist() then
                        self.PanelEffectZhanBu.gameObject:SetActiveEx(false)
                    end
                end, 2000)
            self:Refresh()
        end)
end

function XUiNewYearSignIn:OnShow()
    XEventManager.AddEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.ForceUpdate, self)
end

function XUiNewYearSignIn:ForceUpdate()
    if self.SignId then
        self:Refresh(self.SignId)
    end
end

function XUiNewYearSignIn:OnHide()
    if self.DrawTipTimeId then
        CS.XScheduleManager.UnSchedule(self.DrawTipTimeId)
        self.DrawTipTimeId = nil
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN, self.ForceUpdate, self)
end

return XUiNewYearSignIn