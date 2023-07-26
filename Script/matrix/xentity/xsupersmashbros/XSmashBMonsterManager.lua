--===========================
--超限乱斗怪物组管理器
--模块负责：吕天元
--===========================
local XSmashBMonsterManager = {}
local MonsterGroups
local MonsterGroupDicById
local Monsters
local MonsterDicById
local MonsterScript = require("XEntity/XSuperSmashBros/XSmashBMonster")
local IsAscendOrder
--=================
--筛选方法(筛选界面配套)
--=================
local SortFunctionDic = {
    [XRoomCharFilterTipsConfigs.EnumSortTag.Ability] = function(monsterA, monsterB)
        if IsAscendOrder then
            return monsterA:GetAbility() > monsterB:GetAbility()
        else
            return monsterA:GetAbility() < monsterB:GetAbility()
        end
    end,
    [XRoomCharFilterTipsConfigs.EnumSortTag.SSBMonster] = function(monsterA, monsterB)
        if IsAscendOrder then
            return monsterA:GetMonsterType() > monsterB:GetMonsterType()
        else
            return monsterA:GetMonsterType() < monsterB:GetMonsterType()
        end
    end,
    [XRoomCharFilterTipsConfigs.EnumSortTag.SSBMonsterDefault] = function(monsterA, monsterB)
        if IsAscendOrder then
            return monsterA:GetMonsterType() >= monsterB:GetMonsterType() and monsterA:GetAbility() > monsterB:GetAbility()
        else
            return monsterA:GetMonsterType() <= monsterB:GetMonsterType() and monsterA:GetAbility() < monsterB:GetAbility()
        end
    end
}
--=============
--初始化管理器
--=============
function XSmashBMonsterManager.Init(activityId)
    MonsterGroups = nil
    MonsterGroupDicById = nil
    Monsters = nil
    MonsterDicById = nil
end
--=============
--刷新后台推送活动数据
--=============
function XSmashBMonsterManager.RefreshNotifyMonsterData(data)

end
--=============
--刷新怪物组胜利次数数据
--=============
function XSmashBMonsterManager.RefreshMonsterGroupWinCount(winCountList)
    for _, monsterGroupWinCount in pairs(winCountList or {}) do
        local monsterGroup = XSmashBMonsterManager.GetMonsterGroupById(monsterGroupWinCount.Id)
        if monsterGroup then
            monsterGroup:SetWinCount(monsterGroupWinCount.WinCount)
        end
    end
end
--=============
--根据怪物Id获取怪物对象
--@param
--monsterId : 怪物Id SuperSmashBrosMonster Id
--=============
function XSmashBMonsterManager.GetMonsterById(monsterId)
    if not Monsters then
        XSmashBMonsterManager.CreateMonsters()
    end
    return MonsterDicById[monsterId]
end
--=============
--创建所有怪物对象
--=============
function XSmashBMonsterManager.CreateMonsters()
    Monsters = {}
    MonsterDicById = {}
    local allMonsters = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.MonsterConfig)
    local script = require("XEntity/XSuperSmashBros/XSmashBMonster")
    for id, monsterCfg in pairs(allMonsters) do
        local monster = script.New(monsterCfg)
        table.insert(Monsters, monster)
        MonsterDicById[id] = monster
    end
end
--=============
--根据怪物组Id获取怪物组对象
--@param
--monsterId : 怪物Id SuperSmashBrosMonster Id
--=============
function XSmashBMonsterManager.GetMonsterGroupById(monsterGroupId)
    if not MonsterGroups then
        XSmashBMonsterManager.CreateMonsterGroups()
    end
    return MonsterGroupDicById[monsterGroupId]
end
--=============
--创建所有怪物对象
--=============
function XSmashBMonsterManager.CreateMonsterGroups()
    MonsterGroups = {}
    MonsterGroupDicById = {}
    local allMonsterGroups = XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.MonsterGroupConfig)
    local script = require("XEntity/XSuperSmashBros/XSmashBMonsterGroup")
    for id, monsterGroupCfg in pairs(allMonsterGroups) do
        local monsterGroup = script.New(monsterGroupCfg)
        table.insert(MonsterGroups, monsterGroup)
        MonsterGroupDicById[id] = monsterGroup
    end
end
--=============
--根据模式Id获取已首通的怪物组数量
--@param
--modeId : 模式Id SuperSmashBrosMode Id
--=============
function XSmashBMonsterManager.GetPassMonstersNumByModeId(modeId)
    local monsterList = XSmashBMonsterManager.GetMonsterGroupListByModeId(modeId)
    local result = 0
    for _, monsterGroup in pairs(monsterList) do
        if monsterGroup:CheckIsClear() then
            result = result + 1
        end
    end
    return result
