--===========================
--超限乱斗玩家角色管理器
--模块负责：吕天元
--===========================
local XSmashBRoleManager = {}
local Roles
local RoleDicById
local EggRobotList = {} --记录所有的彩蛋机器人 key = robotId , value = role
local RoleScript = require("XEntity/XSuperSmashBros/XSmashBRole") --超限乱斗角色数据
local XRobot = require("XEntity/XRobot/XRobot")
local IsAscendOrder = true
local SortFunctionDic = {
    [XRoomCharFilterTipsConfigs.EnumSortTag.Level] = function(roleA, roleB)
        if IsAscendOrder then
            return roleA:GetLevel() > roleB:GetLevel()
        else
            return roleA:GetLevel() < roleB:GetLevel()
        end
    end,
    [XRoomCharFilterTipsConfigs.EnumSortTag.Quality] = function(roleA, roleB)
        if IsAscendOrder then
            return roleA:GetQuality() > roleB:GetQuality()
        else
            return roleA:GetQuality() < roleB:GetQuality()
        end
    end,
    [XRoomCharFilterTipsConfigs.EnumSortTag.Ability] = function(roleA, roleB)
        if IsAscendOrder then
            return roleA:GetAbility() > roleB:GetAbility()
        else
            return roleA:GetAbility() < roleB:GetAbility()
        end
    end,
}
--=============
--初始化管理器
--=============
function XSmashBRoleManager.Init()
    Roles = {}
    RoleDicById = {}
    XSmashBRoleManager.RegisterEvents()
end
--=============
--刷新后台推送活动数据
--=============
function XSmashBRoleManager.RefreshNotifyRoleData(data)
    --TODO
end
--=============
--根据角色Id获取角色对象
--@param
--roleId : 角色Id,若是用户角色则传入CharacterId，机器人传入RobotId
--=============
function XSmashBRoleManager.GetRoleById(roleId)
    if XTool.IsTableEmpty(Roles) then
        XSmashBRoleManager.GenerateRoleData()
    end
    return RoleDicById[roleId]
end
--=============
--注册事件
--=============
function XSmashBRoleManager.RegisterEvents()
    --玩家角色增加时，增加成员
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_ADD_SYNC, XSmashBRoleManager.OnCharacterAdd)
end
--=============
--玩家角色增加时
--=============
function XSmashBRoleManager.OnCharacterAdd(character)
    if character == nil then return end
    if RoleDicById[character.Id] then return end
    -- 防止错误判断Roles，新增角色时先调用一遍初始化
    if XTool.IsTableEmpty(Roles) then
        XSmashBRoleManager.GenerateRoleData()
    end
    XSmashBRoleManager.AddNewRole(character)
end
--=============
--收集角色信息并添加
--=============
function XSmashBRoleManager.GenerateRoleData()
    local characters = XDataCenter.CharacterManager.GetOwnCharacterList()
    -- 拥有角色
    for _, character in ipairs(characters) do  
        XSmashBRoleManager.AddNewRole(character)
    end
    -- 超限乱斗机器人
    for _, robotCfg in ipairs(XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.SystemCharaConfig)) do
        XSmashBRoleManager.AddNewRole(XRobot.New(robotCfg.RobotId))
    end
    -- 超限乱斗彩蛋机器人
    for robot_id, v in pairs(XSuperSmashBrosConfig.GetAllConfigs(XSuperSmashBrosConfig.TableKey.EggRobot)) do
        XSmashBRoleManager.AddNewRole(XRobot.New(robot_id))
        local eggRole = XSmashBRoleManager.GetRoleById(robot_id)
        eggRole:SetSuperSmashEggRobot(v)
        EggRobotList[robot_id] = eggRole
    end
end
--=============
--增加新角色
--@params :
-- roleData : XCharacter | XRobot
--=============
function XSmashBRoleManager.AddNewRole(roleData)
    -- 如果已经存在，直接不处理
    if RoleDicById[roleData.Id] then return end
    local role = RoleScript.New(roleData)
    table.insert(Roles, role)
    RoleDicById[role:GetId()] = role
