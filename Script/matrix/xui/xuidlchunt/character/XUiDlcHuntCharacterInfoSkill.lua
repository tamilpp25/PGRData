local XUiDlcHuntChipGridAttr = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipGridAttr")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local XUiDlcHuntCharacterSkillGrid = require("XUi/XUiDlcHunt/Character/XUiDlcHuntCharacterSkillGrid")

---@class XUiDlcHuntCharacterInfoSkill
local XUiDlcHuntCharacterInfoSkill = XClass(nil, "XUiDlcHuntCharacterInfoSkill")

function XUiDlcHuntCharacterInfoSkill:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntCharacter
    self._ViewModel = viewModel
    self._UiAttr = {}
    self._UiSkill = {}
end

function XUiDlcHuntCharacterInfoSkill:Update()
    local attrTable = self._ViewModel:GetAttrTable4Display(true)
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiAttr, attrTable, self.Gridformation1, XUiDlcHuntChipGridAttr)

    local uiSkill = { self.GridIconChip, self.GridIconChip2 }
    local skillList = self._ViewModel:GetSkill()
    for i = 1, #uiSkill do
        local skill = skillList[i]
        local grid = self._UiSkill[i]
        if not grid then
            local ui = uiSkill[i]
            grid = XUiDlcHuntCharacterSkillGrid.New(ui)
            self._UiSkill[i] = grid
            XUiHelper.RegisterClickEvent(self, grid.BtnClick, function()
                XLuaUiManager.Open("UiDlcHuntSkillDetails", self._ViewModel:GetCharacter(), i)
            end)
        end
        grid:Update(skill)
    end
end

return XUiDlcHuntCharacterInfoSkill