end
--=============
--根据怪物Id列表获取怪物对象组
--=============
function XSmashBMonsterManager.GetMonstersByIdList(idList)
    local result = {}
    for _, id in pairs(idList or {}) do
        local monster = XSmashBMonsterManager.GetMonsterById(id)
        if monster then
            table.insert(result, monster)
        end
    end
    return result
end
--=============
--根据模式Id获取所有怪物组
--@param
--modeId : 模式Id SuperSmashBrosMode Id
--=============
function XSmashBMonsterManager.GetMonsterGroupListByModeId(modeId)
    local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(modeId)
    local allGroups = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Group2MonsterGroupDic, mode:GetMonsterLibraryId(), true)
    local result = {}
    for _, group in pairs(allGroups) do
        local temp = XSmashBMonsterManager.GetMonsterGroupById(group.Id)
        if temp then
            table.insert(result, temp)
        end
    end
    table.sort(result, function(monsterGroupA, monsterGroupB)
            return monsterGroupA:GetId() < monsterGroupB:GetId()
        end)
    return result
end
--=============
--根据Id列表获取所有怪物组列表
--@param
--monsterGourpIdList : MonsterGroup Id列表
--=============
function XSmashBMonsterManager.GetMonsterGroupListByIdList(monsterGourpIdList)
    local result = {}
    for _, id in pairs(monsterGourpIdList or {}) do
        local monsterGroup = MonsterGroupDicById[id or 0]
        if monsterGroup then
            table.insert(result, monsterGroup)
        end
    end
    return result
end
--=============
--怪物列表排序(排序筛选界面用)
--@param
--monsters : 要排序MonsterGroup列表
--sortTagType :检索标签类型
--isAscendOrder : true 升序 false 降序
--=============
function XSmashBMonsterManager.SortMonsters(monsters, sortTagType, isAscendOrder)
    if isAscendOrder == nil then isAscendOrder = true end
    IsAscendOrder = isAscendOrder
    if not sortTagType or (sortTagType == XRoomCharFilterTipsConfigs.EnumSortTag.Default) then
        sortTagType = XRoomCharFilterTipsConfigs.EnumSortTag.Ability
    end
    local clearMonsters = {}
    local isFirstFightMonsters = {}
    for key, monster in pairs(monsters) do
        if monster:CheckIsClear() then
            table.insert(clearMonsters, monster)
        else
            table.insert(isFirstFightMonsters, monster)
        end
    end
    table.sort(clearMonsters, SortFunctionDic[sortTagType])
    table.sort(isFirstFightMonsters, SortFunctionDic[sortTagType])

    return appendArray(isFirstFightMonsters, clearMonsters)
