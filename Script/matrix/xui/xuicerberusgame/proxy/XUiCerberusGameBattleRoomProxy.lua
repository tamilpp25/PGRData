local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiCerberusGameBattleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiCerberusGameBattleRoomProxy")

--######################## AOP ########################
function XUiCerberusGameBattleRoomProxy:AOPOnStartBefore(rootUi)
end

function XUiCerberusGameBattleRoomProxy:AOPOnEnableAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
    rootUi.BtnShowInfoToggle.gameObject:SetActiveEx(false)
    rootUi:OnBtnShowInfoToggleClicked(1)
end

function XUiCerberusGameBattleRoomProxy:EnterFight(xTeam, stageId, challengeCount, isAssist)
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    local isAssist = isAssist
    XDataCenter.CerberusGameManager.CerberusGameSetTeamRequest(stageId, xTeam, function ()
        XDataCenter.FubenManager.EnterFight(stageConfig, xTeam, isAssist)
    end)
end

function XUiCerberusGameBattleRoomProxy:GetRoleDetailProxy()
    return require("XUi/XUiCerberusGame/Proxy/XUiCerberusGameBattleRoomRoleDetail")
end

--- func desc
---@param xTeam XCerberusGameTeam
---@param stageId int
function XUiCerberusGameBattleRoomProxy:GetIsCanEnterFight(xTeam, stageId)
    -- 检查队长是否为空
    if xTeam:GetCaptainPosEntityId() == 0 then
        return false, CS.XTextManager.GetText("TeamManagerCheckCaptainNil")
    end
    -- 检查首发位置是否为空
    if xTeam:GetFirstFightPosEntityId() == 0 then
        return false, CS.XTextManager.GetText("TeamManagerCheckFirstFightNil")
    end

    local xConfig = XCerberusGameConfig.CheckIsChallengeStage(stageId)
    local canSeleRoleList = {} -- 可以选择的角色池，含机器人
    if xConfig then
        -- 如果是挑战模式
        canSeleRoleList = XDataCenter.CerberusGameManager.GetCanSelectRoleListForChallengeMode(stageId) or canSeleRoleList
    else
        -- 如果是剧情模式
        canSeleRoleList = XDataCenter.CerberusGameManager.GetCanSelectRoleListForStoryMode(1) or canSeleRoleList
    end

    local canUseCharIdList = {} --可以上阵的构造体机体类型 charId
    for k, xRole in pairs(canSeleRoleList) do
        local id = xRole.Id
        if XRobotManager.CheckIsRobotId(id) then
            id = XRobotManager.GetCharacterId(id)
        end
        canUseCharIdList[id] = true
    end
    -- 获得这个关卡要上阵的角色数量
    local canUseCharacterCount = 0
    local chardesc = ""
    for charId, v in pairs(canUseCharIdList) do
        canUseCharacterCount = canUseCharacterCount + 1
        local charConfig = XMVCA.XCharacter:GetCharacterTemplate(charId)
        local name = charConfig.Name.. "，"
        chardesc = chardesc .. name
    end
    chardesc = XUiHelper.RemoveLastSymbol(chardesc, "，")
    -- 通过比较角色数量限制来判断能否进入战斗
    local teamMemberCount = xTeam:GetEntityCount()
    if teamMemberCount < canUseCharacterCount then
        local errorTip = CS.XTextManager.GetText("CerbrusGameTeamLimit2", chardesc)
        return false, errorTip
    end

    return true
end

function XUiCerberusGameBattleRoomProxy:ClearErrorTeamEntityId(...)
end

function XUiCerberusGameBattleRoomProxy:CheckStageRobotIsUseCustomProxy(robotIds)
    return true
end

function XUiCerberusGameBattleRoomProxy:GetChildPanelData()
    local data = 
    {
        assetPath = CS.XGame.ClientConfig:GetString("UiCerberusGameRoomZd"),
        proxy = require("XUi/XUiCerberusGame/Grid/XUiCerberusGameRoomZd"),
        proxyArgs = { "StageId"}
    }
    return data
end

return XUiCerberusGameBattleRoomProxy