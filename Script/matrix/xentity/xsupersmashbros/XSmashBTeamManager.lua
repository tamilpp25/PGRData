--===========================
--超限乱斗玩家队伍管理器
--模块负责：吕天元
--===========================
local XSmashBTeamManager = {}
--==================
--模式Id --> 我方队伍字典
--Key:ModeId
--Value:TeamData = {(值为示例)
--CaptainPos = 1
--FirstFightPos = 1
--RoleIds = {[1] = 0, [2] = 0, [3] = 0}
--Color = {[1] = red, [2] = blue, [3] = yellow}
--}
--==================
local OwnTeamDic

local DefaultTeamInfo

local SAVE_KEY = "SUPER_SMASH_TEAMDATA_"
--============
--根据模式获取本地保存队伍字符串
--============
local function GetSaveKey(modeId)
    return SAVE_KEY .. XPlayer.Id .. XDataCenter.SuperSmashBrosManager.GetActivityId() .. modeId
end
--============
--获取默认队伍
--先获取本地保存的数据，若没有，则按照模式对应配置新建默认数据
--============
local function GetDefaultTeam(modeId)
    local data = XSaveTool.GetData(GetSaveKey(modeId))
    if data then 
        local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(modeId)
        --检测有没当前没有的角色(有可能配置了不同的机器人)
        for index = 1, #(data.RoleIds or {}) do
            local roleId = data.RoleIds[index]
            if roleId > 0 then
                local role = XDataCenter.SuperSmashBrosManager.GetRoleById(roleId)
                if not role then
                    data.RoleIds[index] = 0
                end
            end
        end
        return data 
    end
    local newData = {
        FirstFightPos = 1,
        CaptainPos = 1,
        Color = {},
        RoleIds = {}
    }
    local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(modeId)
    local roleMax = mode:GetRoleMaxPosition()
    local battleNum = mode:GetRoleBattleNum()
    local roleMin = mode:GetRoleMinPosition()
    local maxPosition = mode:GetTeamMaxPosition() --我方队伍位置数
    local forceRandomIndex = mode:GetRoleRandomStartIndex( ) --我方可强制随机的开始下标
    for index = 1, maxPosition do
        if index > roleMax then
            newData.RoleIds[index] = XSuperSmashBrosConfig.PosState.Ban
            newData.Color[index] = XSuperSmashBrosConfig.ColorTypeEnum.None
        else
            --当上场人数大于1时为组队战，需要有排位颜色按默认顺序排列(红蓝黄)，否则排位颜色时为None
            local colorTypeIndex = ((battleNum == 1) and XSuperSmashBrosConfig.ColorTypeEnum.None) or index
            newData.RoleIds[index] = XSuperSmashBrosConfig.PosState.Empty
            newData.Color[index] = colorTypeIndex
        end

        if forceRandomIndex and index >= forceRandomIndex then
            newData.RoleIds[index] = XSuperSmashBrosConfig.PosState.Random
            newData.Color[index] = XSuperSmashBrosConfig.ColorTypeEnum.None
        end
    end
    return newData
end
--=============
--保存默认队伍
--=============
local function SaveDefaultTeam(modeId, teamData)
    XSaveTool.SaveData(GetSaveKey(modeId), teamData)
end
--=============
--初始化
--=============
function XSmashBTeamManager.Init()
    OwnTeamDic = {}
    DefaultTeamInfo = {}
end
--=============
--获取队伍
--=============
function XSmashBTeamManager.GetTeamByModeId(modeId)
    if not OwnTeamDic[modeId] then
        XSmashBTeamManager.CreateTeam(modeId)
    end
    return OwnTeamDic[modeId]
end
--=============
--获取默认队伍
--=============
function XSmashBTeamManager.GetDefaultTeamInfoByModeId(modeId)
    if not DefaultTeamInfo[modeId] then
        XSmashBTeamManager.CreateTeam(modeId)
    end
    return DefaultTeamInfo[modeId]
end
--=============
--修改默认队伍
--=============
function XSmashBTeamManager.SaveDefaultTeamByModeId(modeId, captainPos, firstFightPos, roleIds, color)
    local defaultTeam = XSmashBTeamManager.GetDefaultTeamInfoByModeId(modeId)
    if captainPos and captainPos > 0 then
        defaultTeam.CaptainPos = captainPos
    end
    if firstFightPos and firstFightPos > 0 then
        defaultTeam.FirstFightPos = firstFightPos
    end
    if roleIds then
        for index, _ in pairs(defaultTeam.RoleIds) do
            defaultTeam.RoleIds[index] = roleIds[index] or XSuperSmashBrosConfig.PosState.Empty
        end
    end
    if color then
        for index = 1, #defaultTeam.Color do
            local newId = color and color[index]
            defaultTeam.Color[index] = newId or XSuperSmashBrosConfig.ColorTypeEnum.None
        end
    end
    SaveDefaultTeam(modeId, defaultTeam)
