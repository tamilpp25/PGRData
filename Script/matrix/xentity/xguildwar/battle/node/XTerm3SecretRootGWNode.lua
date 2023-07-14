local XNormalGWNode = require("XEntity/XGuildWar/Battle/Node/XNormalGWNode")
local XGuildWarAreaBuild = require("XEntity/XGuildWar/Team/XGuildWarAreaBuild")
--三期隐藏节点 (视未来变化 看看是通用节点 还是三期特有节点)
---@class XTerm3SecretRootGWNode
local XTerm3SecretRootGWNode = XClass(XNormalGWNode, "XTerm3SecretRootGWNode")
--为了更好管理内存
--在打开队伍编辑界面时才加载队伍数据 GetTeamBuild 创建数据
--队伍编辑界面销毁时 销毁队伍数据 CleanUpXTeamCache 清除缓存
------------------------------------
--!!!在编辑界面不存在时 不能获取队伍数据!!!
-----------------------------------
---
function XTerm3SecretRootGWNode:Ctor(id)
end

-- data : XGuildWarNodeData
function XTerm3SecretRootGWNode:UpdateWithServerData(data)
    XTerm3SecretRootGWNode.Super.UpdateWithServerData(self, data)
end

-- 更新多节点区域战斗数据
---param areaTeamInfos XGuildWarTeamInfo(C#)[]
function XTerm3SecretRootGWNode:UpdateAreaTeamNodeInfos(areaTeamInfos)
    for index,teamInfo in ipairs(areaTeamInfos) do
        local child = self:GetChildById(teamInfo.NodeId)
        if child then
            child:UpdateAreaTeamNodeInfo(teamInfo)
        end
    end
end

-- 更新多节点区域记录数据
---param areaTeamRecordInfos XGuildWarTeamInfo(C#)[]
function XTerm3SecretRootGWNode:UpdateAreaTeamRecordInfo(areaTeamRecordInfos)
    for index,recordInfo in ipairs(areaTeamRecordInfos) do
        local child = self:GetChildById(recordInfo.NodeId)
        if child then
            child:UpdateAreaTeamRecordInfo(recordInfo)
        end
    end
end

--获取队伍组 Entity
-- fixed 是否根据后端数据 修正队伍
--- @return XGuildWarAreaBuild
function XTerm3SecretRootGWNode:GetTeamBuild(fixed)
    if self.__TeamBuild == nil then
        local xTeams = {}
        local childs = self:GetChildrenNodes()
        for index,childNode in ipairs(childs) do
            table.insert(xTeams,childNode:GetXTeam())
        end
        self.__TeamBuild = XGuildWarAreaBuild.New(xTeams)
    end
    if fixed then self.__TeamBuild:CheckAndFixedBuildMember() end
    return self.__TeamBuild
end

-- 获取所有队伍构建提交数据
--return XGuildWarTeamInfo[](C#)
function XTerm3SecretRootGWNode:GetXGuildWarTeamInfos()
    local teamInfoList = {}
    local childs = self:GetChildrenNodes()
    for index,childNode in ipairs(childs) do
        table.insert(teamInfoList,childNode:GetXGuildWarTeamInfo())
    end
    return teamInfoList
end

-- 获取区域总分
function XTerm3SecretRootGWNode:GetAreaScore()
    local score = 0
    local childs = self:GetChildrenNodes()
    for index,childNode in ipairs(childs) do
        if childNode:GetScoreLock() then
            score = score + childNode:GetScore()
        end
    end
    return score
end

-- 获取区域记录总分
function XTerm3SecretRootGWNode:GetAreaRecord()
    local score = 0
    local childs = self:GetChildrenNodes()
    for index,childNode in ipairs(childs) do
        score = score + childNode:GetRecord()
    end
    return score
end

-- 获取子区域的作战情况
function XTerm3SecretRootGWNode:GetAreaSituation()
    local situationDatas = {}
    local childs = self:GetChildrenNodes()
    for index,childNode in ipairs(childs) do
        if childNode:GetHasRecord() then
            local situationData = {}
            situationData.ChildIndex = index
            situationData.Score = childNode:GetRecord()
            situationData.CharactorInfo = childNode.RecordCharacterInfos
            table.insert(situationDatas, situationData)
        end
    end
    return situationDatas
end

-- 获取子区域的作战记录情况
function XTerm3SecretRootGWNode:GetAreaRecordSituation()
    local situationDatas = {}
    local childs = self:GetChildrenNodes()
    for index,childNode in ipairs(childs) do
        if childNode:GetRecord() > 0 then
            local situationData = {}
            situationData.ChildIndex = index
            situationData.Score = childNode:GetRecord()
            situationData.CaptainPos = childNode.RecordCaptainPos
            situationData.FirstFightPos = childNode.RecordFirstFightPos
            situationData.CharactorInfo = childNode.RecordCharacterInfos
            table.insert(situationDatas, situationData)
        end
    end
    return situationDatas
end

-- 获取区域上次记录总分
function XTerm3SecretRootGWNode:GetAreaRecordScore()
    local score = 0
    local childs = self:GetChildrenNodes()
    for index,childNode in ipairs(childs) do
        score = score + childNode.RecordPoint
    end
    return score
end
    
--清除队伍数据缓存
function XTerm3SecretRootGWNode:CleanUpBuildCache()
    local childs = self:GetChildrenNodes()
    for index,childNode in ipairs(childs) do
        childNode:CleanUpTeamCache()
    end
    self.__TeamBuild = nil
end

--地图界面移动到这个节点时回调(因为隐藏节点不用通用Detail 所以似乎用不上这个接口)
function XTerm3SecretRootGWNode:OnDetailGoCallback()
    if not self:GetIsDead() then
        XLuaUiManager.Close("UiGuildWarStageDetail")
        XLuaUiManager.Open("UiGuildWarConcealStageDetail", self, false)
        return true
    end
    return false
end



return XTerm3SecretRootGWNode