local TYPE = {
    NONE = 0,
    CHARACTER = 1,
    CHIP_GROUP = 2
}

local TAB = {
    Attr = 1,
    Magic = 2
}

local XUiDlcHuntAttrDialogCharacter = require("XUi/XUiDlcHunt/Attr/XUiDlcHuntAttrDialogCharacter")
local XUiDlcHuntAttrDialogChipGroup = require("XUi/XUiDlcHunt/Attr/XUiDlcHuntAttrDialogChipGroup")
local XUiDlcHuntAttrDialogMagic = require("XUi/XUiDlcHunt/Attr/XUiDlcHuntAttrDialogMagic")

---@class UiDlcHuntCharacterDialog:XLuaUi
local XUiDlcHuntAttrDialog = XLuaUiManager.Register(XLuaUi, "UiDlcHuntAttrDialog")

function XUiDlcHuntAttrDialog:Ctor()
    self._Type = TYPE.NONE
    self._Tab = TAB.Attr
    self._Data = false
end

function XUiDlcHuntAttrDialog:OnAwake()
    self:BindExitBtns(self.BtnTanchuangClose)

    ---@type XUiDlcHuntAttrDialogCharacter
    self._UiCharacter = XUiDlcHuntAttrDialogCharacter.New(self.PanelRoleProperties)
    ---@type XUiDlcHuntAttrDialogChipGroup
    self._UiChipGroup = XUiDlcHuntAttrDialogChipGroup.New(self.PanelChipProperties)
    ---@type XUiDlcHuntAttrDialogMagic
    self._UiMagic = XUiDlcHuntAttrDialogMagic.New(self.PanelAffix)
end

function XUiDlcHuntAttrDialog:OnStart(params)
    if params.ChipGroup then
        self._Type = TYPE.CHIP_GROUP
        self._Data = params.ChipGroup
    elseif params.Character then
        self._Type = TYPE.CHARACTER
        self._Data = params.Character
    else
        XLog.Error("[XUiDlcHuntAttrDialog] params is not chipGroup or character")
        return
    end
    self:UpdateTab()
    self:UpdateByTab()
    self.PanelTab:SelectIndex(TAB.Attr, false)
end

function XUiDlcHuntAttrDialog:UpdateTab()
    if self._Type == TYPE.CHIP_GROUP then
        self.BtnTabCharacterAttr.gameObject:SetActiveEx(false)
        self.BtnTabChipAttr.gameObject:SetActiveEx(true)
        self.PanelTab:Init({ self.BtnTabChipAttr, self.BtnTabMagic }, function(index)
            self:OnTabSelected(index)
        end)

    elseif self._Type == TYPE.CHARACTER then
        self.BtnTabCharacterAttr.gameObject:SetActiveEx(true)
        self.BtnTabChipAttr.gameObject:SetActiveEx(false)
        self.PanelTab:Init({ self.BtnTabCharacterAttr, self.BtnTabMagic }, function(index)
            self:OnTabSelected(index)
        end)
    end
end

function XUiDlcHuntAttrDialog:OnTabSelected(index)
    self._Tab = index
    self:UpdateByTab()
end

function XUiDlcHuntAttrDialog:UpdateByTab()
    if self._Tab == TAB.Attr then
        if self._Type == TYPE.CHIP_GROUP then
            self._UiCharacter.GameObject:SetActiveEx(false)
            self._UiChipGroup.GameObject:SetActiveEx(true)
            self._UiMagic.GameObject:SetActiveEx(false)
            self._UiChipGroup:Update(self._Data)

        elseif self._Type == TYPE.CHARACTER then
            self._UiCharacter.GameObject:SetActiveEx(true)
            self._UiChipGroup.GameObject:SetActiveEx(false)
            self._UiMagic.GameObject:SetActiveEx(false)
            self._UiCharacter:Update(self._Data)

        end
    elseif self._Tab == TAB.Magic then
        self._UiCharacter.GameObject:SetActiveEx(false)
        self._UiChipGroup.GameObject:SetActiveEx(false)
        self._UiMagic.GameObject:SetActiveEx(true)
        self._UiMagic:Update(self._Data)
    end
end

return XUiDlcHuntAttrDialog