end
--=============
--创建默认队伍
--=============
function XSmashBTeamManager.CreateTeam(modeId)
    OwnTeamDic[modeId] = {}
    --设置默认队伍，也用于本地保存上次使用过的队伍
    DefaultTeamInfo[modeId] = GetDefaultTeam(modeId)
    OwnTeamDic[modeId] = {
        FirstFightPos = 1,
        CaptainPos = 1,
        RoleIds = {},
        Color = {}
    }
    local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(modeId)
    local roleMax = mode:GetRoleMaxPosition()
    local battleNum = mode:GetRoleBattleNum()
    for index = 1, roleMax do
        OwnTeamDic[modeId].RoleIds[index] = 0
        --当上场人数大于1时为组队战，需要有排位颜色按默认顺序排列(红蓝黄)，否则排位颜色时为None
        local colorTypeIndex = ((battleNum == 1) and XSuperSmashBrosConfig.ColorTypeEnum.None) or index
        OwnTeamDic[modeId].Color[index] = colorTypeIndex == 0 and XSuperSmashBrosConfig.ColorTypeEnum.Red or colorTypeIndex
    end
end
--=============
--重置队伍信息
--=============
function XSmashBTeamManager.ResetTeamByModeId(modeId)
    local teamData = XSmashBTeamManager.GetTeamByModeId(modeId)
    for index, roleId in pairs(teamData.RoleIds or {}) do
        if roleId > 0 then
            local role = XDataCenter.SuperSmashBrosManager.GetRoleById(roleId)
            if role then
                role:SetHpLeft(100)
                role:SetSpLeft(0)
            end
        end
        teamData.RoleIds[index] = 0
    end
    --设置默认值
    teamData.FirstFightPos = DefaultTeamInfo[modeId].FirstFightPos
    teamData.CaptainPos = DefaultTeamInfo[modeId].CaptainPos
    for index = 1, #DefaultTeamInfo[modeId].Color do
        teamData.Color[index] = DefaultTeamInfo[modeId].Color[index]
    end
end
--===============
--设置队伍数据
--@params
--captainPos:队长位
--firstFightPos:首发位
--===============
function XSmashBTeamManager.SetTeamByModeId(captainPos, firstFightPos, roleIds, posIds, modeId)
    local teamData = XSmashBTeamManager.GetTeamByModeId(modeId)
    teamData.CaptainPos = captainPos ~= nil and captainPos > 0 and captainPos or teamData.CaptainPos
    teamData.FirstFightPos = firstFightPos ~= nil and firstFightPos > 0 and firstFightPos or teamData.FirstFightPos
    for index = 1, #(roleIds or {}) do
        teamData.RoleIds[index] = roleIds[index].Id
        -- 记录彩蛋角色揭开之前应该显示的角色id. 服务器验证通过，绑定roll出的彩蛋机器人原角色(有orgId就可以判断这个角色是彩蛋角色) cxldV2
        local orgId = roleIds[index].OrgId
        if orgId and orgId > 0 then
            local eggChar = XDataCenter.SuperSmashBrosManager.GetRoleById(roleIds[index].Id)
            eggChar:SetEggRobotOrgId(orgId)
        end

        -- 给彩蛋角色装备上核心，彩蛋的核心是进入ready界面后通过服务器验证下发 (有eggPlugin就一定是彩蛋角色)
        local eggPluginId = roleIds[index].EggPlugin
        if eggPluginId and eggPluginId > 0 then -- 非彩蛋角色默认发0
            local eggChar = XDataCenter.SuperSmashBrosManager.GetRoleById(roleIds[index].Id)
            eggChar:SetCore(eggPluginId)
        end
    end
    for index = 1, #(posIds or {}) do
        --获取枚举的颜色字符串
        local colorTypeIndex = XSuperSmashBrosConfig.ColorTypeIndex[posIds[index]]
        teamData.Color[index] = XSuperSmashBrosConfig.ColorTypeEnum[colorTypeIndex]
    end
end
--=============
--根据模式Id获取参战队伍的队长位
--=============
function XSmashBTeamManager.GetCaptainPosByModeId(modeId)
    local teamData = XSmashBTeamManager.GetTeamByModeId(modeId)
    return teamData.CaptainPos
end
--=============
--根据模式Id获取参战队伍的首发位
--=============
function XSmashBTeamManager.GetFirstFightPosByModeId(modeId)
    local teamData = XSmashBTeamManager.GetTeamByModeId(modeId)
    return teamData.FirstFightPos
end
--=============
--根据模式Id和队伍位置获取参战队伍角色的颜色位置
--=============
function XSmashBTeamManager.GetColorByIndexAndModeId(index, modeId)
    local teamData = XSmashBTeamManager.GetTeamByModeId(modeId)
    return teamData.Color and teamData.Color[index]
end
--=============
--根据模式Id获取参战队伍的角色Id列表
--=============
function XSmashBTeamManager.GetRoleIdsByModeId(modeId)
    local teamData = XSmashBTeamManager.GetTeamByModeId(modeId)
    return teamData.RoleIds or {}
end

return XSmashBTeamManager