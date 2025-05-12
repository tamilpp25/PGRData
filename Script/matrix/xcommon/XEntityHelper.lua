XEntityHelper = XEntityHelper or {}

XEntityHelper.TEAM_MAX_ROLE_COUNT = 3

-- entityId : CharacterId or RobotId
function XEntityHelper.GetCharacterIdByEntityId(entityId)
    if XRobotManager.CheckIsRobotId(entityId) then
        return XRobotManager.GetRobotTemplate(entityId).CharacterId
    else
        return entityId
    end
end

function XEntityHelper.GetIsRobot(entityId)
    return XRobotManager.CheckIsRobotId(entityId)
end

function XEntityHelper.GetRobotCharacterType(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    return XMVCA.XCharacter:GetCharacterType(characterId)
end

function XEntityHelper.GetCharacterName(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    local config = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    if not config then return "none" end
    return config.Name
end

function XEntityHelper.GetCharacterTradeName(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    local config = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    if not config then return "none" end
    return config.TradeName
end

function XEntityHelper.GetCharacterLogName(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    local config = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    if not config then return "none" end
    return config.LogName
end

function XEntityHelper.GetCharacterSmallIcon(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetCharSmallHeadIcon(characterId, 0, true)
end

function XEntityHelper.GetCharacterType(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    return XMVCA.XCharacter:GetCharacterType(characterId)
end

function XEntityHelper.GetCharacterAbility(entityId)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local ability = XEntityHelper.GetIsRobot(entityId) and XRobotManager.GetRobotAbility(entityId) or characterAgency:GetCharacterAbilityById(entityId)
    return math.ceil(ability)
end

function XEntityHelper.GetCharBigRoundnessNotItemHeadIcon(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetCharBigRoundnessNotItemHeadIcon(characterId)
end

-- 根据奖励Id获取第一个奖励的图标
function XEntityHelper.GetRewardIcon(rewardId)
    local rewardList = XRewardManager.GetRewardList(rewardId)
    return XEntityHelper.GetItemIcon(rewardList[1].TemplateId)
end

function XEntityHelper.GetRewardItemId(rewardId, index)
    if index == nil then index = 1 end
    local rewardList = XRewardManager.GetRewardList(rewardId)
    return rewardList[index]
end

function XEntityHelper.GetItemIcon(itemId)
    local result = XGoodsCommonManager.GetGoodsIcon(itemId)
    if result then return result end
    local config = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
    return config.Icon
end

function XEntityHelper.GetItemName(itemId)
    return XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId).Name
end

function XEntityHelper.GetItemQuality(itemId)
    local result = XGoodsCommonManager.GetGoodsDefaultQuality(itemId)
    if result then return result end
    local config = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId)
    return config.Quality or -1
end

function XEntityHelper.GetCharacterHalfBodyImage(entityId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetCharHalfBodyImage(characterId)
end

-- 检查物品数量是否满足指定数量
function XEntityHelper.CheckItemCountIsEnough(itemId, count, showTip)
    if showTip == nil then showTip = true end
    if XDataCenter.ItemManager.GetCount(itemId) < count then
        if showTip then
            XUiManager.TipError(XUiHelper.GetText("AssetsBuyConsumeNotEnough", XDataCenter.ItemManager.GetItemName(itemId)))
        end
        return false
    end
    return true
end

-- 排序物品
--[[
    itemData : {
        TemplateId,
        Count,
    }
]]
function XEntityHelper.SortItemDatas(itemDatas)
    table.sort(itemDatas, function(itemDataA, itemDataB)
        local itemIdA = itemDataA.TemplateId
        local itemIdB = itemDataB.TemplateId
        local itemCountA = itemDataA.Count or 0
        local itemCountB = itemDataB.Count or 0
        local qualityA = XEntityHelper.GetItemQuality(itemIdA)
        local qualityB = XEntityHelper.GetItemQuality(itemIdB)
        -- 品质
        if qualityA ~= qualityB then
            return qualityA > qualityB
        end
        -- id
        if itemIdA ~= itemIdB then
            return itemIdA > itemIdB
        end
        -- 数量
        return itemCountA > itemCountB
    end)
end

function XEntityHelper.CheckIsNeedRoleLimit(stageId, viewModels)
    local limitType = XFubenConfigs.GetStageCharacterLimitType(stageId)
    if limitType == XFubenConfigs.CharacterLimitType.All then
        return false
    end
    if #viewModels <= 0 then
        return true
    end
    local characterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(limitType)
    for _, viewModel in ipairs(viewModels) do
        if viewModel:GetCharacterType() ~= characterType then
            return true
        end
    end
    return false
end

function XEntityHelper.CheckIsNeedCareerLimit(stageId, viewModels)
    local careerLimitTypes = XFubenConfigs.GetStageCareerSuggestTypes(stageId)
    if #careerLimitTypes <= 0 then
        return false
    end
    local isContain, containIndex
    local result = {}
    for _, viewModel in pairs(viewModels) do
        isContain, containIndex = table.contains(careerLimitTypes, viewModel:GetCareer())
        if isContain then
            result[containIndex] = true
        end
    end
    if table.nums(result) == #careerLimitTypes then -- 都满足
        return false
    end
    return true, careerLimitTypes, result
end

-- ids : 可包含机器人或角色Id，返回对应的机器人或角色实体
function XEntityHelper.GetEntityByIds(ids)
    local result = {}
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    for _, id in ipairs(ids) do
        if XEntityHelper.GetIsRobot(id) then
            table.insert(result, XRobotManager.GetRobotById(id))
        else
            table.insert(result, characterAgency:GetCharacter(id))
        end
    end
    return result
end

function XEntityHelper.ClearErrorTeamEntityId(team, checkHasFunc)
    local hasChanged = false
    -- 遍历前设置为不自动保存
    local oldAutoSaveState = team.AutoSave or false
    team:UpdateAutoSave(false)
    
    for pos, entityId in pairs(team:GetEntityIds()) do
        if entityId > 0 and not checkHasFunc(entityId) then
            hasChanged = true
            team:UpdateEntityTeamPos(entityId, pos, false)
        end
    end

    -- 若出现队伍变更，按照原有的保存设置进行保存处理
    team:UpdateAutoSave(oldAutoSaveState)
    if hasChanged then
        team:Save()
    end
    
end

---@return XCharacterViewModel
function XEntityHelper.GetCharacterViewModelByEntityId(id)
    if id > 0 then
        local entity = nil
        if XEntityHelper.GetIsRobot(id) then
            entity = XRobotManager.GetRobotById(id)
        else
            ---@type XCharacterAgency
            local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
            entity = characterAgency:GetCharacter(id)
        end
        if entity == nil then
            XLog.Warning(string.format("找不到id%s的角色", id))
            return
        end
        return entity:GetCharacterViewModel()
    end
    return nil
end