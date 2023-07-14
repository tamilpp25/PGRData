local XUiMoneyRewardLevelUpTips = XLuaUiManager.Register(XLuaUi, "UiMoneyRewardLevelUpTips")

function XUiMoneyRewardLevelUpTips:OnAwake()
    self:InitAutoScript()
end

function XUiMoneyRewardLevelUpTips:OnStart(oldLevel, newLevel)
    self.OldLevel = oldLevel
    self.NewLevel = newLevel
    self:SetupTips()

    self.PlayingAnimaiton = true
    self:PlayAnimation("MoneyRewardLevelUpTipBegin", function()
        self.PlayingAnimaiton = false
    end)

end

--设置Tips内容
function XUiMoneyRewardLevelUpTips:SetupTips()
    local configPre = XDataCenter.BountyTaskManager.GetBountyTaskRankConfig(self.OldLevel)
    local configCur = XDataCenter.BountyTaskManager.GetBountyTaskRankConfig(self.NewLevel)

    self.TxtPre.text = configPre.RankName
    self.TxtNext.text = configCur.RankName
end

function XUiMoneyRewardLevelUpTips:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiMoneyRewardLevelUpTips:AutoInitUi()
    self.TxtNext = self.Transform:Find("FullScreenBackground/TxtNext"):GetComponent("Text")
    self.TxtPre = self.Transform:Find("FullScreenBackground/TxtPre"):GetComponent("Text")
    self.BtnBg = self.Transform:Find("FullScreenBackground/BtnBg"):GetComponent("Button")
end

function XUiMoneyRewardLevelUpTips:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiMoneyRewardLevelUpTips:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiMoneyRewardLevelUpTips:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiMoneyRewardLevelUpTips:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnBg, self.OnBtnBgClick)
end

function XUiMoneyRewardLevelUpTips:OnBtnBgClick()

    if self.PlayingAnimaiton then
        return
    end

    self.PlayingAnimaiton = true

    self:PlayAnimation("MoneyRewardLevelUpTipEnd",function()
        self:Close()
        XEventManager.DispatchEvent(XEventId.EVENT_BOUNTYTASK_ACCEPT_TASK_REWARD)
    end)
end