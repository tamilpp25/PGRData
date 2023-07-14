XUiPanelSetBirthday = XClass(nil, "XUiPanelSetBirthday")

function XUiPanelSetBirthday:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:InitAutoScript()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelSetBirthday:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelSetBirthday:AutoInitUi()
    self.BtnBirSure = self.Transform:Find("BtnBirSure"):GetComponent("Button")
    self.BtnBirCancel = self.Transform:Find("BtnBirCancel"):GetComponent("Button")
    self.TxtB = self.Transform:Find("Txt"):GetComponent("Text")
    self.TxtMon = self.Transform:Find("InMon/TxtMon"):GetComponent("Text")
    self.TxtDay = self.Transform:Find("InDay/TxtDay"):GetComponent("Text")
end

function XUiPanelSetBirthday:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelSetBirthday:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelSetBirthday:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelSetBirthday:AutoAddListener()
    self:RegisterClickEvent(self.BtnBirSure, self.OnBtnBirSureClick)
    self:RegisterClickEvent(self.BtnBirCancel, self.OnBtnBirCancelClick)
    self.BtnClose.CallBack = function()
        self:OnBtnBirCancelClick()
    end
end
-- auto

function XUiPanelSetBirthday:OnBtnBirSureClick()
    local dayNum = 31
    local mon = tonumber(self.TxtMon.text)
    local day = tonumber(self.TxtDay.text)
    if not mon or not day then
        XUiManager.TipText("WrongDate",XUiManager.UiTipType.Wrong)
        return
    end

    if mon < 1 or mon > 12 then
        XUiManager.TipText("WrongDate",XUiManager.UiTipType.Wrong)
        return
    end

    if mon == 2 then
        dayNum = 29
    elseif mon == 4 or mon == 6 or mon == 9 or mon == 11 then
        dayNum = 30
    end

    if day < 1 or day > dayNum then
        XUiManager.TipText("WrongDate",XUiManager.UiTipType.Wrong)
        return
    end

    -- 对话框取消事件
    local onCancelCb = function ()
        self.Base:OnBtnBirModifyClick()
    end

    -- 对话框确认事件
    local onConfirmCb = function ()
        local currBir = XPlayer.Birthday
        if currBir then
            local isChanged = XPlayer.IsChangedBirthday()
            if (currBir.Mon and mon == currBir.Mon) and (currBir.Day and day == currBir.Day) and isChanged then
                self.Base:HidePanelSetBirthday()
                return
            end
        end

        XPlayer.ChangeBirthday(mon, day, function()
            self.Base:ChangeBirthdayCallback()
        end)
    end

    -- 提示对话框的层级比修改生日弹框的层级低，先将修改生日弹框关闭
    self:OnBtnBirCancelClick()
    local desc
    if XPlayer.Birthday then
        desc = CS.XTextManager.GetText("BirthdayChangeTips", XPlayer.Birthday.Mon, XPlayer.Birthday.Day, mon, day)
    else
        desc = CS.XTextManager.GetText("BirthdayFirstSetTips", mon, day)
    end
    XUiManager.DialogTip("", desc, XUiManager.DialogType.Normal, onCancelCb, onConfirmCb)
    
end

function XUiPanelSetBirthday:OnBtnBirCancelClick()
    self.Base:HidePanelSetBirthday()
end

return XUiPanelSetBirthday