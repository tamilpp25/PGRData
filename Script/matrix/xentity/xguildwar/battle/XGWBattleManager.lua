local XTeam = require("XEntity/XTeam/XTeam")
local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
local XHomeGWNode = require("XEntity/XGuildWar/Battle/Node/XHomeGWNode")
local XBuffGWNode = require("XEntity/XGuildWar/Battle/Node/XBuffGWNode")
local XGuardGWNode = require("XEntity/XGuildWar/Battle/Node/XGuardGWNode")
local XInfectGWNode = require("XEntity/XGuildWar/Battle/Node/XInfectGWNode")
local XSentinelGWNode = require("XEntity/XGuildWar/Battle/Node/XSentinelGWNode")
local XGWEliteMonster = require("XEntity/XGuildWar/Battle/XGWEliteMonster")
local XGWBattleManager = XClass(nil, "XGWBattleManager")

local NodeType2Class = {
    [XGuildWarConfig.NodeType.Home] = XHomeGWNode,
    [XGuildWarConfig.NodeType.Normal] = XNormalGWNode,
    [XGuildWarConfig.NodeType.Buff] = XBuffGWNode,
    [XGuildWarConfig.NodeType.Sentinel] = XSentinelGWNode,
    [XGuildWarConfig.NodeType.Guard] = XGuardGWNode,
    [XGuildWarConfig.NodeType.Infect] = XInfectGWNode,
}

local CreateNode = function(id)
    local nodeConfig = XGuildWarConfig.GetNodeConfig(id)
    if nodeConfig == nil then
        XLog.Error(string.format( "找不到节点%s配置", id))
        return
    end
    local nodeType = nodeConfig.Type
    local classDefine = NodeType2Class[nodeType]
    if classDefine == nil then
        XLog.Error(string.format( "找不到节点%s类型%s配置", id, nodeType))
        return
    end
    local result = classDefine.New(id)
    return result
end

XGWBattleManager.DoAction = {
    [XGuildWarConfig.MosterActType.Dead] = function(self, actionGroup)--怪物死亡
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_DEAD, actionGroup)
    end,

    [XGuildWarConfig.MosterActType.Born] = function(self, actionGroup)--怪物诞生
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_BORN, actionGroup)
    end,

    [XGuildWarConfig.MosterActType.Move] = function(self, actionGroup)--怪物移动
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_MOVE, actionGroup)
    end,

    [XGuildWarConfig.MosterActType.BaseHit] = function(self, actionGroup)--基地受伤
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_BASEHIT, actionGroup)
    end,

    [XGuildWarConfig.MosterActType.NodeDestroyed] = function(self, actionGroup)--节点攻破
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, actionGroup)
    end,
}

function XGWBattleManager:Ctor(difficultyId)
    self.DifficultyId = difficultyId
    -- 所有节点
    self.NodeDic = {}
    -- { [uid] = XGWEliteMonster }
    self.MonsterDic = {}
    -- 路线节点字典
    self.NodeId2PathIndex = {}
    -- 我自己的回合数据 XGuildWarRoundDataDb
    self.CurrentMyRoundData = nil
    -- 节点战斗记录数据 { GuildWarFightRecord }
    self.FightRecords = {}
    -- 当前轮次的数据
    self.CurrentRoundData = nil
    -- 行动队列
    self.ActionList = {}
    -- 行动是否需要缩放字典
    self.ActionZoomDic = {}
    -- 已观看的行动ID
    self.ShowedActionIdDic = {}
    -- 行动正在展示中
    self.IsActionPlayingDic = {}
    -- 当前客户端缓存的战斗UID， 节点或怪物的
    self.CurrentClientBattleUID = nil
    -- 当前客户端缓存的节点状态
    self.CurrentClientBattleNodeStatus = nil
    -- 动画是否是历史动画
    self.IsHistoryAction = false
    -- 动画是否缩放
    self.IsActionInZoom = false
end

-- activityData : GuildWarActivityData
-- myRoundData : XGuildWarRoundDataDb
function XGWBattleManager:InitWithServerData(currentRoundData, myRoundData, fightRecords)
    self:UpdateCurrentRoundData(currentRoundData)
    self:UpdateMyRoundData(myRoundData)
    self:UpdateFightRecords(fightRecords)
end

-- data : GuildWarActivityData
function XGWBattleManager:UpdateCurrentRoundData(data)
    self.DifficultyId = data.DifficultyId
    self.CurrentRoundData = data
    self:UpdateNodePathIndex(self:GetCurrentRoundData().AttackPlan)
    for id, node in pairs(self.NodeDic) do
        node:UpdateWithServerData(self:GetNodeServerData(id))
    end
