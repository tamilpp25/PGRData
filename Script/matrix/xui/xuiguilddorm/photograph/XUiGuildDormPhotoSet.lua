---@class XUiGuildDormPhotoSet : XLuaUi
---@field BtnShowGuildId XUiComponent.XUiButton
---@field LogoDrdSort UnityEngine.UI.Dropdown
local XUiGuildDormPhotoSet = XLuaUiManager.Register(XLuaUi, "UiGuildDormPhotoSet")

local UiButtonState = CS.UiButtonState
local CsDropDown = CS.UnityEngine.UI.Dropdown

function XUiGuildDormPhotoSet:OnAwake()
    self:RegisterUiEvents()
end

---@param setData XUiGuildDormPhotographData
function XUiGuildDormPhotoSet:OnStart(setData, callback)
    self.SetData = setData
    self.CallBack = callback
    self:InitView()
end

function XUiGuildDormPhotoSet:InitView()
    local valueOfShowGuildId = self.SetData:GetOpenGuildId()
    local valueOfShowLevel = self.SetData:GetOpenLevel()
    local valueOfShowUId = self.SetData:GetOpenUId()
    self.BtnShowGuildId:SetButtonState(valueOfShowGuildId and UiButtonState.Select or UiButtonState.Normal)
    self.BtnShowLevel:SetButtonState(valueOfShowLevel and UiButtonState.Select or UiButtonState.Normal)
    self.BtnShowUId:SetButtonState(valueOfShowUId and UiButtonState.Select or UiButtonState.Normal)

    local alignment = self.SetData:GetAlignment()
    self.LogoDrdSort:ClearOptions()
    self.GuildCardDrdSort:ClearOptions()
    self.PlayerCardDrdSort:ClearOptions()
    for _, data in pairs(alignment or {}) do
        local op = CsDropDown.OptionData()
        op.text = data.Name
        self.LogoDrdSort.options:Add(op)
        self.GuildCardDrdSort.options:Add(op)
        self.PlayerCardDrdSort.options:Add(op)
    end
    self.LastLogoValue = self.SetData:GetLogoAlignment().Value
    self.LogoDrdSort.value = self.LastLogoValue
    self.LastGuildValue = self.SetData:GetGuildAlignment().Value
    self.GuildCardDrdSort.value = self.LastGuildValue
    self.LastPlayerValue = self.SetData:GetPlayerAlignment().Value
    self.PlayerCardDrdSort.value = self.LastPlayerValue

    self.PanelShowHideGuild.gameObject:SetActiveEx(self.LastGuildValue ~= 0)
    self.PanelShowHidePlayer.gameObject:SetActiveEx(self.LastPlayerValue ~= 0)
end

function XUiGuildDormPhotoSet:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick)
    
    self.LogoDrdSort.onValueChanged:AddListener(function(value)
        self:OnLogoDrdSortValueChanged(value)
    end)
    self.GuildCardDrdSort.onValueChanged:AddListener(function(value)
        self:OnGuildDrdSortValueChanged(value)
    end)
    self.PlayerCardDrdSort.onValueChanged:AddListener(function(value)
        self:OnPlayerDrdSortValueChanged(value)
    end)
end

function XUiGuildDormPhotoSet:OnBtnBackClick()
    self:Close()
end

function XUiGuildDormPhotoSet:OnBtnConfirmClick()
    local valueOfShowGuildId = self.BtnShowGuildId:GetToggleState() and 1 or 0
    local valueOfShowLevel = self.BtnShowLevel:GetToggleState() and 1 or 0
    local valueOfShowUId = self.BtnShowUId:GetToggleState() and 1 or 0
    self.SetData:Update(self.LastLogoValue, self.LastGuildValue, self.LastPlayerValue, valueOfShowGuildId, valueOfShowLevel, valueOfShowUId)
    self.SetData:SaveSetData()
    if self.CallBack then
        self.CallBack()
    end
    self:Close()
end

function XUiGuildDormPhotoSet:OnLogoDrdSortValueChanged(value)
    self.LastLogoValue = value
end

function XUiGuildDormPhotoSet:OnGuildDrdSortValueChanged(value)
    self.LastGuildValue = value
    self.PanelShowHideGuild.gameObject:SetActiveEx(value ~= 0)
end

function XUiGuildDormPhotoSet:OnPlayerDrdSortValueChanged(value)
    self.LastPlayerValue = value
    self.PanelShowHidePlayer.gameObject:SetActiveEx(value ~= 0)
end

return XUiGuildDormPhotoSet