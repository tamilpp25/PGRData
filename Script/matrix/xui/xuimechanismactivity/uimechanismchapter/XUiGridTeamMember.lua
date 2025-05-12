---@class XUiGridTeamMember
---@field _Control XMechanismActivityControl
---@field Parent XUiPanelTeamList
local XUiGridTeamMember = XClass(XUiNode, 'XUiGridTeamMember')
local XUiGridMechanismBuff = require('XUi/XUiMechanismActivity/UiMechanismChapter/XUiGridMechanismBuff')

function XUiGridTeamMember:OnStart(index, mechanismCharaIndex)
    self._Index = index
    self._MechanismCharaIndex = mechanismCharaIndex
    self.UiMechanismBuff.gameObject:SetActiveEx(false)
    self._BuffGrids = {}
    self.GridBtn.CallBack = handler(self, self.OnBtnClickEvent)
end

function XUiGridTeamMember:Refresh(entityId)
    local validId = XTool.IsNumberValid(entityId)
    self.StandIcon.gameObject:SetActiveEx(validId)
    self.TxtRoleName.gameObject:SetActiveEx(validId)
    
    if validId then
        local characterIndex = self._Control:GetMechanismCharacterIndexByEntityId(entityId)
        local character = entityId
        if XMVCA.XCharacter:CheckIsCharOrRobot(entityId) then
            character = XRobotManager.GetCharacterId(entityId)
        end
        self.StandIcon:SetRawImage(XMVCA.XCharacter:GetCharBigHeadIcon(character))

        self.TxtRoleName.text = XMVCA.XCharacter:GetCharacterFullNameStr(character)
        
        local characterCfg = self._Control:GetMechanismCharacterCfgByIndex(characterIndex)

        if characterCfg and not XTool.IsTableEmpty(characterCfg.BuffIcons) then
            for i, v in ipairs(characterCfg.BuffIcons) do
                if self._BuffGrids[i] then
                    self._BuffGrids[i]:Open()
                    self._BuffGrids[i]:Refresh(characterIndex, i)
                else
                    local clone = CS.UnityEngine.GameObject.Instantiate(self.UiMechanismBuff, self.UiMechanismBuff.transform.parent)
                    local grid = XUiGridMechanismBuff.New(clone, self)
                    grid:Open()
                    grid:Refresh(characterIndex, i)
                    self._BuffGrids[i] = grid
                end
            end
        else
            for i, v in ipairs(self._BuffGrids) do
                self._BuffGrids[i]:Close()
            end
        end
    else
        for i, v in ipairs(self._BuffGrids) do
            self._BuffGrids[i]:Close()
        end
    end
end

function XUiGridTeamMember:OnBtnClickEvent()
    self._Control:SetCharacterBuffsToOld(self._MechanismCharaIndex)
    XLuaUiManager.OpenWithCloseCallback('UiMechanismTeamDetail', function()
        self._Control:SetChapterCharactersBuffsToOld()
        self.Parent:Refresh()
    end, self._Index, self._MechanismCharaIndex)
end

return XUiGridTeamMember