end

-- data : XGuildWarRoundDataDb
function XGWBattleManager:UpdateMyRoundData(data)
    self.CurrentMyRoundData = data
    self.DifficultyId = data.DifficultyId
end

-- data : List<GuildWarFightRecord>
function XGWBattleManager:UpdateFightRecords(data)
    self.FightRecords = data
end

-- data : XGuildWarNodeData
function XGWBattleManager:UpdateNodeData(data)
    local node = self:GetNode(data.NodeId)
    node:UpdateWithServerData(data)
end

function XGWBattleManager:UpdateNodeDatas(datas)
    for _, data in ipairs(datas) do
        self:UpdateNodeData(data)
    end
end

function XGWBattleManager:UpdateMonsterData(data)
    local roundData = self:GetCurrentRoundData()
    local monsterData
    for i = #roundData.MonsterData, 1, -1 do
        monsterData = roundData.MonsterData[i]
        if monsterData.Uid == data.Uid then
            roundData.MonsterData[i] = data
            break
        end
    end
end

-- 更新精英怪死亡
function XGWBattleManager:UpdateMonsterDead(uid, IsDead)
    local monster = self:GetMonsterDic()[uid]
    if not monster then
        XLog.Error(string.format( "服务器下发不存在的怪物Uid : %s", uid))
        return
    end
    monster:UpdateDead(IsDead)
end

function XGWBattleManager:GetCurrentMyRoundData()
    return self.CurrentMyRoundData
end

-- GuildWarRoundData
function XGWBattleManager:GetCurrentRoundData()
    return self.CurrentRoundData
end

-- 当前轮次累计活跃度
function XGWBattleManager:GetTotalActivation()
    return self:GetCurrentRoundData().TotalActivation
end

-- 当前轮次累计积分
function XGWBattleManager:GetTotalPoint()
    return self:GetCurrentRoundData().TotalPoint
end

-- 获取节点服务器数据
function XGWBattleManager:GetNodeServerData(id)
    local currentRoundData = self:GetCurrentRoundData()
    if currentRoundData == nil then return nil end
    for _, nodeData in ipairs(currentRoundData.NodeData) do
        if nodeData.NodeId == id then
            return nodeData
        end
    end
end

function XGWBattleManager:GetDifficultyId()
    return self.DifficultyId
end

function XGWBattleManager:GetNode(id)
    local result = self.NodeDic[id]
    if result == nil then
        result = CreateNode(id)
        local serverData = self:GetNodeServerData(id)
        if serverData then
            result:UpdateWithServerData(serverData)
        else
            XLog.Error(string.format( "找不到%s节点的服务器数据", id))
        end
        self.NodeDic[id] = result
    end
    return result
end

-- 获取当前难度名称
function XGWBattleManager:GetDifficultyName()
    local difficultyCfg = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Difficulty, self.DifficultyId)
    return difficultyCfg and difficultyCfg.Name
end

-- 获取当前难度扫荡血量折损
function XGWBattleManager:GetSweepHpFactor()
    local difficultyCfg = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Difficulty, self.DifficultyId)
    return difficultyCfg and difficultyCfg.SweepHpFactor
end

-- 获取当前节点id
function XGWBattleManager:GetCurrentNodeId()
    if self:GetCurrentMyRoundData() == nil then
        return 1
    end
    return self:GetCurrentMyRoundData().CurNodeId
end

function XGWBattleManager:UpdateCurrentNodeId(value)
    self:GetCurrentMyRoundData().CurNodeId = value
end

-- 获取所有节点数据
function XGWBattleManager:GetNodes()
    local result = {}
    local nodeIds = XGuildWarConfig.GetNodeIdsByDifficultyId(self.DifficultyId)
    for _, nodeId in ipairs(nodeIds) do
        table.insert(result, self:GetNode(nodeId))
    end
    return result
end

-- 获取所有怪物字典，key为UID
function XGWBattleManager:GetMonsterDic()
    local roundData = self:GetCurrentRoundData()
    local monster = nil
    local monsterUnRemoveDic = {}
    if roundData == nil then
        return {}
    end
    for _, monsterData in pairs(roundData.MonsterData) do
        monsterUnRemoveDic[monsterData.Uid] = true
        monster = self.MonsterDic[monsterData.Uid]
        if monster == nil then
            monster = XGWEliteMonster.New(monsterData.MonsterId)
        end
        monster:UpdateWithServerData(monsterData)
        self.MonsterDic[monsterData.Uid] = monster
    end
    -- 删除冗余的怪物数据
    for uid, _ in pairs(self.MonsterDic) do
        if not monsterUnRemoveDic[uid] then
            self.MonsterDic[uid] = nil
        end
    end
    return self.MonsterDic
