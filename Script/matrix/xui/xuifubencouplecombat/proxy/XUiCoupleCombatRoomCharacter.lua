-- 双人玩法选人列表界面代理
local XUiCoupleCombatRoomCharacter = {}
local XUiPanelFeature = require("XUi/XUiFubenCoupleCombat/ChildView/XUiPanelFeature")

--返回默认开启页签
local GetDefaultSelectIndex = function(characterLimitType, tabBtnIndex, robotIdList, stageId, selectCharId)
    --出战界面选择的位置有角色时，默认开启角色所在的页签
    if XTool.IsNumberValid(selectCharId) then
        if XRobotManager.CheckIsRobotId(selectCharId) then
            return tabBtnIndex.Robot
        end
        return XMVCA.XCharacter:GetCharacterType(selectCharId) == XCharacterConfigs.CharacterType.Isomer and tabBtnIndex.Isomer or tabBtnIndex.Normal
    end

    local defaultTabBtnIndex
    local characterType
    if characterLimitType == XFubenConfigs.CharacterLimitType.Normal or characterLimitType == XFubenConfigs.CharacterLimitType.IsomerDebuff then
        characterType = XCharacterConfigs.CharacterType.Normal
        defaultTabBtnIndex = tabBtnIndex.Normal
    elseif characterLimitType == XFubenConfigs.CharacterLimitType.Isomer or characterLimitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        characterType = XCharacterConfigs.CharacterType.Isomer
        defaultTabBtnIndex = tabBtnIndex.Isomer
    end

    if characterType then
        local curFeatureMathchMaxCount = 0
        local featureMathchCount = 0
        local recommendCharId           --推荐角色的Id
        local recommendCharAbility = 0  --推荐角色的战力
        local ability
        local robotAndCharList = XDataCenter.CharacterManager.GetRobotAndCharacterIdList(robotIdList, characterType)
        for _, charId in ipairs(robotAndCharList) do
            featureMathchCount = XFubenCoupleCombatConfig.GetFeatureMatchCount(stageId, charId)
            ability = XRobotManager.CheckIsRobotId(charId) and XRobotManager.GetRobotAbility(charId) or XDataCenter.CharacterManager.GetCharacterAbilityById(charId)

            --未锁定角色的角色特性与环境特性的重合数量多的优先，重合数量相同时战力高的优先
            if (not XDataCenter.FubenCoupleCombatManager.CheckCharacterUsed(charId)) and 
                (featureMathchCount > curFeatureMathchMaxCount or (featureMathchCount == curFeatureMathchMaxCount and ability > recommendCharAbility)) then
                curFeatureMathchMaxCount = featureMathchCount
                recommendCharId = charId
                recommendCharAbility = ability
            end
        end

        if XRobotManager.CheckIsRobotId(recommendCharId) then
            defaultTabBtnIndex = tabBtnIndex.Robot
        end
    end

    defaultTabBtnIndex = defaultTabBtnIndex or tabBtnIndex.Robot

    if defaultTabBtnIndex == tabBtnIndex.Robot then
        XUiManager.TipText("CoupleCombatRecommonTips")
    elseif defaultTabBtnIndex == tabBtnIndex.Isomer and not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer) then
        defaultTabBtnIndex = tabBtnIndex.Normal
    end

    return defaultTabBtnIndex
end

