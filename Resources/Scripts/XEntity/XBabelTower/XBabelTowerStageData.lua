local XBabelTowerTeamData = require("XEntity/XBabelTower/XBabelTowerTeamData")

local tableInsert = table.insert

local XBabelTowerStageData = XClass(nil, "XBabelTowerStageData")

local Default = {
    StageId = 0,
    GuideId = 0,
    MaxScore = 0,
    IsSyn = false, --是否与服务端数据同步
    TeamDatas = {},
}

function XBabelTowerStageData:Ctor(stageId)
    for key, v in pairs(Default) do
        if type(v) == "table" then
            self[key] = {}
        else
            self[key] = v
        end
    end

    self.StageId = stageId
    self:InitTeamDatas()
end

function XBabelTowerStageData:InitTeamDatas()
    local teamCount = XFubenBabelTowerConfigs.GetStageTeamCount(self.StageId)
    for teamId = 1, teamCount do
        self.TeamDatas[teamId] = XBabelTowerTeamData.New(teamId)
    end
end

function XBabelTowerStageData:UpdateData(data)
    self.StageId = data.Id
    self.GuideId = data.GuildId
    self.MaxScore = data.MaxScore
    self.IsSyn = true
    self:UpdateTeamDatas(data.TeamDatas)
end

function XBabelTowerStageData:IsSyned()
    return self.IsSyn
end

function XBabelTowerStageData:Syn()
    self.IsSyn = true
end

function XBabelTowerStageData:GetTeamData(teamId)
    local teamData = self.TeamDatas[teamId]
    if not teamData then
        XLog.Error("XBabelTowerStageData:GetTeamData Error:获取活动关卡队伍信息失败, stageId: " .. self.StageId .. ", teamId: " .. teamId)
        return
    end
    return teamData
end

function XBabelTowerStageData:UpdateTeamDatas(teamDatas)
    for _, clientTeamData in pairs(self.TeamDatas) do
        clientTeamData:ResetSyn()
    end
    for _, teamData in pairs(teamDatas or {}) do
        local teamId = teamData.Id
        local clientTeamData = self:GetTeamData(teamId)
        clientTeamData:UpdateData(teamData)
    end
end

function XBabelTowerStageData:GetTotalUsedCharacterIds(paramTeamId)
    local totalCharacterIds = {}

    for _, teamData in pairs(self.TeamDatas) do
        if not teamData:IsReseted() and teamData:GetTeamId() ~= paramTeamId then
            local characterIds = teamData:GetCharacterIds()
            for _, characterId in pairs(characterIds) do
                if characterId > 0 then
                    totalCharacterIds[characterId] = characterId
                end
            end
        end
    end

    return totalCharacterIds
end

function XBabelTowerStageData:GetTotalScore()
    local totalScore = 0
    for _, teamData in pairs(self.TeamDatas) do
        totalScore = totalScore + teamData:GetScore()
    end
    return totalScore
end

function XBabelTowerStageData:GetGudieId()
    return self.GuideId
end

function XBabelTowerStageData:GetTeamIdList()
    local teamIdList = {}
    for _, teamData in ipairs(self.TeamDatas) do
        tableInsert(teamIdList, teamData:GetTeamId())
    end
    return teamIdList
end

function XBabelTowerStageData:GetSynTeamNum()
    local teamNum = 0
    for _, teamData in ipairs(self.TeamDatas) do
        if not teamData:IsSyned() then
            break
        end
        teamNum = teamNum + 1
    end
    return teamNum
end

return XBabelTowerStageData