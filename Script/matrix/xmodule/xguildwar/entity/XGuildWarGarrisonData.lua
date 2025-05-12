--- 公会战5.0新增的驻守玩法相关数据管理类
---@class XGuildWarGarrisonData
---@field ResourceNodeAttackedInfo @资源节点进攻信息，服务端数据
---@field private _DefensePlayerPercent @资源结点驻守百分比
---@field private _AttackInfoResNodeIdMap @当前资源节点id列表-在resourceNodeAttackedInfo下的映射,key:uid,value:index
---@field private _RoundDataResNodeIdMap @当前资源节点id列表-在roundData下的映射,key:uid,value:index
local XGuildWarGarrisonData = XClass(nil, 'XGuildWarGarrisonData')

--- 刷新炮击资源点信息
function XGuildWarGarrisonData:RefreshResourceNodeAttackedInfo(data)
    self._DefensePlayerPercent = nil
    self.ResourceNodeAttackedInfo = data
    if self._AttackInfoResNodeIdMap == nil then
        self._AttackInfoResNodeIdMap = {}
    end
    if not XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) and not XTool.IsTableEmpty(self.ResourceNodeAttackedInfo.ResourceNodesData) then
        for i, v in ipairs(self.ResourceNodeAttackedInfo.ResourceNodesData) do
            self.ResourceNodeAttackedInfo[v.NodeId]=i
        end
    end

    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ATTACKINFO_UPDATE)
end

--- 初始化节点Id-索引映射字典
function XGuildWarGarrisonData:InitResNodeIdMapInRoundData()
    if self._RoundDataResNodeIdMap == nil then
        self._RoundDataResNodeIdMap = {}
    end
    local roundData = XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData
    if roundData and not XTool.IsTableEmpty(roundData.NodeData) then
        for i, v in ipairs(roundData.NodeData) do
            if v.NodeType == XGuildWarConfig.NodeType.Resource then
                self._RoundDataResNodeIdMap[v.NodeId] = i
            end
        end
    end
end

--- 清空客户端驻守比例缓存
function XGuildWarGarrisonData:ClearDefensePlayerPercentCache()
    self._DefensePlayerPercent = nil
end

--- 获取对应资源点的驻守玩家比例
function XGuildWarGarrisonData:GetDefensePlayerPercentById(defenseId)
    if self._DefensePlayerPercent == nil then
        self._DefensePlayerPercent = {}
    else
        if self._DefensePlayerPercent[defenseId] then
            return self._DefensePlayerPercent[defenseId]
        else
            return 0
        end
    end

    local defenseDict = nil

    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) or self.ResourceNodeAttackedInfo.DefenseDic == nil then
        local roundData = XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData
        defenseDict = roundData.DefenseDic
    else--查驻守数据
        defenseDict = self.ResourceNodeAttackedInfo.DefenseDic
    end

    if XTool.IsTableEmpty(defenseDict) then
        return 0
    end

    --初始化计算
    local totalPlayer=0
    for i, v in pairs(defenseDict) do
        totalPlayer = totalPlayer + 1
        if self._DefensePlayerPercent[v] == nil then
            self._DefensePlayerPercent[v] = 1
        else
            self._DefensePlayerPercent[v] = self._DefensePlayerPercent[v] + 1
        end
    end

    for i, v in pairs(self._DefensePlayerPercent) do
        self._DefensePlayerPercent[i] = v / totalPlayer
    end

    --返回结果
    return self._DefensePlayerPercent[defenseId] or 0
end

--- 获取所有驻守人数最大（存在相同）的节点Id
function XGuildWarGarrisonData:GetMaxDefendResourceNodeIds()
    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) or self.ResourceNodeAttackedInfo.DefenseDic == nil then
        local roundData = XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData
        return roundData.LastProtectNodeIds
    else
        return self.ResourceNodeAttackedInfo.ProtectNodeIds
    end
end

--- 判断玩家自己是否在给定的资源点上驻守
function XGuildWarGarrisonData:CheckDefensePointIsPlayerInById(defenseId)
    local defenseDict=nil

    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) or self.ResourceNodeAttackedInfo.DefenseDic == nil then
        local roundData = XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData
        if roundData then
            defenseDict = roundData.DefenseDic
        end
    else
        defenseDict = self.ResourceNodeAttackedInfo.DefenseDic
    end

    if XTool.IsTableEmpty(defenseDict) then
        return false
    end

    local selfDefenseId = defenseDict[XPlayer.Id]
    if selfDefenseId == nil then
        return false
    end
    return selfDefenseId == defenseId
end

--- 判断玩家自己是否已经选择资源点驻守了
function XGuildWarGarrisonData:IsPlayerDefend()
    local map = self:GetDefensePointIds()
    for i, v in pairs(map) do
        if self:CheckDefensePointIsPlayerInById(i) then
            return true
        end
    end
    return false
end

--- 判断指定的资源点是否处于重建状态
function XGuildWarGarrisonData:IsDefensePointRebuilding(defenseId)
    local index = 0

    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) or XTool.IsTableEmpty(self.ResourceNodeAttackedInfo.ResourceNodesData) then
        local nodeData = self:GetResNodeDataInRoundData(defenseId)
        if nodeData then
            return nodeData.CurHp<=0
        end

        return false
    end

    index = self._AttackInfoResNodeIdMap[defenseId]

    if XTool.IsNumberValid(index) then
        return self.ResourceNodeAttackedInfo.ResourceNodesData[index] and self.ResourceNodeAttackedInfo.ResourceNodesData[index].CurHp<=0 or false
    end

    return false