end

-- 根据节点id获取怪物数据
function XGWBattleManager:GetMonstersByNodeId(id, checkIsDead)
    if checkIsDead == nil then checkIsDead = true end
    local result = {}
    for _, v in pairs(self:GetMonsterDic()) do
        if v:GetCurrentNodeId() == id then
            if not checkIsDead or not v:GetIsDead() then
                table.insert(result, v)
            end
        end
    end
    return result
end

-- 根据节点id获取怪物数据
function XGWBattleManager:GetMonsterById(uid)
    local monster = self:GetMonsterDic()[uid]
    if not monster then
        XLog.Error(string.format( "服务器下发不存在的怪物Uid : %s", uid))
        return
    end
    return monster
end

function XGWBattleManager:UpdateNodePathIndex(pathNodeIds)
    self.NodeId2PathIndex = {}
    for index, id in ipairs(pathNodeIds or {}) do
        self.NodeId2PathIndex[id] = index
    end
end

function XGWBattleManager:GetNodePathIndex(nodeId)
    return self.NodeId2PathIndex[nodeId]
end

-- 根据节点UID或者精英怪UID获取最高伤害
function XGWBattleManager:GetMaxDamageByUID(uid, aliveType)
    if self.FightRecords == nil or #self.FightRecords <= 0 then
        return 0
    end
    for _, data in pairs(self.FightRecords) do
        if data.Uid == uid then
            if aliveType == nil then
                return data.MaxDamage
            elseif data.AliveType == aliveType then
                return data.MaxDamage
            end
        end
    end
    return 0
end

-- 获取战斗日志
function XGWBattleManager:GetBattleLogs(count)
    local result = {}
    local roundData = self:GetCurrentRoundData()
    for i = #roundData.Battlelog, 1, -1 do
        local logData = roundData.Battlelog[i]
        local menberData = XDataCenter.GuildManager.GetMemberDataByPlayerId(logData.PlayerId)
        if menberData then
            local IsFightNode = logData.FightType == XGuildWarConfig.NodeFightType.FightNode
            local IsShowDeadNode = logData.IsDead > 0 and IsFightNode
            
            local textConfig = IsShowDeadNode and 
            XGuildWarConfig.BattleDeadNodeLogTextConfig or
            XGuildWarConfig.BattleLogTextConfig[logData.LogType]
            
            local text = ""
            local fightName = ""
            
            if IsFightNode then
                local node = self:GetNode(logData.NodeId)
                fightName = node:GetName(false)
                text = textConfig[node:GetNodeType()] or ""
            else
                fightName = XGuildWarConfig.GetEliteMonsterConfig(logData.MonsterId).Name
                text = textConfig[XGuildWarConfig.NodeType.Normal] or ""
            end
            
            local logFullText = ""
            if IsShowDeadNode then
                logFullText = XUiHelper.GetText(text,(logData.Point or 0))
            else
                logFullText = XUiHelper.GetText(text,fightName,string.format("%s", (logData.DamagePercent or 0) / 10))
            end
            
            local log = {
                Time = XTime.TimestampToGameDateTimeString(logData.CreateTime, "MM.dd HH:mm"),
                Name = menberData:GetName(),
                Text = logFullText
            }
            table.insert(result, log)
        end
        
        if count and #result >= count then
            return result
        end
    end
    return result
end

-- 获取所有buff节点，默认是已经激活的
function XGWBattleManager:GetBuffNodes()
    local result = {}
    for _, node in ipairs(self:GetNodes()) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Buff then
            if node:GetIsActiveBuff() then
                table.insert(result, node)
            end
        end
    end
    return result
end

function XGWBattleManager:CheckActionIsShowed(id)
    return self.ShowedActionIdDic[id]
end

function XGWBattleManager:UpdateShowedActionIdDic(idList)
    for _,id in pairs(idList or {}) do
        self.ShowedActionIdDic[id] = true
    end
end

local InsertActinGroupList = function(allActinGroupList, actinGroup)
    if actinGroup and next(actinGroup) then
        table.sort(actinGroup, function (a, b)
            return a.ActionId < b.ActionId
        end)
        table.insert(allActinGroupList, actinGroup)
    end
end

