local XUiTipReward = XLuaUiManager.Register(XLuaUi, "UiTipReward")

function XUiTipReward:OnAwake()
    self:InitAutoScript()
    self:InitBtnSound()
end

function XUiTipReward:OnStart(rewardGoodsList, title, closecallback, surecallback, extraTip)
    self.GridBagItemRecycle.gameObject:SetActive(false)
    self.Items = {}
    self.OkCallback = surecallback
    self.CancelCallback = closecallback
    self:Refresh(rewardGoodsList)
    if title then
        self.RecycleTitle.text = title
    end
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_Big)
    if extraTip ~= nil and self.TxtExtraTip then
        self.TxtExtraTip.gameObject:SetActiveEx(true)
        self.TxtExtraTip.text = extraTip
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiTipReward:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiTipReward:AutoInitUi()
    self.BtnBg = self.Transform:Find("SafeAreaContentPane/BtnBg"):GetComponent("Button")
    self.BtnDetermine = self.Transform:Find("SafeAreaContentPane/BtnDetermine"):GetComponent("Button")
    self.PanelRecycle = self.Transform:Find("SafeAreaContentPane/ViewRecycle/Viewport/PanelRecycle")
    self.GridBagItemRecycle = self.Transform:Find("SafeAreaContentPane/ViewRecycle/Viewport/PanelRecycle/GridBagItemRecycle")
    self.RecycleTitle = self.Transform:Find("SafeAreaContentPane/RecycleTitle/RecycleTitle1"):GetComponent("Text")
end

function XUiTipReward:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiTipReward:RegisterListener(uiNode, eventName, func)
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
            XLog.Error("XUiTipReward:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiTipReward:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnBg, self.OnBtnBgClick)
    self:RegisterClickEvent(self.BtnDetermine, self.OnBtnDetermineClick)
end
-- auto
--初始化音效
function XUiTipReward:InitBtnSound()
    self.SpecialSoundMap[self:GetAutoKey(self.BtnBg, "onClick")] = XSoundManager.UiBasicsMusic.Return
    self.SpecialSoundMap[self:GetAutoKey(self.BtnDetermine, "onClick")] = XSoundManager.UiBasicsMusic.Confirm
end

function XUiTipReward:OnBtnBgClick()
    self:Close()
    if self.CancelCallback then
        self.CancelCallback()
    end
end

function XUiTipReward:OnBtnDetermineClick()
    self:Close()
    if self.OkCallback then
        self.CancelCallback()
    end
end

function XUiTipReward:Refresh(rewardGoodsList)
    local onCreate = function(grid, data)
        grid:Refresh(data)
    end
    XUiHelper.CreateTemplates(self, self.Items, rewardGoodsList, XUiGridCommon.New, self.GridBagItemRecycle, self.PanelRecycle, onCreate)
end