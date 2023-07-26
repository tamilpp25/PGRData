local XUiFubenDialog = XLuaUiManager.Register(XLuaUi, "UiFubenDialog")

function XUiFubenDialog:OnAwake()
    self:InitAutoScript()
    self:InitBtnSound()
end

function XUiFubenDialog:OnStart(title, content, closeCallback, sureCallback)
    if title ~= nil and title ~= "" then
        self.Txt.text = title
    else
        self.Txt.text = CS.XTextManager.GetText("FubenDialogTitle")
    end

    self.TxtInfo.text = string.gsub(content, "\\n", "\n")
    self.OkCallBack = sureCallback
    self.CancelCallBack = closeCallback
end

--初始化音效
function XUiFubenDialog:InitBtnSound()
    self.SpecialSoundMap[self:GetAutoKey(self.BtnClose, "onClick")] = XSoundManager.UiBasicsMusic.Return
    self.SpecialSoundMap[self:GetAutoKey(self.BtnConfirm, "onClick")] = XSoundManager.UiBasicsMusic.Confirm
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiFubenDialog:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiFubenDialog:AutoInitUi()
    self.PanelDialog = self.Transform:Find("SafeAreaContentPane/PanelDialog")
    self.BtnConfirm = self.Transform:Find("SafeAreaContentPane/PanelDialog/BtnConfirm"):GetComponent("Button")
    self.BtnClose = self.Transform:Find("SafeAreaContentPane/PanelDialog/BtnClose"):GetComponent("Button")
    self.Txt = self.Transform:Find("SafeAreaContentPane/PanelDialog/Txt"):GetComponent("Text")
    self.PanelTextList = self.Transform:Find("SafeAreaContentPane/PanelTextList")
    self.TxtInfo = self.Transform:Find("SafeAreaContentPane/PanelTextList/Viewport/TxtInfo"):GetComponent("Text")
end

function XUiFubenDialog:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiFubenDialog:RegisterListener(uiNode, eventName, func)
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
            XLog.Error("XUiFubenDialog:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiFubenDialog:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end
-- auto
function XUiFubenDialog:OnBtnConfirmClick()
    self:OkBtnClick()
end

function XUiFubenDialog:OnBtnCloseClick()
    self:CancelBtnClick()
end

function XUiFubenDialog:OkBtnClick()
    --CS.XUiManager.DialogManager:Pop()
    self:Close()
    if self.OkCallBack then
        self.OkCallBack()
    end

    self.OkCallBack = nil
    self.CancelCallBack = nil
end

function XUiFubenDialog:CancelBtnClick()
    --CS.XUiManager.DialogManager:Pop()
    self:Close()
    if self.CancelCallBack and type(self.CancelCallBack) == "function" then
        self.CancelCallBack()
    end

    self.OkCallBack = nil
    self.CancelCallBack = nil
end

function XUiFubenDialog:OnEnable()

end

function XUiFubenDialog:OnDisable()

end