function XGWBattleManager:GetRobots(characterType)
    local robotIds = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Difficulty, self:GetDifficultyId()).RobotId
    local result = {}
    local characterId = nil
    local robotCharacterType
    for _, id in ipairs(robotIds) do
        robotCharacterType = XEntityHelper.GetRobotCharacterType(id)
        if characterType == nil then
            table.insert(result, XRobotManager.GetRobotById(id))
        elseif characterType == robotCharacterType then
            table.insert(result, XRobotManager.GetRobotById(id))
        end
    end
    return result
end

function XGWBattleManager:GetTeam()
    if self.__Team == nil then
        self.__Team = XTeam.New("XGWBattleManager" .. self:GetDifficultyId())
    end
    -- 清除错误配置的机器人
    local robotIds = XGuildWarConfig.GetCfgByIdKey(XGuildWarConfig.TableKey.Difficulty, self:GetDifficultyId()).RobotId
    local robotIdDic = table.arrayToDic(robotIds)
    for pos, entityId in ipairs(self.__Team:GetEntityIds()) do
        if entityId > 0 and XEntityHelper.GetIsRobot(entityId) then
            if robotIdDic[entityId] == nil then
                self.__Team:UpdateEntityTeamPos(entityId, pos, false)
            end
        end
    end
    return self.__Team
end

function XGWBattleManager:OpenBattleRoomUi(stageId)
    XLuaUiManager.Open("UiBattleRoleRoom", stageId, self:GetTeam(), require("XUi/XUiGuildWar/XUiGuildWarBattleRoleRoom"))
end

-- 获取怪物行动组队列
function XGWBattleManager:GetActionGroupList()
    local actionAllGroupList = {}
    local actionDeadGroupDic = {}
    local actionBornGroupDic = {}
    local actionMoveGroupDic = {}
    local actionBaseHitGroupDic = {}
    local actionNodeDestroyedGroup = {}
    local turn = 1
    
    for _,action in pairs(self.ActionList or {}) do
        if  not self:CheckActionIsShowed(action.ActionId) then
            if action.ActionType == XGuildWarConfig.MosterActType.Dead then
                actionDeadGroupDic[turn] = actionDeadGroupDic[turn] or {}
                table.insert(actionDeadGroupDic[turn], action)
                
            elseif action.ActionType == XGuildWarConfig.MosterActType.Move then
                actionMoveGroupDic[turn] = actionMoveGroupDic[turn] or {}
                table.insert(actionMoveGroupDic[turn], action)

            elseif action.ActionType == XGuildWarConfig.MosterActType.Born then
                actionBornGroupDic[turn] = actionBornGroupDic[turn] or {}
                table.insert(actionBornGroupDic[turn], action)
                
            elseif action.ActionType == XGuildWarConfig.MosterActType.BaseHit then
                actionBaseHitGroupDic[turn] = actionBaseHitGroupDic[turn] or {}
                table.insert(actionBaseHitGroupDic[turn], action)
                
            elseif action.ActionType == XGuildWarConfig.MosterActType.NodeDestroyed then
                local node = self:GetNode(action.NodeId)
                table.insert(actionNodeDestroyedGroup, action)       
            elseif action.ActionType == XGuildWarConfig.MosterActType.NextTurn then
                turn = turn + 1
            end
        end
    end
    for key = 1, turn do
        InsertActinGroupList(actionAllGroupList, actionMoveGroupDic[key])
        InsertActinGroupList(actionAllGroupList, actionBornGroupDic[key])
        InsertActinGroupList(actionAllGroupList, actionDeadGroupDic[key])
        InsertActinGroupList(actionAllGroupList, actionBaseHitGroupDic[key])
    end
    InsertActinGroupList(actionAllGroupList, actionNodeDestroyedGroup)
    
    return actionAllGroupList
end

function XGWBattleManager:GetPreMonsterDataDic()--只需拿出第一回合所有需要预创建的怪物就好，后面回合用到的怪物要么是出生的，要么是前面回合遗留下来的。
    local preMonsterDataDic = {}
    
    for _,action in pairs(self.ActionList or {}) do
        if not self:CheckActionIsShowed(action.ActionId) then
            if action.ActionType == XGuildWarConfig.MosterActType.Dead then
                if not preMonsterDataDic[action.MonsterUid] then
                    local data = {UID = action.MonsterUid, NodeIndex = action.CurNodeIdx}
                    preMonsterDataDic[action.MonsterUid] = data
                end
            elseif action.ActionType == XGuildWarConfig.MosterActType.Move then
                if not preMonsterDataDic[action.MonsterUid] then
                    local data = {UID = action.MonsterUid, NodeIndex = action.PreNodeIdx}
                    preMonsterDataDic[action.MonsterUid] = data
                end
            end
        end
    end
    
    for _,action in pairs(self.ActionList or {}) do
        if not self:CheckActionIsShowed(action.ActionId) then
            if action.ActionType == XGuildWarConfig.MosterActType.Born then
                if preMonsterDataDic[action.MonsterUid] then
                    preMonsterDataDic[action.MonsterUid] = nil
                end
            end
        end
    end

    return preMonsterDataDic