function XUiCoupleCombatRoomCharacter.InitCharacterTypeBtns(roomCharacterUi, teamCharIdMap, tabBtnIndex)
    roomCharacterUi.BtnTabRobot.gameObject:SetActiveEx(true)

    local lockShougezhe = not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
    roomCharacterUi.BtnTabShougezhe:SetDisable(lockShougezhe)

    local robotIdList = roomCharacterUi.RobotIdList
    local characterLimitType = roomCharacterUi.CharacterLimitType
    local stageId = roomCharacterUi.StageId
    local teamCharIdMap = roomCharacterUi.TeamCharIdMap
    local selectCharId = roomCharacterUi.TeamSelectPos and teamCharIdMap[roomCharacterUi.TeamSelectPos] or 0
    local defaultTabBtnIndex = GetDefaultSelectIndex(characterLimitType, tabBtnIndex, robotIdList, stageId, selectCharId)
    roomCharacterUi.PanelCharacterTypeBtns:SelectIndex(defaultTabBtnIndex)
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
        local featureList = XFubenCoupleCombatConfig.GetCharacterFeature(id)
        for _, v in ipairs(featureList) do
            if stageFeatureDic[v] then
                matchCountDic[id] = matchCountDic[id] + 1
            end
        end
    end

    local abilityA, abilityB
    table.sort(charIdList, function(a, b)
        abilityA = XRobotManager.CheckIsRobotId(a) and XRobotManager.GetRobotAbility(a) or XDataCenter.CharacterManager.GetCharacterAbilityById(a)
        abilityB = XRobotManager.CheckIsRobotId(b) and XRobotManager.GetRobotAbility(b) or XDataCenter.CharacterManager.GetCharacterAbilityById(b)
        
        if XDataCenter.FubenCoupleCombatManager.CheckCharacterUsed(stageId, a) ~=
                XDataCenter.FubenCoupleCombatManager.CheckCharacterUsed(stageId, b) then    --未使用的角色优先
            return XDataCenter.FubenCoupleCombatManager.CheckCharacterUsed(stageId, b)
        elseif matchCountDic[a] ~= matchCountDic[b] then    --角色特性与环境特性的重合数量从高到低
            return matchCountDic[a] > matchCountDic[b]
        elseif abilityA ~= abilityB then    --战力从高到低
            return abilityA > abilityB
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
        roomCharacterUi.PanelFeatureStage:Refresh(XDataCenter.FubenCoupleCombatManager.GetStageFeatureIdList(roomCharacterUi.StageId), {})

        --重写按钮回调
        roomCharacterUi.BtnPartner.CallBack = function()
            if XRobotManager.CheckIsRobotId(roomCharacterUi.CurCharacter.Id) then
                XUiManager.TipText("RobotRefusePartner")
                return
            end
            roomCharacterUi:OnCarryPartnerClick()
        end
        roomCharacterUi.BtnFashion.CallBack = function()
            roomCharacterUi:OnBtnFashionClick()
        end
        roomCharacterUi.BtnConsciousness.CallBack = function()
            if XRobotManager.CheckIsRobotId(roomCharacterUi.CurCharacter.Id) then
                XUiManager.TipText("RobotRefuseAwareness")
                return
            end
            roomCharacterUi:OnBtnConsciousnessClick()
        end
        roomCharacterUi.BtnWeapon.CallBack = function()
            if XRobotManager.CheckIsRobotId(roomCharacterUi.CurCharacter.Id) then
                XUiManager.TipText("RobotRefuseWeapon")
                return
            end
            roomCharacterUi:OnBtnWeaponClick()
        end
        roomCharacterUi:RegisterClickEvent(roomCharacterUi.BtnJoinTeam, function()
            if roomCharacterUi:IsSameCharIdInTeam(roomCharacterUi.CurCharacter.Id) then
                XUiManager.TipText("ElectricDeploySameCharacter")
                return
            end
            roomCharacterUi:OnBtnJoinTeamClick()
        end, true)
    end
    roomCharacterUi.PanelFeatureElement.gameObject:SetActiveEx(not isEmpty)
    
    roomCharacterUi.BtnQuitTeam.gameObject:SetActiveEx(false)
    roomCharacterUi.BtnJoinTeam.gameObject:SetActiveEx(false)

    roomCharacterUi.PanelRoleModel.gameObject:SetActiveEx(not isEmpty)
    roomCharacterUi.PanelRoleContent.gameObject:SetActiveEx(not isEmpty)
    roomCharacterUi.PanelEmptyList.gameObject:SetActiveEx(isEmpty)
    roomCharacterUi.BtnPartner.gameObject:SetActiveEx(not isEmpty)
    roomCharacterUi.BtnFashion.gameObject:SetActiveEx(not isEmpty)
    roomCharacterUi.BtnConsciousness.gameObject:SetActiveEx(not isEmpty)
    roomCharacterUi.BtnWeapon.gameObject:SetActiveEx(not isEmpty)
end

function XUiCoupleCombatRoomCharacter.UpdatePanelEmptyList(roomCharacterUi, charId)
    local characterId = XRobotManager.GetCharacterId(charId)
    local features = XFubenCoupleCombatConfig.GetCharacterFeature(characterId)
    
    --v1.32 角色特性与推荐特性重合刷新高亮
    local matchDic = XDataCenter.FubenCoupleCombatManager.GetFeatureMatchOneChar(roomCharacterUi.StageId, characterId)
    roomCharacterUi.PanelFeatureCharacter:Refresh(features, matchDic, characterId)
    roomCharacterUi.PanelFeatureStage:Refresh(XDataCenter.FubenCoupleCombatManager.GetStageFeatureIdList(roomCharacterUi.StageId), matchDic)
end

function XUiCoupleCombatRoomCharacter.UpdateTeamBtn(roomCharacterUi, charId)
    local id = charId
    local isRobot = XRobotManager.CheckIsRobotId(id)
    local useFashion = true
    if isRobot then
        useFashion = XRobotManager.CheckUseFashion(id)
    end
    roomCharacterUi.BtnPartner:SetDisable(isRobot, not isRobot)
    roomCharacterUi.BtnFashion:SetDisable(not useFashion, useFashion)
    roomCharacterUi.BtnConsciousness:SetDisable(isRobot, not isRobot)
    roomCharacterUi.BtnWeapon:SetDisable(isRobot, not isRobot)
   
    if not (roomCharacterUi.TeamCharIdMap and next(roomCharacterUi.TeamCharIdMap)) then
        roomCharacterUi.BtnJoinTeam.gameObject:SetActiveEx(false)
        return
    end

    --在当前操作的队伍中
    local isInTeam = roomCharacterUi:IsInTeam(charId)
    local hideBtnJoinTeam = isInTeam or XDataCenter.FubenCoupleCombatManager.CheckCharacterUsed(roomCharacterUi.StageId, charId)
    roomCharacterUi.BtnQuitTeam.gameObject:SetActiveEx(isInTeam)
    roomCharacterUi.BtnJoinTeam.gameObject:SetActiveEx(not hideBtnJoinTeam)
end

function XUiCoupleCombatRoomCharacter.GetCharInfo(roomCharacterUi, charId)
    local charInfo = {}

    if XRobotManager.CheckIsRobotId(charId) then
        charInfo.Id = charId
        charInfo.IsRobot = true
        charInfo.Ability = XRobotManager.GetRobotAbility(charId)
    else
        charInfo = XDataCenter.CharacterManager.GetCharacter(charId) or {}
    end

    return charInfo
end

function XUiCoupleCombatRoomCharacter.RefreshCharacterTypeTips(roomCharacterUi)
    roomCharacterUi.PanelRequireCharacter.gameObject:SetActiveEx(false)
end

function XUiCoupleCombatRoomCharacter.OnResetEvent()
    XLuaUiManager.RunMain()
    XDataCenter.FubenHackManager.OnActivityEnd()
end

return XUiCoupleCombatRoomCharacter