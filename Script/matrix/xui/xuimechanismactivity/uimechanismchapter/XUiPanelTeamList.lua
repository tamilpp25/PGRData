---@class XUiPanelTeamList
---@field _Control XMechanismActivityControl
---@field Parent XUiMechanismChapter
local XUiPanelTeamList = XClass(XUiNode, 'XUiPanelTeamList')
local XUiGridTeamMember = require('XUi/XUiMechanismActivity/UiMechanismChapter/XUiGridTeamMember')

function XUiPanelTeamList:InitTeamDataByChapterId(chapterId)
    self._ChapterId = chapterId
    self.GridCharacter.gameObject:SetActiveEx(false)
    self._CharaGrids = {}
end

function XUiPanelTeamList:Refresh()
    self.TxtTeamName.text = self._Control:GetChapterTeamNameById(self._ChapterId)
    local characterCfgs = XMVCA.XMechanismActivity:GetMechanismCharacterCfgsByChapterId(self._ChapterId)
    if not XTool.IsTableEmpty(characterCfgs) then
        ---@param v XTableMechanismCharacter
        for i, v in ipairs(characterCfgs) do
            if self._CharaGrids[i] then
                self._CharaGrids[i]:Refresh(v.CharacterId)
            else
                local clone = CS.UnityEngine.GameObject.Instantiate(self.GridCharacter, self.GridCharacter.transform.parent)
                local grid = XUiGridTeamMember.New(clone, self, i, v.Id)
                grid:Open()
                self._CharaGrids[i] = grid
                self._CharaGrids[i]:Refresh(v.CharacterId)
            end
        end
    else
        for i, v in ipairs(self._CharaGrids[i]) do
            self._CharaGrids[i]:Refresh(0)
        end
    end
end

return XUiPanelTeamList