end

function XGWBattleManager:GetIsHasCanPlayAction()
    for _,action in pairs(self.ActionList or {}) do
        if action.ActionType ~= XGuildWarConfig.MosterActType.NextTurn then
            if not self:CheckActionIsShowed(action.ActionId) then
                return true
            end
        end
    end
    return false
end

function XGWBattleManager:DoActionFinish(actionType)
    self.IsActionPlayingDic[actionType] = nil
    self:CheckActionList()
end

function XGWBattleManager:CheckActionList()
    if not self:CheckActionPlaying() then
        local firstIndex = 1
        local actionGroupList = self:GetActionGroupList()
        local actionGroup = actionGroupList[firstIndex]
        if actionGroup and next(actionGroup) then
            local actionIdList = {}
            for _,action in pairs(actionGroup) do
                table.insert(actionIdList, action.ActionId)
            end
            XDataCenter.GuildWarManager.RequestPopupActionID(actionIdList, function ()
                    local type = actionGroup[1].ActionType
                    self.IsActionPlayingDic[type] = true
                    self:UpdateShowedActionIdDic(actionIdList)
                    if self.DoAction[type] then
                        if self:CheckActionGroupNeedZoom(actionGroup) and not self.IsActionInZoom then
                            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_OPEN_MOVIEMODE,function ()
                                    self.DoAction[type](self, actionGroup)
                            end)
                            self.IsActionInZoom = true
                        else
                            self.DoAction[type](self, actionGroup)
                        end
                    end
            end)
        else
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER)
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_CLOSE_MOVIEMODE)
            self:SetIsHistoryAction(false)
            self.IsActionInZoom = false
        end
    end
end

function XGWBattleManager:CheckActionPlaying()
    for _,plaing in pairs(self.IsActionPlayingDic or {}) do
        if plaing then
            return true
        end
    end
    return false
end

--设置行动队列
function XGWBattleManager:SetActionList(actionList)
    self.ActionList = actionList
    self.ActionZoomDic = {}
    for _,action in pairs(actionList or {}) do
        self.ActionZoomDic[action.ActionId] = true
    end
end

--增加行动队列
function XGWBattleManager:AddActionList(actionList)
    appendArray(self.ActionList, actionList)
    self:UpdateActionData(actionList)--只有即时发生的事件需要通过action去更新数据
end

function XGWBattleManager:UpdateActionData(actionList)
    for _,action in pairs(actionList) do
        if action.ActionType == XGuildWarConfig.MosterActType.Dead then
            self:UpdateMonsterDead(action.MonsterUid, true)
        elseif action.ActionType == XGuildWarConfig.MosterActType.NodeDestroyed then
            self:UpdateNodeData(action.NodeData)
        end
    end
end

function XGWBattleManager:UpdateCurrentClientBattleInfo(uid, nodeStatus)
    self.CurrentClientBattleUID = uid
    self.CurrentClientBattleNodeStatus = nodeStatus
end

function XGWBattleManager:GetCurrentClientBattleUID()
    return self.CurrentClientBattleUID
end

function XGWBattleManager:GetCurrentClientBattleNodeStatus()
    return self.CurrentClientBattleNodeStatus
end

function XGWBattleManager:CheckActionGroupNeedZoom(actionGroup)
    for _,action in pairs(actionGroup or {}) do
        if self.ActionZoomDic[action.ActionId] then
            return true
        end
    end
    return false
end

function XGWBattleManager:CheckIsHistoryAction()
    return self.IsHistoryAction
end

function XGWBattleManager:SetIsHistoryAction(IsHistory)
    self.IsHistoryAction = IsHistory
end

function XGWBattleManager:CheckAllInfectIsDead()
    for _, node in ipairs(self:GetNodes()) do
        if node:GetNodeType() == XGuildWarConfig.NodeType.Infect then
            if not node:GetIsDead() then
                return false
            end
        end
    end
    return true
end

return XGWBattleManager