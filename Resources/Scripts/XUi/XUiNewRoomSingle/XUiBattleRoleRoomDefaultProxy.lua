local XUiBattleRoleRoomDefaultProxy = XClass(nil, "XUiBattleRoleRoomDefaultProxy")

function XUiBattleRoleRoomDefaultProxy:GetCharacterViewModelByEntityId(id)
    return nil
end

function XUiBattleRoleRoomDefaultProxy:GetRoleAbility(entityId)
    local viewModel = self:GetCharacterViewModelByEntityId(entityId)
    if viewModel then
        return viewModel:GetAbility()
    end
    return 0
end

function XUiBattleRoleRoomDefaultProxy:GetPartnerByEntityId(id)
    return nil
end

function XUiBattleRoleRoomDefaultProxy:GetIsShowRoleBGEffect()
    return true
end

function XUiBattleRoleRoomDefaultProxy:GetChildPanelData()
    return nil
end

function XUiBattleRoleRoomDefaultProxy:GetRoleDetailProxy()
    return nil
end

-- team : XTeam
function XUiBattleRoleRoomDefaultProxy:GetIsCanEnterFight(team)
    -- 检查队长是否为空
    if team:GetCaptainPosEntityId() == 0 then
        return false, CS.XTextManager.GetText("TeamManagerCheckCaptainNil")
    end
    -- 检查首发位置是否为空
    if team:GetFirstFightPosEntityId() == 0 then
        return false, CS.XTextManager.GetText("TeamManagerCheckFirstFightNil")
    end
    return true
end

-- team : XTeam
-- stageId : number
function XUiBattleRoleRoomDefaultProxy:EnterFight(team, stageId)
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    local teamId = team:GetId()
    local isAssist = false
    local challengeCount = 1
    XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount)
end

function XUiBattleRoleRoomDefaultProxy:GetAutoCloseInfo()
    return false
end

--######################## AOP ########################

function XUiBattleRoleRoomDefaultProxy:AOPOnStartBefore(rootUi)
    
end

function XUiBattleRoleRoomDefaultProxy:AOPOnStartAfter(rootUi)
    
end

return XUiBattleRoleRoomDefaultProxy