end

--- 获取防守点的Id字典 <nodeId, index>
function XGuildWarGarrisonData:GetDefensePointIds()
    if XTool.IsTableEmpty(self._AttackInfoResNodeIdMap) then
        if XTool.IsTableEmpty(self._AttackInfoResNodeIdMap) then
            self:InitResNodeIdMapInRoundData()
        end
        return self._RoundDataResNodeIdMap
    end
    return self._AttackInfoResNodeIdMap
end

--- 判断最近的炮击是否播放过（通过读取客户端缓存记录的方式）
function XGuildWarGarrisonData:CheckNearestAttackAnimIsPlayed()
    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) then
        local roundData=XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData
        --判断有没有记录上一次炮击时间
        local record = XSaveTool.GetData(XDataCenter.GuildWarManager.GetGuildWarAttackTimeLocKey())

        if roundData.AttackTimes == 0 then
            return true --轮次初次开始时未发生过炮击，所以权当此次已经标记了炮击了
        end

        if XTool.IsNumberValid(record) then
            --判断是否炮击过
            return record == roundData.AttackTimes
        end

        return false
    else
        local record = XSaveTool.GetData(XDataCenter.GuildWarManager.GetGuildWarAttackTimeLocKey())

        if self.ResourceNodeAttackedInfo.AttackedTimes == 0 then
            return true --轮次初次开始时未发生过炮击，所以权当此次已经标记了炮击了
        end

        if XTool.IsNumberValid(record) then
            --判断是否炮击过
            return record == self.ResourceNodeAttackedInfo.AttackedTimes
        end

        return false
    end
end

--- 根据节点Id获取当前轮次的节点数据
function XGuildWarGarrisonData:GetResNodeDataInRoundData(NodeId)
    local roundData = XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData

    if XTool.IsTableEmpty(self._RoundDataResNodeIdMap) then
        self:InitResNodeIdMapInRoundData()
    end

    if not XTool.IsTableEmpty(self._RoundDataResNodeIdMap) then
        local index = self._RoundDataResNodeIdMap[NodeId]
        return roundData.NodeData[index]
    end
end

--- 获取当前轮次下一次炮击的时间戳
function XGuildWarGarrisonData:GetNextAttackedTime()
    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo)then
        local roundData=XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData
        if roundData then
            return roundData.NextAttackTime
        end
        return 0
    end

    return self.ResourceNodeAttackedInfo.NextAttackedTime or 0
end

--- 获取当前轮次炮击的次数
function XGuildWarGarrisonData:GetAttackedTimes()
    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) then
        local roundData=XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData
        return roundData and roundData.AttackTimes or 0
    else
        return self.ResourceNodeAttackedInfo.AttackedTimes
    end
end

--- 检查当前轮次最后一次炮击是否防守成功
function XGuildWarGarrisonData:CheckLastDefendSuccess()
    if self:GetAttackedTimes() <= 0 then
        return false
    end

    local ids = self:GetDefensePointIds()
    if not XTool.IsTableEmpty(ids) then
        for i, v in pairs(ids) do
            if self:IsDefensePointRebuilding(i)  then
                return false
            end
        end
        return true
    end
end

--- 获取当前轮次的防守数据字典
function XGuildWarGarrisonData:GetDefendDict()
    local defenseDict=nil

    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) or XTool.IsTableEmpty(self.ResourceNodeAttackedInfo.DefenseDic) then
        local roundData = XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData
        defenseDict = roundData.DefenseDic
    else--查驻守数据
        defenseDict = self.ResourceNodeAttackedInfo.DefenseDic
    end

    return defenseDict
end

--- 刷新当前轮次玩家自己驻守的资源点缓存数据
function XGuildWarGarrisonData:RefreshDefendDictData(defendNodeId)
    local data = nil

    if XTool.IsNumberValid(defendNodeId) then
        data = defendNodeId
    end

    if not XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) then
        self.ResourceNodeAttackedInfo.DefenseDic[XPlayer.Id] =  data
    end

    local roundData=XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData
    if roundData then
        roundData.DefenseDic[XPlayer.Id] =  data
    end
    self._DefensePlayerPercent = nil
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_DEFEND_UPDATE)
end

--- 获取当前轮次对应的资源的数据
function XGuildWarGarrisonData:GetLatestResourceNodeId(nodeId)
    local index = 0

    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) or XTool.IsTableEmpty(self.ResourceNodeAttackedInfo.ResourceNodesData) then
        local nodeData = self:GetResNodeDataInRoundData(nodeId)
        return nodeData
    end

    index = self._AttackInfoResNodeIdMap[nodeId]

    if XTool.IsNumberValid(index) then
        return self.ResourceNodeAttackedInfo.ResourceNodesData[index]
    end
end

--- 获取当前轮次最近一次被炮击的资源点Id
function XGuildWarGarrisonData:GetLastAttackedResourcesId()
    if XTool.IsTableEmpty(self.ResourceNodeAttackedInfo) then
        local roundData=XDataCenter.GuildWarManager.GetCurrentRound().BattleManager.CurrentRoundData

        if roundData then
            return roundData.LastAttackNodeId
        end
    else
        return self.ResourceNodeAttackedInfo.AttackedNodeId
    end
end

return XGuildWarGarrisonData