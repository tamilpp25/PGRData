---@class XScoreTowerRankPlayer
local XScoreTowerRankPlayer = XClass(nil, "XScoreTowerRankPlayer")

function XScoreTowerRankPlayer:Ctor()
    -- 进入排行榜时，当时挑战的关卡Id
    self.ScoreTowerStageCfgId = 0
    -- 进入排行榜时，当时使用的阵容角色
    ---@type number[]
    self.CharacterIds = {}
    -- 排行榜基础玩家信息
    self.Id = 0
    self.Name = ""
    self.HeadPortraitId = 0
    self.HeadFrameId = 0
    self.Score = 0
end

function XScoreTowerRankPlayer:NotifyScoreTowerRankPlayerData(data)
    self.ScoreTowerStageCfgId = data.ScoreTowerStageCfgId or 0
    self.CharacterIds = data.CharacterIds or {}
    self.Id = data.Id or 0
    self.Name = data.Name or ""
    self.HeadPortraitId = data.HeadPortraitId or 0
    self.HeadFrameId = data.HeadFrameId or 0
    self.Score = data.Score or 0
end

--region 数据获取

function XScoreTowerRankPlayer:GetScoreTowerStageCfgId()
    return self.ScoreTowerStageCfgId
end

function XScoreTowerRankPlayer:GetCharacterIds()
    local entityIds = { 0, 0, 0 }
    for i = 1, 3 do
        local id = self.CharacterIds[i] or 0
        if XTool.IsNumberValid(id) and XRobotManager.CheckIsRobotId(id) then
            local characterId = XRobotManager.GetCharacterId(id)
            if not XTool.IsNumberValid(characterId) then
                id = 0
            end
        end
        entityIds[i] = id
    end
    return entityIds
end

function XScoreTowerRankPlayer:GetId()
    return self.Id
end

function XScoreTowerRankPlayer:GetName()
    return self.Name
end

function XScoreTowerRankPlayer:GetHeadPortraitId()
    return self.HeadPortraitId
end

function XScoreTowerRankPlayer:GetHeadFrameId()
    return self.HeadFrameId
end

function XScoreTowerRankPlayer:GetScore()
    return self.Score
end

--endregion

return XScoreTowerRankPlayer
