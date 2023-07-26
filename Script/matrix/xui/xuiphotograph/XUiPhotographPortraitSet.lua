
local XUiPhotographPortraitSet = XLuaUiManager.Register(XLuaUi, "UiPhotographPortraitSet")

local UiButtonState = CS.UiButtonState
local CsDropDown = CS.UnityEngine.UI.Dropdown

function XUiPhotographPortraitSet:OnAwake()
    self:InitCb()
end

function XUiPhotographPortraitSet:OnStart(setData)
    self.SetData = setData
    self:InitView()
end

function XUiPhotographPortraitSet:InitCb()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnCancel.CallBack = function() self:Close() end
    self.BtnConfirm.CallBack = function() self:SaveSet() end

    self.CardDrdSort.onValueChanged:AddListener(function(value)
        self:OnCardDrdSortValueChanged(value)
    end)

    self.LogoDrdSort.onValueChanged:AddListener(function(value)
        self:OnLogoDrdSortValueChanged(value)
    end)
end

function XUiPhotographPortraitSet:InitView()
    local valueOfShowLevel = self.SetData:GetProperty("_OpenLevel")
    local valueOfShowId = self.SetData:GetProperty("_OpenUId")
    self.BtnShowLevel:SetButtonState(XTool.IsNumberValid(valueOfShowLevel) and UiButtonState.Select or UiButtonState.Normal)
    self.BtnShowId:SetButtonState(XTool.IsNumberValid(valueOfShowId) and UiButtonState.Select or UiButtonState.Normal)

    local alignment = self.SetData:GetAlignment()

    self.CardDrdSort:ClearOptions()
    self.LogoDrdSort:ClearOptions()
    for _, data in pairs(alignment or {}) do
        local op = CsDropDown.OptionData()
        op.text = data.Name
        self.CardDrdSort.options:Add(op)
        self.LogoDrdSort.options:Add(op)
    end
    self.LastCardValue = self.SetData:GetProperty("_InfoAlignment").Value
    self.CardDrdSort.value = self.LastCardValue
    self.LastLogoValue = self.SetData:GetProperty("_LogoAlignment").Value
    self.LogoDrdSort.value = self.LastLogoValue
end

function XUiPhotographPortraitSet:OnCardDrdSortValueChanged(value)
    if value == self.LogoDrdSort.value and (value ~= 0 or self.LogoDrdSort.value ~= 0) then
        XUiManager.TipPortraitText("PhotoModeLogoInfoMutex")
        self.CardDrdSort.value = self.LastCardValue
        return
    end
    self.LastCardValue = self.CardDrdSort.value
end

function XUiPhotographPortraitSet:OnLogoDrdSortValueChanged(value)
    if value == self.CardDrdSort.value and (value ~= 0 or self.CardDrdSort.value ~= 0) then
        XUiManager.TipPortraitText("PhotoModeLogoInfoMutex")
        self.LogoDrdSort.value = self.LastLogoValue
        return
    end
    self.LastLogoValue = self.LogoDrdSort.value
end

function XUiPhotographPortraitSet:SaveSet()
    local logoValue = self.LastLogoValue
    local infoValue = self.LastCardValue
    if logoValue == infoValue and (logoValue ~= 0 or infoValue ~= 0) then
        XUiManager.TipPortraitText("PhotoModeLogoInfoMutex")
        return
    end
    local valueOfShowLevel = self.BtnShowLevel:GetToggleState() and 1 or 0
    local valueOfShowId = self.BtnShowId:GetToggleState() and 1 or 0
    self.SetData:Update(logoValue, infoValue, valueOfShowLevel, valueOfShowId)
    self:Close()
end 