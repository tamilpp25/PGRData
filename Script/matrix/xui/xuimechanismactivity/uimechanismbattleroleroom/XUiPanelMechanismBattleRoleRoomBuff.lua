---@class XUiPanelMechanismBattleRoleRoomBuff
---@field _Control XMechanismActivityControl
---@field Parent XUiBattleRoleRoom
local XUiPanelMechanismBattleRoleRoomBuff = XClass(XUiNode, 'XUiPanelMechanismBattleRoleRoomBuff')
local XUiGridMechanismBuff = require('XUi/XUiMechanismActivity/UiMechanismChapter/XUiGridMechanismBuff')

function XUiPanelMechanismBattleRoleRoomBuff:OnStart(index)
    self._Index = index
    self.UiEffectPlayBuff.gameObject:SetActiveEx(false)
    self.Btn.CallBack = handler(self, self.OnBtnClickEvent)
    self._GridList = {}
    self:Refresh()
end

function XUiPanelMechanismBattleRoleRoomBuff:OnDisable()
    for i, v in pairs(self._GridList) do
        v:Close()
    end
end


function XUiPanelMechanismBattleRoleRoomBuff:Refresh()
    -- 刷新角色在机制玩法表中的Id
    ---@type XTeam
    local curTeam = self.Parent.Team or self._Control:GetTeamDataByChapterId(self._Control:GetMechanismCurChapterId())

    if XTool.IsTableEmpty(curTeam) then
        return
    end
    
    local entityId = curTeam:GetEntityIdByTeamPos(self._Index)
    self._MechanismCharacterId = self._Control:GetMechanismCharacterIndexByEntityId(entityId)
    
    local buffIcons = self._Control:GetBuffIconsByCharacterIndex(self._MechanismCharacterId)

    if XTool.IsTableEmpty(buffIcons) then
        return
    end
    
    XUiHelper.RefreshCustomizedList(self.UiEffectPlayBuff.transform.parent, self.UiEffectPlayBuff, buffIcons and #buffIcons or 0, function(index, obj)
        if self._GridList[index] then
            self._GridList[index]:Open()
            self._GridList[index]:Refresh(self._MechanismCharacterId, index, true)
        else
            local gridCommont = XUiGridMechanismBuff.New(obj, self)
            gridCommont:Open()
            gridCommont:Refresh(self._MechanismCharacterId, index, true)
            self._GridList[index] = gridCommont
        end
        
    end)
end

function XUiPanelMechanismBattleRoleRoomBuff:OnBtnClickEvent()
    local characters = XMVCA.XMechanismActivity:GetMechanismCharacterCfgsByChapterId(self._Control:GetMechanismCurChapterId())
    local index = 1
    ---@param v XTableMechanismCharacter
    for i, v in pairs(characters) do
        if v.Id == self._MechanismCharacterId then
            index = i
            break
        end
    end
    XLuaUiManager.Open('UiMechanismTeamDetail', index, self._MechanismCharacterId)
end

return XUiPanelMechanismBattleRoleRoomBuff