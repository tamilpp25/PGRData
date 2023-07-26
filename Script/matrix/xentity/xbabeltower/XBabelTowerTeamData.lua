---@class XBabelTowerTeamData
local XBabelTowerTeamData = XClass(nil, "XBabelTowerTeamData")

local Default = {
    TeamId = 0,
    CurScore = 0,
    MaxScore = 0,
    IsReset = false,
    IsSyn = false, --是否与服务端数据同步
    CaptainPos = 0,
    CharacterIds = { 0, 0, 0 },
    ChallengeBuffDic = {},
    SupportBuffDic = {},
    StageLevel = 0,
}

local TeamMaxCount = 3

function XBabelTowerTeamData:Ctor(teamId)
    for key, v in pairs(Default) do
        if type(v) == "table" then
            self[key] = {}
        else
            self[key] = v
        end
    end
    self.TeamId = teamId
    self.CharacterIds = { 0, 0, 0 }
    self.StageLevel = XFubenBabelTowerConfigs.Difficult.Easy
    self.CaptainPos = XFubenBabelTowerConfigs.LEADER_POSITION
    self.FirstFightPos = XFubenBabelTowerConfigs.FIRST_FIGHT_POSITION
end

-- 更新服务器下发的队伍数据
function XBabelTowerTeamData:UpdateData(data)
    self.TeamId = data.Id
    self.CurScore = data.CurScore
    self.MaxScore = data.MaxScore or 0
    self.IsReset = data.IsReset
    self:UpdateCharacter(data.TeamList, data.TeamRobotList)
    self.IsSyn = true
    self.StageLevel = data.StageLevel and data.StageLevel ~= 0 and data.StageLevel or XFubenBabelTowerConfigs.Difficult.Easy
    self.CaptainPos = data.CaptainPos and data.CaptainPos ~= 0 and data.CaptainPos or XFubenBabelTowerConfigs.LEADER_POSITION
    self.FirstFightPos = data.FirstFightPos and data.FirstFightPos ~= 0 and data.FirstFightPos or XFubenBabelTowerConfigs.FIRST_FIGHT_POSITION

    self:UpdateChallengeBuffDic(data.ChallengeBuffInfos)

    self.SupportBuffDic = {}
    for _, buffData in pairs(data.SupportBuffInfos or {}) do
        self.SupportBuffDic[buffData.GroupId] = buffData.BufferId
    end
end

function XBabelTowerTeamData:UpdateCharacter(teamList, teamRobotList)
    self.CharacterIds = { 0, 0, 0 }
    for i, charId in pairs(teamList or {}) do
        if XTool.IsNumberValid(charId) then
            self.CharacterIds[i] = charId
        end
    end
    for i, robotId in pairs(teamRobotList or {}) do
        if XTool.IsNumberValid(robotId) then
            self.CharacterIds[i] = robotId
        end
    end
end

function XBabelTowerTeamData:ResetSyn()
    self.IsSyn = false
end

function XBabelTowerTeamData:IsSyned()
    return self.IsSyn
end

function XBabelTowerTeamData:IsReseted()
    return self.IsReset
end

function XBabelTowerTeamData:Reset()
    self.IsReset = true
end

function XBabelTowerTeamData:Recover()
    self.IsReset = false
end

function XBabelTowerTeamData:GetTeamId()
    return self.TeamId
end

function XBabelTowerTeamData:GetChallengeBuffDic()
    return XTool.Clone(self.ChallengeBuffDic)
end

function XBabelTowerTeamData:UpdateChallengeBuffDic(buffDatas)
    --刷新前先置空 解决问题：玩家失败返回关卡选择界面读取进入关卡前的BUFF选择，而不是之前最高等级的BUFF选择
    self.ChallengeBuffDic = {}
    for _, buffData in pairs(buffDatas or {}) do
        self.ChallengeBuffDic[buffData.GroupId] = buffData.BufferId
    end
end

function XBabelTowerTeamData:GetSupportBuffDic()
    return XTool.Clone(self.SupportBuffDic)
end

function XBabelTowerTeamData:UpdateSupportBuffDic(buffDatas)
    self.SupportBuffDic = {}
    for _, buffData in pairs(buffDatas or {}) do
        self.SupportBuffDic[buffData.GroupId] = buffData.BufferId
    end
end

function XBabelTowerTeamData:GetCharacterIds(includeReset)
    if includeReset then
        return XTool.Clone(self.CharacterIds)
    end

    if self:IsReseted() then
        return { 0, 0, 0 }
    end

    return XTool.Clone(self.CharacterIds)
end

function XBabelTowerTeamData:UpdateCharacterIds(characterIds)
    if not characterIds then return end
    self.CharacterIds = XTool.Clone(characterIds)
end

function XBabelTowerTeamData:ClearCharacterIds()
    self.CharacterIds = { 0, 0, 0 }
    self.CaptainPos = XFubenBabelTowerConfigs.LEADER_POSITION
    self.FirstFightPos = XFubenBabelTowerConfigs.FIRST_FIGHT_POSITION
end

function XBabelTowerTeamData:GetScore(ignoreReset)
    if ignoreReset then
        return self.CurScore or 0
    end
    return not self.IsReset and self.CurScore or 0
end

function XBabelTowerTeamData:GetMaxScore()
    return self.MaxScore
end

function XBabelTowerTeamData:GetSelectDiffcult()
    return self.StageLevel
end

function XBabelTowerTeamData:SelectDiffcult(difficult)
    self.StageLevel = difficult
end

function XBabelTowerTeamData:GetCaptainPos()
    return self.CaptainPos
end

function XBabelTowerTeamData:GetFirstFightPos()
    return self.FirstFightPos
end

function XBabelTowerTeamData:SetCaptainPos(captainPos)
    self.CaptainPos = captainPos
end

function XBabelTowerTeamData:SetFirstFightPos(firstFightPos)
    self.FirstFightPos = firstFightPos
end

function XBabelTowerTeamData:HasCaptain()
    local characterId = self.CharacterIds[self.CaptainPos]
    return characterId and characterId ~= 0
end

return XBabelTowerTeamData