local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiBatchPanel = XClass(nil, "XUiBatchPanel")
local Interval = 100
local MinCount = 1
local MaxCount = 99
-- panelParam格式
-- panelParam = {
--     MaxCount,
--     MinCount,
--     BtnAddCallBack,
--     BtnReduceCallBack,
--     BtnAddLongCallBack,
--     BtnReduceLongCallBack,
--     BtnMaxCallBack,
--     SelectTextChangeCallBack,
--     SelectTextInputEndCallBack,
-- }
function XUiBatchPanel:Ctor(rootUi, ui, panelParam)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init(panelParam)
end

function XUiBatchPanel:Init(panelParam)
    if not panelParam then
        XLog.Error("PanelParam Cant Be nil")
        return
    end
    self.MaxCount = panelParam.MaxCount or MaxCount
    self.MinCount = panelParam.MinCount or MinCount
    self.Interval = panelParam.Interval or Interval
    self.BtnAddCallBack = panelParam.BtnAddCallBack
    self.BtnReduceCallBack = panelParam.BtnReduceCallBack
    self.BtnAddLongCallBack = panelParam.BtnAddLongCallBack
    self.BtnReduceLongCallBack = panelParam.BtnReduceLongCallBack
    self.BtnMaxCallBack = panelParam.BtnMaxCallBack
    self.SelectTextChangeCallBack = panelParam.SelectTextChangeCallBack
    self.SelectTextInputEndCallBack = panelParam.SelectTextInputEndCallBack

    self:AutoRegisterListener()
    self:SetSelectTextData()
    self.IsInLongClick = false

    if self.MaxCount <= 1 then
        self.BtnMax:SetDisable(true, false)
    else
        self.BtnMax:SetDisable(false, true)
    end

    self.TxtSelect.text = tostring(self.MinCount)
end

function XUiBatchPanel:OnBtnAddClick()
    if self.IsInLongClick then
        self.IsInLongClick = false
        return
    end

    if self.RootUi.CurrentBuyCount >= self.MaxCount then
        return
    end

    if self.BtnAddCallBack then
        self.BtnAddCallBack()
        self.BtnClicked = true
        self.TxtSelect.text = tostring(self.RootUi.CurrentBuyCount)
    end
end

function XUiBatchPanel:OnBtnReduceClick()
    if self.IsInLongClick then
        self.IsInLongClick = false
        return
    end

    if self.RootUi.CurrentBuyCount <= self.MinCount then
        return
    end

    if self.BtnReduceCallBack then
        self.BtnReduceCallBack()
        self.BtnClicked = true
        self.TxtSelect.text = tostring(self.RootUi.CurrentBuyCount)
    end
end

function XUiBatchPanel:OnBtnAddLongClick()
    if self.RootUi.CurrentBuyCount >= self.MaxCount then
        return
    end

    if not self.IsInLongClick then self.IsInLongClick = true end
    if self.BtnAddLongCallBack then
        self.BtnAddLongCallBack()
        self.BtnClicked = true
        self.TxtSelect.text = tostring(self.RootUi.CurrentBuyCount)
    end
end

function XUiBatchPanel:OnBtnReduceLongClick()
    if self.RootUi.CurrentBuyCount <= self.MinCount then
        return
    end

    if not self.IsInLongClick then self.IsInLongClick = true end
    if self.BtnReduceLongCallBack then
        self.BtnReduceLongCallBack()
        self.BtnClicked = true
        self.TxtSelect.text = tostring(self.RootUi.CurrentBuyCount)
    end
end

function XUiBatchPanel:OnBtnMaxClick()
    if self.BtnMaxCallBack then
        self.BtnMaxCallBack()
        self.BtnClicked = true
        self.TxtSelect.text = tostring(self.RootUi.CurrentBuyCount)
    end
end

function XUiBatchPanel:OnSelectTextValueChange()
    if self.BtnClicked then
        self.BtnClicked = false
        return
    end
    if self.SelectTextChangeCallBack then
        local num = tonumber(self.TxtSelect.text)
        if not num then
            num = self.MinCount
        end
        if num < self.MinCount then
            num = self.MinCount
        elseif num > self.MaxCount then
            num = self.MaxCount
        end
        self.SelectTextChangeCallBack(num)
        if self.TxtSelect.text ~= tostring(self.RootUi.CurrentBuyCount) then
            self.TxtSelect.text = tostring(self.RootUi.CurrentBuyCount)
        end
    end
end

function XUiBatchPanel:OnSelectTextInputEnd()
   if self.SelectTextInputEndCallBack then
        local num = tonumber(self.TxtSelect.text)
        if not num then
            num = self.MinCount
        end
        if num < self.MinCount then
            num = self.MinCount
        elseif num > self.MaxCount then
            num = self.MaxCount
        end
        self.SelectTextInputEndCallBack(num)
        self.TxtSelect.text = tostring(self.RootUi.CurrentBuyCount)
    end
end

function XUiBatchPanel:AutoRegisterListener()
    self.BtnAddSelect.CallBack = function () self:OnBtnAddClick() end
    self.BtnMinSelect.CallBack = function () self:OnBtnReduceClick() end
    self.BtnMax.CallBack = function () self:OnBtnMaxClick() end
    self.BtnAddSelectPointer:RemoveAllListeners()
    XUiButtonLongClick.New(self.BtnAddSelectPointer, self.Interval, self, nil, self.OnBtnAddLongClick, nil, true)
    self.BtnMinusSelectPointer:RemoveAllListeners()
    XUiButtonLongClick.New(self.BtnMinusSelectPointer, self.Interval, self, nil, self.OnBtnReduceLongClick, nil, true)
    self.TxtSelect.onValueChanged:RemoveAllListeners()
    self.TxtSelect.onValueChanged:AddListener(function() self:OnSelectTextValueChange() end)
    self.TxtSelect.onEndEdit:RemoveAllListeners()
    self.TxtSelect.onEndEdit:AddListener(function() self:OnSelectTextInputEnd() end)
end

function XUiBatchPanel:SetSelectTextData()
    self.TxtSelect.characterLimit = 4
    self.TxtSelect.contentType = CS.UnityEngine.UI.InputField.ContentType.IntegerNumber
end

return XUiBatchPanel