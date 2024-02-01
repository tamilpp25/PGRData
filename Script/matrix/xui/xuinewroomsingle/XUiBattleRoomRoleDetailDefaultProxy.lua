---@class XUiBattleRoomRoleDetailDefaultProxy
local XUiBattleRoomRoleDetailDefaultProxy = XClass(nil, "XUiBattleRoomRoleDetailDefaultProxy")

-- 获取实体数据
-- characterType : XEnumConst.CHARACTER.CharacterType 参数为空时要返回所有实体
-- return : { ... }
function XUiBattleRoomRoleDetailDefaultProxy:GetEntities(characterType)
    return XMVCA.XCharacter:GetOwnCharacterList(characterType)
end

function XUiBattleRoomRoleDetailDefaultProxy:GetFilterJudge()
    return function(groupId, tagValue, entity)
        if not entity.GetCharacterViewModel then return false end
        local characterViewModel = entity:GetCharacterViewModel()
        -- 职业筛选
        if groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Career then
            if tagValue == characterViewModel:GetCareer() then
                return true
            end
        -- 能量元素筛选
        elseif groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Element then
            local obtainElementList = characterViewModel:GetObtainElements()
            for _, element in pairs(obtainElementList) do
                if element == tagValue then
                    return true
                end
            end
        else
            XLog.Error(string.format("XUiBattleRoomRoleDetailDefaultProxy:Filter函数错误，没有处理排序组：%s的逻辑", groupId))
            return false
        end
    end
end

-- 获取左边角色格子代理，默认为XUiBattleRoomRoleGrid
-- 如果只是做一些简单的显示，比如等级读取自定义，可以直接使用AOPOnDynamicTableEventAfter接口去处理也可以
-- return : 继承自XUiBattleRoomRoleGrid的类
function XUiBattleRoomRoleDetailDefaultProxy:GetGridProxy()
    return nil
end

---用于某种特殊玩法需要给grid传特殊参数
---V2.6PS：据点用上了,代码坐标XUiGridEchelonMember:GetProxyInstance(viewData) by 标仔
---@return table 传的必须是table
function XUiBattleRoomRoleDetailDefaultProxy:GetGridExParams()
    return {}
end

-- 获取子面板数据，主要用来增加编队界面自身玩法信息，就不用污染通用的预制体
--[[
    return : {
        assetPath : 资源路径
        proxy : 子面板代理
        proxyArgs : 子面板SetData传入的参数列表
    }
]]
function XUiBattleRoomRoleDetailDefaultProxy:GetChildPanelData()
    return nil
end

-- 根据实体id获取角色视图数据
-- return : XCharacterViewModel
function XUiBattleRoomRoleDetailDefaultProxy:GetCharacterViewModelByEntityId(id)
    if id > 0 then
        local entity = nil
        if XEntityHelper.GetIsRobot(id) then
            entity = XRobotManager.GetRobotById(id)
        else
            entity = XMVCA.XCharacter:GetCharacter(id)
        end
        if entity == nil then
            XLog.Error(string.format("找不到id%s的角色", id))
            return
        end
        return entity:GetCharacterViewModel()
    end
    return nil
end

-- 根据实体id获取角色类型
-- return : XEnumConst.CHARACTER.CharacterType
function XUiBattleRoomRoleDetailDefaultProxy:GetCharacterType(entityId)
    local viewModel = self:GetCharacterViewModelByEntityId(entityId)
    if viewModel then
        return viewModel:GetCharacterType()
    end
    return XEnumConst.CHARACTER.CharacterType.Normal
end

--==============================
 ---@desc 默认选中机体类型页签
 ---@return number 机体类型
--==============================
function XUiBattleRoomRoleDetailDefaultProxy:GetDefaultCharacterType()
    return XEnumConst.CHARACTER.CharacterType.Normal
end

-- 检查队伍里是否有相同的角色
function XUiBattleRoomRoleDetailDefaultProxy:CheckTeamHasSameCharacterId(team, checkEntityId)
    local checkCharacterId = self:GetCharacterViewModelByEntityId(checkEntityId):GetId()
    local viewModel = nil
    for _, entityId in pairs(team:GetEntityIds()) do
        if entityId > 0 then
            viewModel = self:GetCharacterViewModelByEntityId(entityId)
            if viewModel == nil then
                XLog.Error(string.format("队伍数据中存在找不到找到ViewModel的Id : %s, 请合理检查是否逻辑存在问题", entityId))
            elseif viewModel:GetId() == checkCharacterId then
                return true
            end
        end
    end
    return false
end