end
--=============
--进入模式处理，选择随机怪兽
--@param
--monsterIdList : 选择的怪兽Id列表
--stageId : 选择的地图Id，用于筛选掉不符合地图的怪兽
--modeId : 选择的模式Id
--=============
function XSmashBMonsterManager.SelectRandomMonster(monsterIdList, stageId, modeId)
    if not MonsterGroups then
        XSmashBMonsterManager.CreateMonsterGroups()
    end
    local monsterGroup = XSmashBMonsterManager.GetMonsterGroupListByModeId(modeId)
    local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(modeId)

    local monsterNum = #monsterGroup --总的怪物组数目
    local monsterIdDic = {} --队伍中已经被选择的怪物组Id字典
    local bossLimit = mode:GetBossLimit()
    local bossNum = 0 --统计已选定的怪物组中的首领级怪物组数目
    for _, monsterId in pairs(monsterIdList) do
        if monsterId > 0 then
            monsterIdDic[monsterId] = true --已经选择了的怪物组放入字典中
            local monster = XSmashBMonsterManager.GetMonsterGroupById(monsterId)
            local isBoss = monster:GetMonsterType() == XSuperSmashBrosConfig.MonsterType.Boss
            bossNum = bossNum + (isBoss and 1 or 0)
        end
    end
    local isSelectBoss = bossNum < bossLimit --是否需要选择首领级怪物
    --分开首战，非首战怪物组
    local firstBattleMonsterDic = {} --首战怪物组
    local clearBattleMonsterDic = {} --非首战怪物组
    for _, monster in pairs(monsterGroup) do
        if monsterIdDic[monster:GetId()] then
            goto continue
        end
        local isStageLimit = monster:CheckLimitStage(stageId) --检查怪物组是否受地图限制出战
        if isStageLimit then
            goto continue
        end
        local isBoss = monster:GetMonsterType() == XSuperSmashBrosConfig.MonsterType.Boss
        if not isSelectBoss and isBoss then
            goto continue
        end
        local isFirst = not monster:CheckIsClear()
        if isFirst then
            table.insert(firstBattleMonsterDic, monster)
        else
            table.insert(clearBattleMonsterDic, monster)
        end
        :: continue ::
    end

    local resultList = {}
    for index, monsterId in pairs(monsterIdList) do
        --按以下流程随机
        --1.检测是不是随机位
        --1-1.是随机位
        --1-1-1.先检查首战怪物组中有没成员，有的话从中随机，随机一个数字
        --1-1-1-1.检查是否超过最多选择的首领级怪物组数目
        --1-1-1-2.超过而且随机的是首领的话从首战怪物组字典删去该项，重新到步骤1-1
        --1-1-1-3.不超过而且是首领的话把选中首领怪物组的数目+1
        --1-1-1-4.随机成功，记录在队伍Id字典和结果Id中，之后从首战怪物组字典删去该项
        --1-1-1-5.给随机位赋值结果Id
        --1-1-2.检查复刷怪物组中有没成员，具体内部步骤同1-1-1-X首战怪物组
        --1-1-3.若首战怪物组和复刷怪物组中皆没有成员，给随机位赋值0(空位)
        if monsterId == XSuperSmashBrosConfig.PosState.Random or
            monsterId == XSuperSmashBrosConfig.PosState.OnlyRandom then
            local result = 0
            isSelectBoss = bossNum < bossLimit --是否需要选择首领级怪物
            :: GroupRandom ::
            if #firstBattleMonsterDic > 0 then
                local random = math.random(1, #firstBattleMonsterDic)
                local isBoss = firstBattleMonsterDic[random]:GetMonsterType() == XSuperSmashBrosConfig.MonsterType.Boss
                if not isSelectBoss and isBoss then
                    table.remove(firstBattleMonsterDic, random)
                    goto GroupRandom
                elseif isBoss then
                    bossNum = bossNum + 1
                end
                local randomId = firstBattleMonsterDic[random]:GetId()
                monsterIdDic[randomId] = true
                table.remove(firstBattleMonsterDic, random)
                result = randomId
            elseif #clearBattleMonsterDic > 0 then
                local random = math.random(1, #clearBattleMonsterDic)
                local isBoss = clearBattleMonsterDic[random]:GetMonsterType() == XSuperSmashBrosConfig.MonsterType.Boss
                if not isSelectBoss and isBoss then
                    table.remove(clearBattleMonsterDic, random)
                    goto GroupRandom
                elseif isBoss then
                    bossNum = bossNum + 1
                end
                local randomId = clearBattleMonsterDic[random]:GetId()
                monsterIdDic[randomId] = true
                table.remove(clearBattleMonsterDic, random)
                result = randomId
            else
                result = 0
            end
            resultList[index] = result
        elseif monsterId > 0 then
            resultList[index] = monsterId
        else
            resultList[index] = 0
        end
    end
    return resultList
end
--===================
--设置出战怪物组剩余生命值
--@params:
--enemyTeam : 怪物组Id列表
--monsterProgress : 
--===================
function XSmashBMonsterManager.SetMonsterTeamLeftHp(enemyTeam, monsterProgress, monsterHpResultList, monsterBattleNum)
    for index, enemyId in pairs(enemyTeam or {}) do
        local monsterGroup = XSmashBMonsterManager.GetMonsterGroupById(enemyId)
        if monsterGroup and index < monsterProgress then
            monsterGroup:SetHpLeft(0)
        elseif monsterGroup and monsterHpResultList and index < (monsterProgress + monsterBattleNum) then
            --这里剩余怪物同一ID的怪物状态刷新不能记录哪个怪兽属于哪个组
            --这种情况会发生计算错误，需要策划配置时回避
            local total = 0 --怪兽组总血量
            local left = 0 --怪兽组总剩余血量
            local monsterIds = {}
            for _, monsterId in pairs(monsterGroup:GetMonsterIdList()) do
                local monster = XSmashBMonsterManager.GetMonsterById(monsterId)
                if monster then
                    monsterIds[monster:GetMonsterId()] = true
                end
            end
            for _, info in pairs(monsterHpResultList or {}) do
                if monsterIds[info.NpcId] and info.AttrTable[1] then
                    total = total + info.AttrTable[1].MaxValue
                    left = left + info.AttrTable[1].Value
                end
            end
            monsterGroup:SetHpLeft((total == 0 and 100) or (left / total * 100))
        else
            monsterGroup:SetHpLeft(100)
        end
    end
end
--===================
--根据怪物组Id列表重置怪物组剩余生命值
--===================
function XSmashBMonsterManager.ResetMonsterGroupHpLeftByIdList(idList)
    for _, monsterGroupId in pairs(idList or {}) do
        if monsterGroupId > 0 then
            local monsterGroup = XSmashBMonsterManager.GetMonsterGroupById(monsterGroupId)
            if monsterGroup then
                monsterGroup:SetHpLeft(100)
            end
        end
    end
end

return XSmashBMonsterManager