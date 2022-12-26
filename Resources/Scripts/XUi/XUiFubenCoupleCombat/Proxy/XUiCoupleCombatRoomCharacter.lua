-- 双人玩法选人列表界面代理
local XUiCoupleCombatRoomCharacter = {}
local XUiPanelFeature = require("XUi/XUiFubenCoupleCombat/ChildView/XUiPanelFeature")

function XUiCoupleCombatRoomCharacter.InitCharacterTypeBtns(roomCharacterUi, teamCharIdMap, TabBtnIndex)
    roomCharacterUi.BtnTabShougezhe.gameObject:SetActiveEx(false)
    roomCharacterUi.PanelCharacterTypeBtns:SelectIndex(TabBtnIndex.Normal)
end

function XUiCoupleCombatRoomCharacter.SortList(roomCharacterUi, charIdList)
    local indexDic = {}
    for i, v in ipairs(charIdList) do
        indexDic[v] = i
    end

    local matchCountDic = {}
    local stageFeatureDic = {}
    local stageId = roomCharacterUi.StageId
    local stageInterInfo = XFubenCoupleCombatConfig.GetStageInfo(stageId)
    if not stageInterInfo then return charIdList end
    for _, v in ipairs(stageInterInfo.Feature) do
        stageFeatureDic[v] = true
    end

    for _, id in ipairs(charIdList) do
        matchCountDic[id] = 0
        local allMatch = true
        local memberInfo = XFubenCoupleCombatConfig.GetRobotInfo(id)
        if memberInfo then
            for _, v in ipairs(memberInfo.Feature) do
                if stageFeatureDic[v] then
                    matchCountDic[id] = matchCountDic[id] + 1
                else
                    allMatch = false
                end
            end
            if allMatch then
                matchCountDic[id] = matchCountDic[id] + XMath.IntMax()
            end
        end
    end

    table.sort(charIdList, function(a, b)
        if XDataCenter.FubenCoupleCombatManager.CheckRobotUsed(stageId, a) ~=
                XDataCenter.FubenCoupleCombatManager.CheckRobotUsed(stageId, b) then
            return XDataCenter.FubenCoupleCombatManager.CheckRobotUsed(stageId, b)
        elseif matchCountDic[a] ~= matchCountDic[b] then
            return matchCountDic[a] > matchCountDic[b]
        else
            return indexDic[a] < indexDic[b]
        end
    end)

    return charIdList
end

function XUiCoupleCombatRoomCharacter.SetPanelEmptyList(roomCharacterUi, isEmpty)
    if not roomCharacterUi.PanelFeatureStage then
        roomCharacterUi.PanelFeatureStage = XUiPanelFeature.New(roomCharacterUi, roomCharacterUi.StageFeature)
        roomCharacterUi.PanelFeatureCharacter = XUiPanelFeature.New(roomCharacterUi, roomCharacterUi.CharacterFeature)
        local stageInterInfo = XFubenCoupleCombatConfig.GetStageInfo(roomCharacterUi.StageId)
        if not stageInterInfo then return end
        roomCharacterUi.PanelFeatureStage:Refresh(stageInterInfo.Feature, {})

        roomCharacterUi.BtnConsciousness.gameObject:SetActiveEx(false)
        roomCharacterUi.BtnFashion.gameObject:SetActiveEx(false)
        roomCharacterUi.BtnWeapon.gameObject:SetActiveEx(false)
        roomCharacterUi.BtnPartner.gameObject:SetActiveEx(false)
    end
    roomCharacterUi.PanelFeatureElement.gameObject:SetActiveEx(not isEmpty)
    
    roomCharacterUi.BtnQuitTeam.gameObject:SetActiveEx(false)
    roomCharacterUi.BtnJoinTeam.gameObject:SetActiveEx(false)

    roomCharacterUi.PanelRoleModel.gameObject:SetActiveEx(not isEmpty)
    roomCharacterUi.PanelRoleContent.gameObject:SetActiveEx(not isEmpty)
    roomCharacterUi.PanelEmptyList.gameObject:SetActiveEx(isEmpty)
end

function XUiCoupleCombatRoomCharacter.UpdatePanelEmptyList(roomCharacterUi, charId)
    local robotInfo = XFubenCoupleCombatConfig.GetRobotInfo(charId)
    if not robotInfo then return end

    roomCharacterUi.PanelFeatureCharacter:Refresh(robotInfo.Feature, {})
    --roomCharacterUi.BtnJoinTeam.gameObject:SetActiveEx(roomCharacterUi.NeedShowBtnJoinTeam)
end

function XUiCoupleCombatRoomCharacter.UpdateTeamBtn(roomCharacterUi, charId)
    if not (roomCharacterUi.TeamCharIdMap and next(roomCharacterUi.TeamCharIdMap)) then
        roomCharacterUi.BtnJoinTeam.gameObject:SetActiveEx(false)
        return
    end

    --在当前操作的队伍中
    local isInTeam = roomCharacterUi:IsInTeam(charId)
    local hideBtnJoinTeam = isInTeam or XDataCenter.FubenCoupleCombatManager.CheckRobotUsed(roomCharacterUi.StageId, charId)
    roomCharacterUi.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
    roomCharacterUi.BtnJoinTeam.gameObject:SetActiveEx(not hideBtnJoinTeam)
end

function XUiCoupleCombatRoomCharacter.GetCharInfo(roomCharacterUi, charId)
    local charInfo = {}

    if XFubenCoupleCombatConfig.GetRobotInfo(charId) then
        charInfo.Id = charId
        charInfo.IsRobot = true
        charInfo.HideTryTag = true
        if XDataCenter.FubenCoupleCombatManager.CheckRobotUsed(roomCharacterUi.StageId, charId) then
            charInfo.ShowText = CSXTextManagerGetText("CoupleCombatRobotUsed")
        end
        --charInfo.Ability = XRobotManager.GetRobotAbility(charId)
    end

    return charInfo
end

function XUiCoupleCombatRoomCharacter.OnResetEvent()
    XLuaUiManager.RunMain()
    XDataCenter.FubenHackManager.OnActivityEnd()
end

return XUiCoupleCombatRoomCharacter