-- 排序算法，默认队伍>XDataCenter.RoomCharFilterTipsManager.GetSort
-- team : XTeam
-- sortTagType : XRoomCharFilterTipsConfigs.EnumSortTag
function XUiBattleRoomRoleDetailDefaultProxy:SortEntitiesWithTeam(team, entities, sortTagType)
    local inTeamEntities = {}
    for i = #entities, 1, -1 do
        if team:GetEntityIdIsInTeam(entities[i]:GetId()) then
            table.insert(inTeamEntities, entities[i])
            table.remove(entities, i)
        end
    end
    table.sort(entities, function(entityA, entityB)
        local aCharacterViewModel = self:GetCharacterViewModelByEntityId(entityA:GetId())
        local bCharacterViewModel = self:GetCharacterViewModelByEntityId(entityB:GetId())
        return XDataCenter.RoomCharFilterTipsManager.GetSort(aCharacterViewModel:GetId()
            , bCharacterViewModel:GetId(), nil, false, sortTagType)
    end)
    table.sort(inTeamEntities, function(entityA, entityB)
        local aCharacterViewModel = self:GetCharacterViewModelByEntityId(entityA:GetId())
        local bCharacterViewModel = self:GetCharacterViewModelByEntityId(entityB:GetId())
        return XDataCenter.RoomCharFilterTipsManager.GetSort(aCharacterViewModel:GetId()
            , bCharacterViewModel:GetId(), nil, false, sortTagType)
    end)
    for i = #inTeamEntities, 1, -1 do
        table.insert(entities, 1, inTeamEntities[i])
    end
    return entities
end

-- return : bool 是否开启自动关闭检查, number 自动关闭的时间戳(秒), function 每秒更新的回调 function(isClose) isClose标志是否到达结束时间
function XUiBattleRoomRoleDetailDefaultProxy:GetAutoCloseInfo()
    return false
end

-- 获取自定义的角色格子实体，可在通用界面直接追加，可参考XUiSuperTowerBattleRoomRoleDetail
-- return : GameObject
function XUiBattleRoomRoleDetailDefaultProxy:GetRoleDynamicGrid()
    
end

-- 隐藏筛选指定标签
-- return { [XRoomCharFilterTipsConfigs.EnumSortTag.xxx] = true } 即为隐藏
function XUiBattleRoomRoleDetailDefaultProxy:GetHideSortTagDic()
    return nil
end

-- 设置筛选过滤类型和排序类型
-- return1 : XRoomCharFilterTipsConfigs.EnumFilterType
-- return2 : XRoomCharFilterTipsConfigs.EnumSortType
function XUiBattleRoomRoleDetailDefaultProxy:GetFilterTypeAndSortType()
    return XRoomCharFilterTipsConfigs.EnumFilterType.Common, XRoomCharFilterTipsConfigs.EnumSortType.Common
end

-- 检查实体是否为机器人
function XUiBattleRoomRoleDetailDefaultProxy:CheckIsRobot(entityId)
    return XRobotManager.CheckIsRobotId(self:GetCharacterViewModelByEntityId(entityId):GetSourceEntityId())
end

-- 获取是否显示右上角角色详情
function XUiBattleRoomRoleDetailDefaultProxy:GetIsShowRoleDetail()
    return true
end

-- 各自玩法可以重写这里限定编进队伍的条件
function XUiBattleRoomRoleDetailDefaultProxy:CheckCustomLimit(entityId)
    return false
end

-- 获取角色战力
function XUiBattleRoomRoleDetailDefaultProxy:GetRoleAbility(entityId)
    local viewModel = self:GetCharacterViewModelByEntityId(entityId)
    if not viewModel then
        ---@type XCharacterAgency
        local ag = XMVCA:GetAgency(ModuleId.XCharacter)
        return ag:GetCharacterHaveRobotAbilityById(entityId)
    end
    return viewModel:GetAbility()
end

--######################## AOP ########################

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnStartBefore(rootUi)
    
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnStartAfter(rootUi)
    
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnBtnJoinTeamClickedBefore(rootUi)

end

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnBtnJoinTeamClickedAfter(rootUi)
    
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPSetJoinBtnIsActiveAfter(rootUi)
    
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnDynamicTableEventAfter(rootUi, event, index, grid)
    
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPCloseBefore(rootUi)
    
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnCharacterClickBefore(rootUi, index)
    
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPRefreshOperationBtnsBefore()
    return false
end

--截断自定义模型显示逻辑
function XUiBattleRoomRoleDetailDefaultProxy:AOPRefreshModelBefore(rootUi,characterViewModel,sourceEntityId,finishedCallback)

end

function XUiBattleRoomRoleDetailDefaultProxy:CheckIsNeedPractice()
    return true
end

function XUiBattleRoomRoleDetailDefaultProxy:GetFilterControllerConfig(rootUi)
    return nil
end

-- 覆写排序算法的table
function XUiBattleRoomRoleDetailDefaultProxy:GetFilterSortOverrideFunTable()
    return nil
end

function XUiBattleRoomRoleDetailDefaultProxy:GetFilterCharIdFun(entity)
    return nil
end

-- 该界面是否启用q版模型 默认用愚人节检测
function XUiBattleRoomRoleDetailDefaultProxy:CheckUseCuteModel()
    return XDataCenter.AprilFoolDayManager.IsInCuteModelTime()
end

function XUiBattleRoomRoleDetailDefaultProxy:CheckEntityIdIsIsomer(entityId)
    return XMVCA.XCharacter:GetIsIsomer(entityId)
end

return XUiBattleRoomRoleDetailDefaultProxy