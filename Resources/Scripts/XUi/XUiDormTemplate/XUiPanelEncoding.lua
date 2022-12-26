local XUiPanelEncoding = XClass(nil, "XUiPanelEncoding")

function XUiPanelEncoding:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:AddListener()
end

function XUiPanelEncoding:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelEncoding:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelEncoding:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelEncoding:AddListener()
    self:RegisterClickEvent(self.BtnAllClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSure, self.OnBtnSureClick)
end

function XUiPanelEncoding:OnBtnCloseClick()
    self:Close()
end

function XUiPanelEncoding:OnBtnSureClick()
    local shareId = string.gsub(self.InFSigm.text, "^%s*(.-)%s*$", "%1")
    if string.len(shareId) < 0 then
        XUiManager.TipError(CS.XTextManager.GetText("DormTemplateEncondeNoneID"))
        return
    end

    local titletext = CS.XTextManager.GetText("TipTitle")
    local contenttext = CS.XTextManager.GetText("DormTemplateEncondeTip")

    XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.DormManager.DormGetPlayerLayoutReq(shareId, function()
            self:Close()
            self.RootUi:Close()
            XDataCenter.DormManager.EnterTeamplateDormitory(shareId, XDormConfig.DormDataType.Provisional)
        end)
    end)
end

function XUiPanelEncoding:Close()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelEncoding:Open()
    self.InFSigm.text = ""
    self.GameObject:SetActiveEx(true)
end

return XUiPanelEncoding