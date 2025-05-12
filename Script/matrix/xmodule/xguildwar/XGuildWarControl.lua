--- 公会战
---@class XGuildWarControl : XControl
---@field private _Model XGuildWarModel
---@field DragonRageControl XDragonRageControl @龙怒系统玩法的控制器
---@field GarrisonControl XGarrisonControl @驻守系统玩法的控制器
local XGuildWarControl = XClass(XControl, "XGuildWarControl")
local INF = 0xFFFFFFF -- 表示距离无限
local NoSafeLimit = 10000 -- 用于增加最短路径计算时，绕过未击破节点时的代价

function XGuildWarControl:OnInit()
    -- 初始化龙怒系统的控制器
    self.DragonRageControl = self:AddSubControl(require("XModule/XGuildWar/SubModule/DragonRage/XDragonRageControl"))
    -- 初始化驻守玩法的控制器
    self.GarrisonControl = self:AddSubControl(require("XModule/XGuildWar/SubModule/Garrison/XGarrisonControl"))
end

function XGuildWarControl:AddAgencyEvent()

end

function XGuildWarControl:RemoveAgencyEvent()

end

function XGuildWarControl:OnRelease()
    self._MoveDistanceMap = nil
    self._DijkstraDist = nil
    self._DijkstraFlag = nil
    self._DijkstraPreNode = nil

    local battleManager = XDataCenter.GuildWarManager.GetBattleManager()

    if battleManager then
        battleManager:ClearActionPlayingDic()
    end
end

--region ---------- 节点数据 ---------->>>

--- 获取所有在大地图上显示的节点数据
function XGuildWarControl:GetMainMapNodes()
    ---@type XGWBattleManager
    local battleManager = XDataCenter.GuildWarManager.GetBattleManager()
    
    ---@type XGWNode[]
    local nodeList = battleManager:GetMainMapNodes()
    
    return nodeList
end

--endregion <<<--------------------------

--region ---------- 地图寻路 ---------->>>

--- 获取所有点之间的可达路程
function XGuildWarControl:GetMoveDistanceMap()
    local isInit = false
    if self._MoveDistanceMap == nil then
        self._MoveDistanceMap = {}
        isInit = true
    end
    
    local nodes = XDataCenter.GuildWarManager.GetBattleManager():GetNodes()
    local n = #nodes
    
    -- 初始化路径点之间的距离
    if isInit then
        for i = 1, n do
            for j = 1, n do
                local node1 = nodes[i]
                local node2 = nodes[j]
                local id1 = node1:GetId()
                local id2 = node2:GetId()
                self._MoveDistanceMap[id1] = self._MoveDistanceMap[id1] or {}
                self._MoveDistanceMap[id1][id2] = INF
            end
        end
    end

    -- 根据当前情况更新路径点之间的距离
    for i = 1, n do
        local node = nodes[i]
        local children = node:GetNextNodes()
        for j = 1, #children do
            local childNode = children[j]
            
            local nodeId = node:GetId()
            local childNodeId = childNode:GetId()
            
            local isNodeSafe = node:GetIsDead() or node:GetIsBaseNode()
            local isChildNodeSafe = childNode:GetIsDead() or childNode:GetIsBaseNode()
            
            
            if isNodeSafe or isChildNodeSafe then
                self._MoveDistanceMap[nodeId][childNodeId] = isChildNodeSafe and 1 or  (NoSafeLimit + 1)-- 默认路程为1
                self._MoveDistanceMap[childNodeId][nodeId] = isNodeSafe and 1 or (NoSafeLimit + 1) -- 默认路程为1
            else
                self._MoveDistanceMap[nodeId][childNodeId] = INF
                self._MoveDistanceMap[childNodeId][nodeId] = INF
            end
        end
    end

    return self._MoveDistanceMap
end

--- 迪杰斯特拉寻路算法求单源路径(旧逻辑位置迁移 + 缓存优化GC）
function XGuildWarControl:_Dijkstra(start, map)
    if self._DijkstraDist == nil then
        self._DijkstraDist = {}
    end

    if self._DijkstraFlag == nil then
        self._DijkstraFlag = {}
    end

    if self._DijkstraPreNode == nil then
        self._DijkstraPreNode = {}
    end
    
    -- 初始化单源距离和标记
    for i, v in pairs(map) do
        self._DijkstraDist[i] = map[start][i]
        self._DijkstraFlag[i] = false;
        if self._DijkstraDist[i] == INF then
            self._DijkstraPreNode[i] = -1
        else
            self._DijkstraPreNode[i] = start
        end
    end

    self._DijkstraFlag[start] = true
    self._DijkstraDist[start] = 0
    
    -- 遍历计算
    for i, v in pairs(map) do
        local temp = INF
        local t = start
        for j, v in pairs(map[i]) do
            if (not self._DijkstraFlag[j]) and self._DijkstraDist[j] < temp then
                t = j;
                temp = self._DijkstraDist[j]
            end
        end
        if t == start then
            break
        end
        self._DijkstraFlag[t] = true

        for j, v in pairs(map[i]) do
            if (not self._DijkstraFlag[j]) and map[t][j] < INF then
                if (self._DijkstraDist[j] > (self._DijkstraDist[t] + map[t][j])) then
                    self._DijkstraDist[j] = self._DijkstraDist[t] + map[t][j]
                    self._DijkstraPreNode[j] = t
                end
            end
        end
    end
    
    return self._DijkstraDist, self._DijkstraPreNode
end

--- 获取玩家所在的节点到达其余所有节点的最短连通图
---@param beginNodeId @指定起始节点，不指定时默认玩家所在节点
function XGuildWarControl:GetMovePreNodes(map, beginNodeId)
    local currentNodeId = XTool.IsNumberValid(beginNodeId) and beginNodeId or XDataCenter.GuildWarManager.GetBattleManager():GetCurrentNodeId()
    if not map[currentNodeId] then
        XLog.Error("[XGuildWarManager] 当前节点不存在:", currentNodeId)
        return "???"
    end
    local dist, preNodes = self:_Dijkstra(currentNodeId, map)
    return preNodes
end

--- 获取玩家从所在节点移动到目标节点消耗的资源数量
---@param beginNodeId @指定起始节点，不指定时默认玩家所在节点
function XGuildWarControl:GetMoveCost(targetId, beginNodeId)
    local map = self:GetMoveDistanceMap()

    local currentNodeId = XTool.IsNumberValid(beginNodeId) and beginNodeId or XDataCenter.GuildWarManager.GetBattleManager():GetCurrentNodeId()
    if not map[currentNodeId] then
        XLog.Error("[XGuildWarManager] 当前节点不存在:", currentNodeId)
        return "???"
    end
    local dist, preNodes = self:_Dijkstra(currentNodeId, map)
    local path = dist[targetId] or 0

    if path > NoSafeLimit then
        path = path - NoSafeLimit
    end
    
    return math.floor(path * XGuildWarConfig.GetServerConfigValue("MoveCostEnergy")), preNodes
end

--endregion <<<--------------------------

return XGuildWarControl