local XUiSignGridDay = XClass(nil, "XUiSignGridDay")

function XUiSignGridDay:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Grid = nil

    XTool.InitUiObject(self)
    self:InitComponent()
    self:InitAddListen()
end

function XUiSignGridDay:InitComponent()
    self.PanelNext.gameObject:SetActiveEx(false)
end

function XUiSignGridDay:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiSignGridDay:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiSignGridDay:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiSignGridDay:InitAddListen()
    if not self.BtnCard then return end
    self:RegisterClickEvent(self.BtnCard, self.OnBtnCardClick)
end

function XUiSignGridDay:OnBtnCardClick()
    XDataCenter.AutoWindowManager.StopAutoWindow()
    XDataCenter.PurchaseManager.OpenYKPackageBuyUi()
    -- XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.YK, false)
end

---
--- 福利界面打开时'isShow'为false:不领取奖励、设置明日奖励标识
--- 打脸时为true:领取奖励、不设置明日奖励标识(领取奖励之后再利用'forceSetTomorrow'来设置明日奖励标识)
---
--- 打脸时设置对应的奖励的'forceSetTomorrow'为true，设置明日奖励标识
function XUiSignGridDay:Refresh(config, isShow, forceSetTomorrow)
    self.IsShow = isShow
    self.Config = config
    self.ForceSetTomorrow = forceSetTomorrow

    self.TxtDay.text = string.format("%02d", config.Pre)
    if not isShow or forceSetTomorrow then
        self:SetTomorrow()
    end

    local isAlreadyGet = XDataCenter.SignInManager.JudgeAlreadyGet(config.SignId, config.Round, config.Day)
    self.PanelHaveGroup.alpha = isAlreadyGet and 1 or 0
    self.PanelHaveReceive.gameObject:SetActiveEx(isAlreadyGet)
    self:SetEffectActive(false)

    local rewardList = XRewardManager.GetRewardList(config.ShowRewardId)
    if not rewardList or #rewardList <= 0 then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
        return
    end

    if not self.Grid then
        self.Grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
    end

    self:SetCardInfo(isAlreadyGet)
    self.Grid:Refresh(rewardList[1])
    self.GameObject:SetActiveEx(true)
    self:AnimaStart()
end

---
--- 设置明日奖励标识
function XUiSignGridDay:SetTomorrow()
    local isTomorrow = XDataCenter.SignInManager.JudgeTomorrow(self.Config.SignId, self.Config.Round, self.Config.Day)
    self.PanelNext.gameObject:SetActiveEx(isTomorrow)
end

---
--- 检测是否领取奖励
--- 如果当前是今日奖励，并且已领取，则派发事件，然后开启打脸界面的关闭按钮，并设置明日奖励标识
function XUiSignGridDay:AnimaStart()
    if not self.IsShow then
        return
    end

    local isToday, isGet = XDataCenter.SignInManager.JudgeTodayGet(self.Config.SignId, self.Config.Round, self.Config.Day)
    if not isToday then
        return
    end

    -- 已经领取奖励，派发事件
    -- XUiSignPrefab:SetTomorrowOpen()不会进入v:SetTomorrow()，因为后面的奖励格子还未初始化
    -- 但是XUiSignPrefab的self.SetTomorrow被设置为true(forceSetTomorrow)，所以后面格子的初始化刷新会进行明日奖励的设置
    if isToday and isGet then
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true, self.Config)
        return
    end

    -- 还未领取奖励，将会在签到动画播放完后才派发事件
    -- 这时候奖励格子已经全部初始化完成，会进入XUiSignPrefab:SetTomorrowOpen()的v:SetTomorrow()
    self:SetEffectActive(true)
    XDataCenter.SignInManager.SignInRequest(self.Config.SignId, function(rewardItems)
        self:GetYK(rewardItems)
    end,
    function()
        self:GetYK()
    end)
end

function XUiSignGridDay:SetEffectActive(active)
    self.PanelEffect.gameObject:SetActiveEx(active)
end