end
--=============
--获取所有角色列表
--=============
function XSmashBRoleManager.GetRoleList()
    if XTool.IsTableEmpty(Roles) then
        XSmashBRoleManager.GenerateRoleData()
    end
    return Roles
end
--=============
--获取所有彩蛋角色列表
--=============
function XSmashBRoleManager.GetEggRoleList()
    if XTool.IsTableEmpty(EggRobotList) then
        XSmashBRoleManager.GenerateRoleData()
    end
    return EggRobotList
end
--=============
-- 解锁重置可播放彩蛋动画，且解锁菜单机器人绑定和展示和核心 每次退出模式(包括胜利退出和放弃退出)并进入ready界面时重置 cxldV2
--=============
function XSmashBRoleManager.ResetEggRobotOpen()
    -- 循环彩蛋角色列表
    for robotId, char in pairs(EggRobotList) do
        char:SetCloseEgg()
        char:SetCore(nil) -- 解除核心
        XSaveTool.SaveData(string.format("%d%dSuperSmashEggAnim", XPlayer.Id, char:GetId()), 0)
    end
end
--==============
--根据角色类型获取所有角色列表
--@param:
--charaType:角色类型(构造体，授格者…)
--==============
function XSmashBRoleManager.GetRoleListByCharaType(charaType)
    if XTool.IsTableEmpty(Roles) then
        XSmashBRoleManager.GenerateRoleData()
    end
    if charaType == nil then
        return Roles
    end
    local result = {}
    for _, role in ipairs(Roles) do
        if role:GetCharacterType() == charaType then
            table.insert(result, role)
        end
    end
    return result
end
--==============
--排序角色列表(筛选排列界面的配套方法)
--@param:
--roles:要排列的角色列表
--sortTagType:排序标签类型
--isAscendOrder:true为升序 false为降序
--==============
function XSmashBRoleManager.SortRoles(roles, sortTagType, isAscendOrder)
    if isAscendOrder == nil then isAscendOrder = true end
    IsAscendOrder = isAscendOrder
    if not sortTagType or (sortTagType == XRoomCharFilterTipsConfigs.EnumSortTag.Default) then
        sortTagType = XRoomCharFilterTipsConfigs.EnumSortTag.Ability
    end
    local characterRoles = {}
    local characterIdDic = {}
    local robotRoles = {}
    for _, role in ipairs(roles) do
        if role:GetIsRobot() then
            table.insert(robotRoles, role)
        else
            table.insert(characterRoles, role)
            characterIdDic[role:GetId()] = role
        end
    end
    table.sort(characterRoles, SortFunctionDic[sortTagType])
    table.sort(robotRoles, SortFunctionDic[sortTagType])
    return appendArray(characterRoles, robotRoles)
end
--==============
--获取设置真实队伍角色队伍数据
--@param:
--modeId:设置真实队伍的模式Id
--charaIdList:我方选择角色队伍Id列表(包含空位，随机位)
--==============
function XSmashBRoleManager.GetSetTeamRoleTeam(modeId, charaIdList)
    local teamData = XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(modeId)
    local finalCharaIdList = XSmashBRoleManager.SelectRandomRole(teamData.RoleIds, modeId) --finalCharaIdList 随机后的最终id
    local colorList = {}
    for i, color in pairs(teamData.Color) do
        colorList[i] = color
    end
    local resultTeam = {}
    local resultColor = {}
    local captainPos = teamData.CaptainPos
    local firstFightPos = teamData.FirstFightPos
    --检查队长位
    --若设置的队长位是空位置，则强制将其设置到第一个有角色Id的位置
    if not finalCharaIdList[captainPos] or (finalCharaIdList[captainPos] == 0) then
        for pos, finalCharaId in pairs(finalCharaIdList) do
            if finalCharaId > 0 then
                captainPos = pos
                break
            end
        end
    end
    --检查首战位
    --若设置的首战位是空位置，则将其设置到第一个有角色Id的位置
    if not finalCharaIdList[firstFightPos] or (finalCharaIdList[firstFightPos] == 0) then
        for pos, finalCharaId in pairs(finalCharaIdList) do
            if finalCharaId > 0 then
                firstFightPos = pos
                break
            end
        end
    end
    local captainColor = teamData.Color[captainPos]
    local resultCaptainPos = 1
    for index, finalCharaId in pairs(finalCharaIdList) do
        if finalCharaId > 0 then
            table.insert(resultTeam, {
                    Id = finalCharaId,
                    IsRobot = XEntityHelper.GetIsRobot(finalCharaId),
                    IsRandom = teamData.RoleIds[index] == XSuperSmashBrosConfig.PosState.Random or teamData.RoleIds[index] == XSuperSmashBrosConfig.PosState.OnlyRandom,
                    GridIndex = index
                })
            table.insert(resultColor, (colorList[index] == 0 and 1) or colorList[index])
            if captainColor == colorList[index] then resultCaptainPos = (captainColor == 0 and 1) or captainColor end
        end
    end
    firstFightPos = resultCaptainPos --首战位统一和队长位相同
    return resultTeam, resultColor, resultCaptainPos, firstFightPos
