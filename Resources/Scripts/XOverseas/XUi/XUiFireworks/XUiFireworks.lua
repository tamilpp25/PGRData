local XUiFireworks = XClass(nil, "XUiFireworks")
local CSScheduleMng = CS.XScheduleManager

function XUiFireworks:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:InitAddListen()
end

function XUiFireworks:OnHide()
    self:Clear()
end

function XUiFireworks:OnShow()

end

function XUiFireworks:Clear()
    if self.AnimationSchedule ~= nil then
        CSScheduleMng.UnSchedule(self.AnimationSchedule)
        self.AnimationSchedule = nil
    end
    for i = 1, 3 do
        self.EffectAList[i]:SetActiveEx(false)
        self.EffectBList[i]:SetActiveEx(false)
    end
end

function XUiFireworks:InitAddListen()
    self.EffectAList = {}
    self.EffectBList = {}
    for i = 1, 3 do
        self.EffectAList[i] = self.Transform:Find("PanelRound1/EffectA" .. i).gameObject
        self.EffectBList[i] = self.Transform:Find("PanelRound1/EffectB" .. i).gameObject
    end
    self.BtnTab.CallBack = function() self:OnDrawClick() end
    self.BtnHelp.CallBack = function() XLuaUiManager.Open("UiFireworksLog") end
end

function XUiFireworks:OnDrawClick()
    if not XDataCenter.FireworksManager.IsPlayerQualified() then
        XUiManager.TipText("EnKrFireworksLeveldonotenough")
        return
    end
    self:Clear()
    self.BtnTab.gameObject:SetActiveEx(false)
    XDataCenter.FireworksManager.OnFire(function(success, res)
        if not success then
            XUiManager.TipCode(res.Code)
            return
        end

        local rewardList = res.RewardGoodsList
        local dropId = res.DropId
        local effectId = XDataCenter.FireworksManager.GetEffectIdByDropId(dropId)

        if effectId == nil or effectId <= 0 or effectId > 3 then
            XLog.Error("Firework Effect Id doesn't exist")
            XLuaUiManager.Open("UiObtain", rewardList)
            return
        end

        self.EffectAList[effectId]:SetActiveEx(true)
        XLuaUiManager.SetAnimationMask("Firework", true)
        self.AnimationSchedule = CSScheduleMng.ScheduleOnce(function()
            self.EffectAList[effectId]:SetActiveEx(false)
            XLuaUiManager.SetAnimationMask("Firework", false)
            local function playEffectB()
                self.EffectBList[effectId]:SetActiveEx(true)
            end
            XLuaUiManager.Open("UiObtain", rewardList, nil, playEffectB, playEffectB)
            XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)

            if XDataCenter.FireworksManager.HasAvailableFireTimes() then
                self.BtnTab.gameObject:SetActiveEx(true)
            end
        end, 1800)
    end)
end

function XUiFireworks:Refresh(configId)
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
    for i = 1, 3 do
        self.EffectAList[i]:SetActiveEx(false)
        self.EffectBList[i]:SetActiveEx(false)
    end
    if XDataCenter.FireworksManager.HasAvailableFireTimes() then
        self.BtnTab.gameObject:SetActiveEx(true)
    else
        self.BtnTab.gameObject:SetActiveEx(false)
        self:PlayLastFirework()
    end
end

function XUiFireworks:PlayLastFirework()
    local lastId = XDataCenter.FireworksManager.GetLastRecordType()
    if lastId == nil then
        return
    end
    self.EffectBList[lastId]:SetActiveEx(true)
end

return XUiFireworks