-- 设置月卡信息
function XUiSignGridDay:SetCardInfo()
    if not self.BtnCard then return end

    
    local isAlreadyGet = XDataCenter.SignInManager.JudgeAlreadyGet(self.Config.SignId, self.Config.Round, self.Config.Day)
    local isGot = true
    local remainDay = -1
    local ykData = XDataCenter.PurchaseManager.GetYKInfoData()
    if ykData then
        isGot = ykData.IsDailyRewardGet
        remainDay = ykData.DailyRewardRemainDay
    end

    local isOverdue, canClickYk = XDataCenter.SignInManager.JudgeYKInSignOverdue(self.Config.SignId, self.Config.Round, self.Config.Day, remainDay)
    local isToday, _ = XDataCenter.SignInManager.JudgeTodayGet(self.Config.SignId, self.Config.Round, self.Config.Day)
    if isOverdue then
        self:SetPanelEnableActive(true)
        self:SetPanelEnableActive(false)
        self:SetPanelDisableActive(true)
        self:SetBtnCardActive(canClickYk and not isToday)
        self:SetPanelDisableParentActive(not isAlreadyGet or isToday)
        return
    end

    self:SetPanelEnableActive(true)
    self:SetPanelDisableActive(false)
    self:SetBtnCardActive(true)
    self:SetPanelDisableParentActive(not isAlreadyGet or isToday)
end

function XUiSignGridDay:SetPanelEnableActive(isActive)
    if self.PanelEnable then
        self.PanelEnable.gameObject:SetActiveEx(isActive)
    end
end

function XUiSignGridDay:SetPanelDisableActive(isActive)
    if self.PanelDisable then
        self.PanelDisable.gameObject:SetActiveEx(isActive)
    end
end

function XUiSignGridDay:SetBtnCardActive(isActive)
    if self.BtnCard then
        self.BtnCard.gameObject:SetActiveEx(isActive)
    end
end

function XUiSignGridDay:SetPanelDisableActive(isActive)
    if self.PanelDisable then
        self.PanelDisable.gameObject:SetActiveEx(isActive)
    end
end

function XUiSignGridDay:SetPanelDisableParentActive(isActive)
    local parent = self.PanelDisable and self.PanelDisable.transform.parent
    if parent then
        parent.gameObject:SetActiveEx(isActive)
    end
end

-- 领取月卡
function XUiSignGridDay:GetYK(rewardItems)
    if not self.BtnCard then
        self:HandlerReward(rewardItems)
        return
    end

    if not XDataCenter.PurchaseManager.IsYkBuyed() then
        self:HandlerReward(rewardItems)
        return
    end

    XDataCenter.PurchaseManager.YKInfoDataReq(function()
        local data = XDataCenter.PurchaseManager.GetYKInfoData()
        if not data or data.IsDailyRewardGet then
            self:HandlerReward(rewardItems)
            return
        end

        XDataCenter.PurchaseManager.PurchaseGetDailyRewardRequest(data.Id, function(rewards)
            for _, v in ipairs(rewards) do
                if not rewardItems then
                    rewardItems = {}
                end

                table.insert(rewardItems, v)
            end
            self:HandlerReward(rewardItems)
        end, function()
            self:HandlerReward(rewardItems)
        end)
    end)
end

function XUiSignGridDay:HandlerReward(rewardItems)
    if rewardItems and #rewardItems > 0 then
        self:SetReward(rewardItems)
    else
        self:SetNoReward()
    end
end

function XUiSignGridDay:SetReward(rewardItems)
    self.PanelHaveGroup.alpha = 1
    self.PanelHaveReceive.gameObject:SetActiveEx(true)
    self.GameObject:PlayTimelineAnimation(function()
        XUiManager.OpenUiObtain(rewardItems)
        self:SetEffectActive(false)
        self:SetCardInfo()
        XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true, self.Config)
    end)
end

function XUiSignGridDay:SetNoReward()
    self:SetEffectActive(false)
    if self.BtnCard then
        self:SetPanelEnableActive(false)
        self:SetPanelDisableActive(true)
        self:SetBtnCardActive(true)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)
end

return XUiSignGridDay