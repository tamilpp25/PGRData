local XUiTipLayer = XLuaUiManager.Register(XLuaUi, "UiTipLayer")

local TIP_MSG_SHOW_TIME = 2000

function XUiTipLayer:OnAwake()
    self:InitAutoScript()
end

function XUiTipLayer:OnStart(msg, type, cb, hideCloseMark)
    self.Cb = cb
    self.closeState = false
    self:HideTipLayer()
    self.BtnClose.interactable = true
    self.BtnClose.gameObject:SetActive(not hideCloseMark)
    XUiHelper.StopAnimation()
    if type == XUiManager.UiTipType.Tip then
        self.PanelTip.gameObject:SetActive(true)
        self:PlayAnimation("PanelTip")
        self.TxtInfo.text = msg
    elseif type == XUiManager.UiTipType.Success then
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Success) -- 成功
        self.PanelSuccess.gameObject:SetActive(true)
        self:PlayAnimation("PaneSuccess")
        self.TxtInfoSuccess.text = msg
    elseif type == XUiManager.UiTipType.Wrong then
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Intercept) -- 拦截
        self.PanelError.gameObject:SetActive(true)
        self:PlayAnimation("PanelError")
        self.TxtInfoError.text = msg
    end

    local pop = function()
        self:Close()
    end

    local closeFunc
    if type == XUiManager.UiTipType.Tip then
        closeFunc = function()
            if not XTool.UObjIsNil(self.GameObject) then
                self:PlayAnimation("PanelTipEnd", pop)
            end
        end
    elseif type == XUiManager.UiTipType.Success then
        closeFunc = function()
            if not XTool.UObjIsNil(self.GameObject) then
                self:PlayAnimation("PaneSuccessEnd", pop)
            end
        end
    elseif type == XUiManager.UiTipType.Wrong then
        closeFunc = function()
            if not XTool.UObjIsNil(self.GameObject) then
                self:PlayAnimation("PanelErrorEnd", pop)
            end
        end
    end
    self.CloseFunc = closeFunc
    self.Timer = XScheduleManager.ScheduleOnce(function()
        if not self.closeState then
            self.closeState = true
            closeFunc()
        end
    end, TIP_MSG_SHOW_TIME)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiTipLayer:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiTipLayer:AutoInitUi()
    self.BtnClose = self.Transform:Find("SafeAreaContentPane/BtnClose"):GetComponent("Button")
    self.PanelSuccess = self.Transform:Find("SafeAreaContentPane/PanelSuccess")
    self.TxtInfoSuccess = self.Transform:Find("SafeAreaContentPane/PanelSuccess/TxtInfo"):GetComponent("Text")
    self.PanelError = self.Transform:Find("SafeAreaContentPane/PanelError")
    self.TxtInfoError = self.Transform:Find("SafeAreaContentPane/PanelError/TxtInfo"):GetComponent("Text")
    self.PanelTip = self.Transform:Find("SafeAreaContentPane/PanelTip")
    self.TxtInfo = self.Transform:Find("SafeAreaContentPane/PanelTip/TxtInfo"):GetComponent("Text")
end

function XUiTipLayer:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiTipLayer:RegisterListener(uiNode, eventName, func)
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
            XLog.Error("XUiTipLayer:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiTipLayer:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end
-- auto
function XUiTipLayer:OnBtnCloseClick()

    if self.closeState then
        return
    end

    self.closeState = true
    XScheduleManager.UnSchedule(self.Timer)
    self.BtnClose.interactable = false
    if self.CloseFunc then
        self:CloseFunc()
    else
        --CS.XUiManager.TipsManager:Pop()
        self:Close()
    end
end

function XUiTipLayer:HideTipLayer()
    self.PanelTip.gameObject:SetActive(false)
    self.PanelError.gameObject:SetActive(false)
    self.PanelSuccess.gameObject:SetActive(false)
end

function XUiTipLayer:OnDestroy()
    local key = self:GetAutoKey(self.BtnClose, "onClick")
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        self.BtnClose["onClick"]:RemoveListener(listener)
    end
    if self.Cb then
        self.Cb()
    end
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end