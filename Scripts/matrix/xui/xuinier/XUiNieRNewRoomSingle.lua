-- 尼尔玩法出战界面代理
local XUiNieRNewRoomSingle = {}


function XUiNieRNewRoomSingle.UpdateRoleModel(newRoomSingle, charId, roleModelPanel, pos)
    roleModelPanel:ShowRoleModel()
    local callback = function()
        newRoomSingle.LoadModelCount = newRoomSingle.LoadModelCount - 1
        if newRoomSingle.LoadModelCount <= 0 then
            newRoomSingle.BtnEnterFight:SetDisable(false)
        end
    end
    local robotCfg = XRobotManager.TryGetRobotTemplate(charId)
   
    if not robotCfg then
        newRoomSingle:UpdateRoleModel(charId, roleModelPanel, pos)
    else
        local robotId = charId
        local characterId = XRobotManager.GetCharacterId(robotId)
        local fashionId = robotCfg.FashionId
        local weaponId = robotCfg.WeaponId
        local nierChId = XDataCenter.NieRManager.GetCharacterIdByNieRRobotId(charId)
        if nierChId ~= 0 then
            local nierCharacter = XDataCenter.NieRManager.GetNieRCharacterByCharacterId(nierChId)
            weaponId = nierCharacter:GetNieRWeaponId()
            fashionId = nierCharacter:GetNieRFashionId()
        end

        roleModelPanel:UpdateRobotModel(robotId, characterId, callback, fashionId, weaponId)
    end
end

function XUiNieRNewRoomSingle.SetEditBattleUiTeam(newRoomSingle)
    XDataCenter.NieRManager.SetPlayerTeamData(newRoomSingle.CurTeam, newRoomSingle.CurrentStageId)
end

return XUiNieRNewRoomSingle