XUiPanelDaily = XClass(nil, "XUiPanelDaily")

function XUiPanelDaily:Ctor(ui,rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitAutoScript()
    self.XUiPanelMsgBoard = XUiPanelMsgBoard.New(self.PanelMsgBoard,self.RootUi)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelDaily:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiPanelDaily:AutoInitUi()
    -- self.BtnBack = self.Transform:Find("BtnBack"):GetComponent("Button")
    -- self.PanelMsgBoard = self.Transform:Find("PanelMsgBoard")
    -- self.PanelWrite = self.Transform:Find("PanelWrite")
    -- self.BtnWriteMsg = self.Transform:Find("BtnWriteMsg"):GetComponent("Button")
end

function XUiPanelDaily:GetAutoKey(uiNode,eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelDaily:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelDaily:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key],eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiPanelDaily:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnWriteMsg, self.OnBtnWriteMsgClick)
end
-- auto

function XUiPanelDaily:OnBtnBackClick()
    self:PlayAnimation("DailyOut", function ()
            self:SetIsShow(false)
    end, function ()

    end)
end

function XUiPanelDaily:OnBtnWriteMsgClick()
    XDataCenter.PersonalInfoManager.OpenInputView(function( content )
        XDataCenter.PersonalInfoManager.WriteDaily(content,function()
            XDataCenter.PersonalInfoManager.RefreshDailyData(1,
            function()
                XDataCenter.PersonalInfoManager.PanelMsgBoard:Refresh()
            end)
        end)--写日记
    end)
end

function XUiPanelDaily:SetIsShow( code )
    if code then
        XDataCenter.PersonalInfoManager.GetDailys(XPlayer.Id,1,function()
            self.XUiPanelMsgBoard:Refresh()
        end)
    end
    self.GameObject.gameObject:SetActive(code)
end

function XUiPanelDaily:OnClose()
    -- body
end