end
--==============
--选择随机角色
--@param:
--charaIdList:我方角色队伍Id列表(包含空位，随机位)
--modeId:进行随机的模式Id
--==============
function XSmashBRoleManager.SelectRandomRole(charaIdList, modeId)
    local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(modeId)
    local isTeamBattle = mode:GetRoleBattleNum() > 1 --出战人数多于1人时就为组队制
    --提取已选中角色的Id字典与获得队伍角色类型限制
    local charaIdDic = {}
    local charaType
    for _, charaId in pairs(charaIdList) do
        if charaId > 0 then
            charaIdDic[charaId] = true
            --组队模式要检查队内角色类型必须统一
            if isTeamBattle and (not charaType) then
                local role = XSmashBRoleManager.GetRoleById(charaId)
                charaType = role:GetCharacterType()
            end
        end
    end
    --从所有角色池中构建符合队伍的随机角色池
    local randomPool = {}
    for _, role in pairs(Roles) do
        if charaIdDic[role:GetId()] then --已经在队伍中的角色排除
            goto nextRole
        end
        if role:GetIsRobot() then --试玩角色排除
            goto nextRole
        end
        -- cxldV2 授格者已经可以混队
        -- if isTeamBattle and charaType and (role:GetCharacterType() ~= charaType) then --组队模式下不和已在队伍中的角色统一类型的排除  
        --     goto nextRole
        -- end
        table.insert(randomPool, role)
        :: nextRole ::
    end

    -- 开始随机
    local resultList = {}
    for index, charaId in pairs(charaIdList) do
        if charaId == XSuperSmashBrosConfig.PosState.Random or
        charaId == XSuperSmashBrosConfig.PosState.OnlyRandom then
            local result = 0
            -- :: randomAgain ::
            local roleNum = #randomPool
            if roleNum > 0 then
                local random = math.random(1, roleNum)
                local randomId = randomPool[random]:GetId()
                -- cxldV2 授格者已经可以混队
                -- local randomCharaType = randomPool[random]:GetCharacterType()
                -- if not charaType then       
                --     charaType = randomCharaType
                -- elseif randomCharaType ~= charaType then
                --     table.remove(randomPool, random)
                --     goto randomAgain
                -- end
                table.remove(randomPool, random)
                result = randomId
            end
            resultList[index] = result
        elseif charaId > 0 then
            resultList[index] = charaId
        else
            resultList[index] = 0
        end
    end
    return resultList
end

function XSmashBRoleManager.SetBattleRoleLeftHp(battleTeam, characterProgress, characterHpResultList)
    for index, charaId in pairs(battleTeam or {}) do
        local role = XSmashBRoleManager.GetRoleById(charaId)
        if role then
            --这里先把所有被淘汰(出场索引在现起始出战索引之前)的角色Hp设置为0
            --其他都初始化为满血，在后面再根据数据设置剩余血量
            if index < characterProgress then
                role:SetHpLeft(0)
            else
                role:SetHpLeft(100)
            end
        end
    end
    for _, charaInfo in pairs(characterHpResultList or {}) do
        local role = XSmashBRoleManager.GetRoleById(charaInfo.CharacterId)
        if role then
            role:SetHpLeft(charaInfo.HpPercent)
            role:SetSpLeft(charaInfo.Energy)
        end
    end
end
return XSmashBRoleManager