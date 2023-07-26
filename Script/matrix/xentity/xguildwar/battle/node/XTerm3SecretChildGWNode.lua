local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
local XGuildWarAreaTeam = require("XEntity/XGuildWar/Team/XGuildWarAreaTeam")
--三期隐藏节点 (视未来变化 看看是通用节点 还是三期特有节点)
---@class XTerm3SecretChildGWNode
local XTerm3SecretChildGWNode = XClass(XNormalGWNode, "XTerm3SecretChildGWNode")
local DEFAULT_TEAM_MEMBER = 3 --默认队伍人数 未来或许会跟配置改变？
function XTerm3SecretChildGWNode:Ctor(id)
    -- 队长位
    self.CaptainPos = 0
    -- 首战位
    self.FirstFightPos = 0
    -- 当前挑战记录的队伍角色数据
    -- List<XGuildWarTeamCharacterInfo>
    self.CharacterInfos = {}
    --当前积分
    self.CurPoint = 0
    --上次记录积分
    self.RecordPoint = 0
    --队伍
    ---@type XGuildWarAreaTeam
    self.__Team = nil
end

-- data : XGuildWarNodeData
function XTerm3SecretChildGWNode:UpdateWithServerData(data)
    XTerm3SecretChildGWNode.Super.UpdateWithServerData(self, data)
end


--更新多节点区域 子节点数据 由父节点调用
-- areaTeamInfo : XGuildWarTeamInfo
function XTerm3SecretChildGWNode:UpdateAreaTeamNodeInfo(areaTeamInfo)
    self.CaptainPos = areaTeamInfo.CaptainPos
    self.FirstFightPos = areaTeamInfo.FirstFightPos
    self.CharacterInfos = areaTeamInfo.CharacterInfos
    self.CurPoint = areaTeamInfo.CurPoint
    self.RecordPoint = areaTeamInfo.LastPoint
end

--更新多节点区域 子节点记录数据 由父节点调用
-- recordInfo : XGuildWarTeamInfo
function XTerm3SecretChildGWNode:UpdateAreaTeamRecordInfo(recordInfo)
    self.RecordCaptainPos = recordInfo.CaptainPos
    self.RecordFirstFightPos = recordInfo.FirstFightPos
    self.RecordCharacterInfos = recordInfo.CharacterInfos
end

--重置区域分数(本地 只在请求服务器修改 服务器不更新时 才本地自己更新)
function XTerm3SecretChildGWNode:ResetCurPoint()
    self.CurPoint = 0
    self.RecordCaptainPos = self.CaptainPos
    self.RecordFirstFightPos = self.FirstFightPos
    self.RecordCharacterInfos = XTool.Clone(self.CharacterInfos)
end

--更新记录(本地 只在请求服务器修改 服务器不更新时 才本地自己更新)
function XTerm3SecretChildGWNode:UpdateRecord(newRecord)
    self.RecordPoint = newRecord
end

--获取队伍实例数据
---@return XGuildWarAreaTeam
function XTerm3SecretChildGWNode:GetXTeam()
    if self.__Team == nil then
        local rootId = self:GetParentNode():GetId()
        local id = "XGWNodeAreaTeam" .. rootId .. "_" ..self:GetId()
        self.__Team = XGuildWarAreaTeam.New(id)
        self.__Team:SetMemberNumber(DEFAULT_TEAM_MEMBER)
        XDataCenter.TeamManager.SetXTeam(self.__Team)
    end
    --如果没被初始化 或者从自定义组队转变成
    if self.__Team.DataType == XGuildWarConfig.AreaTeamDataType.Uninit then
        if self:GetScoreLock() then
            self.__Team:LoadTeamByData(self.CharacterInfos)
        else
            self.__Team:LoadTeamByCache()
        end
    --如果节点已经锁定 但类型不是 把队伍类型改为锁定类型
    elseif self.__Team.DataType == XGuildWarConfig.AreaTeamDataType.Custom and self:GetScoreLock() then
        self.__Team:LoadTeamByData(self.CharacterInfos)
    --如果节点已经解锁 但类型不是 把队伍类型改为自定义类型
    elseif self.__Team.DataType == XGuildWarConfig.AreaTeamDataType.Locked and not self:GetScoreLock() then
        self.__Team:LoadTeamByCache()
    end
    return self.__Team
end

--获取节点队伍服务器格式数据
--return XGuildWarTeamInfo(C#)
function XTerm3SecretChildGWNode:GetXGuildWarTeamInfo()
    --锁定状态的数据不提交
    if self:GetScoreLock() then return nil end
    local xGuildWarTeamInfo = self:GetXTeam():GetXFightTeamData()
    xGuildWarTeamInfo.NodeId = self:GetId()
    xGuildWarTeamInfo.CurPoint = self.CurPoint
    xGuildWarTeamInfo.LastPoint = self.RecordPoint
    return xGuildWarTeamInfo
end

--获取当前区域成绩
function XTerm3SecretChildGWNode:GetScore()
    return self.CurPoint
end

--获取当前区域记录成绩
function XTerm3SecretChildGWNode:GetRecord()
    return self.RecordPoint
end

--获取当前节点成绩是否被锁定
function XTerm3SecretChildGWNode:GetScoreLock()
    return not (self.CurPoint == 0)
end

--获取当前节点是否存在记录
function XTerm3SecretChildGWNode:GetHasRecord()
    return self.RecordPoint > 0
end

--清除队伍数据缓存
function XTerm3SecretChildGWNode:CleanUpTeamCache()
    XDataCenter.TeamManager.RemoveXTeam(self.__Team)
    self.__Team = nil
end

return XTerm3SecretChildGWNode