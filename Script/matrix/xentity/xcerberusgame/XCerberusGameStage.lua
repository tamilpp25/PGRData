local XCerberusGameTeam = require("XEntity/XCerberusGame/XCerberusGameTeam")
---@class XCerberusGameStage
local XCerberusGameStage = XClass(nil, "XCerberusGameStage")

-- 剧情节点
function XCerberusGameStage:Ctor(stageId)
    self.XStoryPoint = nil
    -- 服务器下发确认的数据
    self.StageId = stageId
    self.s_Pass = nil
    self.s_StarsMark = nil
    self.s_GotStarRewardIds = nil
    self.BuffInfo = {}
    ---@type XCerberusGameTeam
    self.XTeam = nil
end

---@return XCerberusGameStoryPoint
function XCerberusGameStage:GetXStoryPoint()
    if not self.XStoryPoint then
        local storyPointId = XMVCA.XCerberusGame:GetStoryPointByStageIdPointDic(self.StageId)
        if storyPointId then
            self.XStoryPoint = XMVCA.XCerberusGame:GetXStoryPointById(storyPointId)
        end
    end

    return self.XStoryPoint
end

function XCerberusGameStage:SetServerData(data)
    self.s_Pass = data.Passed
    self.s_StarsMark = data.StarMark
    self.s_GotStarRewardIds = data.GotStarRewardIds
    self.s_StageParams = data.StageParams
    self:SetXTeamByServer(data.TeamInfo)
end

function XCerberusGameStage:SetXTeamByServer(teamInfo)
    local xTeam = self:GetXTeam()
    if not xTeam then
        xTeam = XCerberusGameTeam.New(self.StageId)
    end
    local roleIds = {0, 0, 0}
    for k, id in pairs(teamInfo.CharacterIdList) do
        if XTool.IsNumberValid(id) then
            roleIds[k] = id
        end
    end
    for k, id in pairs(teamInfo.RobotIdList) do
        if XTool.IsNumberValid(id) then
            roleIds[k] = id
        end
    end
    xTeam:UpdateEntityIds(roleIds)
    xTeam:UpdateCaptainPos(teamInfo.CaptainPos)
    xTeam:UpdateFirstFightPos(teamInfo.FirstFightPos)
    self:SetXTeam(xTeam)
end

function XCerberusGameStage:SetXTeam(xTeam)
    self.XTeam = xTeam
end

function XCerberusGameStage:GetXTeam()
    if XTool.IsTableEmpty(self.XTeam) then
        self.XTeam = XCerberusGameTeam.New(self.StageId)
    end

    return self.XTeam
end

function XCerberusGameStage:SetPassed(flag)
    self.s_Pass = flag
end

function XCerberusGameStage:GetIsPassed()
    return self.s_Pass
end

function XCerberusGameStage:GetStageParams()
    return self.s_StageParams or {}
end

function XCerberusGameStage:GetStarsMapByMark()
    local _, res = XTool.GetStageStarsFlag(self.s_StarsMark, 3)
    return res
end

function XCerberusGameStage:GetStarsCount()
    local count = 0
    for k, v in pairs(self:GetStarsMapByMark()) do
        if v then
            count = count + 1
        end
    end
    return count
end

function XCerberusGameStage:GetIsOpen()
    local allConfigs = XMVCA.XCerberusGame:GetModelCerberusGameChallenge()
    local stageConfig = allConfigs[self.StageId]
    if not stageConfig then
        return true
    end

    local preStageId = stageConfig.PreStageId
    if not XTool.IsNumberValid(preStageId) then
        return true
    end

    local xStage = XMVCA.XCerberusGame:GetXStageById(preStageId)
    return xStage:GetIsPassed()
end

function XCerberusGameStage:GetStageId()
    return self.StageId
end

function XCerberusGameStage:GetCommunicationId()
    return self.CommunicationId
end

function XCerberusGameStage:GetType()
    return self.Type
end

return XCerberusGameStage