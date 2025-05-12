local XUiGridArenaAreaCharacter = require("XUi/XUiArenaNew/XUiArenaBattleRoleTips/XUiGridArenaAreaCharacter")

---@class XUiGridArenaAreaRecord : XUiNode
---@field _Control XArenaControl
local XUiGridArenaAreaRecord = XClass(XUiNode, "XUiGridArenaAreaRecord")

local GridColor = {
    XUiHelper.Hexcolor2Color("4F99FF"),
    XUiHelper.Hexcolor2Color("FF1111"),
    XUiHelper.Hexcolor2Color("F9CB35"),
}

function XUiGridArenaAreaRecord:OnStart()
    self._Data = nil
    ---@type XUiGridArenaAreaCharacter[]
    self._GridList = {}
end

function XUiGridArenaAreaRecord:Refresh(data)
    self._Data = data

    self.TxtNumber.text = data.Point
    self.TxtTitle.text = self._Control:GetAreaStageBuffNameByAreaIdAndIndex(data.AreaId, data.SelectEnvironment + 1)
    for i, characterData in ipairs(data.CharacterList) do
        if not self._GridList[i] then
            local obj = XUiHelper.Instantiate(self.GridTeamRole, self.PanelCharContent)

            self._GridList[i] = XUiGridArenaAreaCharacter.New(obj, self)
        end
        self._GridList[i]:Refresh(characterData, data.PartnerList[i], data.AbilityList[i], data.QualityList[i],
            data.CharacterHeadInfoList[i], GridColor[i])
    end

    self.GridTeamRole.gameObject:SetActiveEx(false)
end

return XUiGridArenaAreaRecord
