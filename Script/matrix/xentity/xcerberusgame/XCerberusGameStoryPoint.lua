---@class XCerberusGameStoryPoint
local XCerberusGameStoryPoint = XClass(nil, "XCerberusGameStoryPoint")
-- 剧情节点

function XCerberusGameStoryPoint:Ctor(config)
    self.Id = config.Id
    self.Config = config
    self.Type = config.StoryPointType
    if self.Type == XCerberusGameConfig.StoryPointType.Communicate then
        self.CommunicationId = tonumber(config.StoryPointTypeParams[1])
    else
        self.StageId = tonumber(config.StoryPointTypeParams[1])
    end

    if self.StageId then
        self:GetXStage():SetXStoryPoint(self)
    end

    -- 服务器下发确认的数据
    self.s_Pass = false
end

function XCerberusGameStoryPoint:GetId()
    return self.Id
end

function XCerberusGameStoryPoint:GetConfig()
    return self.Config
end

function XCerberusGameStoryPoint:SetPassed(flag)
    self.s_Pass = flag
end

function XCerberusGameStoryPoint:GetIsPassed()
    return self.s_Pass
end

function XCerberusGameStoryPoint:GetIsShow()
    local configs = self:GetConfig().PrePointIds
    if XTool.IsTableEmpty(configs) then
        return true
    end
    for k, preStortyPointId in pairs(configs) do
        local xPreStoryPoint = XDataCenter.CerberusGameManager.GetXStoryPointById(preStortyPointId)
        if xPreStoryPoint:GetIsPassed() then
            return true
        end
    end
    return false
end

function XCerberusGameStoryPoint:GetIsOpen()
    if not XTool.IsNumberValid(self:GetConfig().OpenCondition) then
        return true
    end

    return XConditionManager.CheckCondition(self:GetConfig().OpenCondition)
end

function XCerberusGameStoryPoint:GetStageId()
    return self.StageId
end

function XCerberusGameStoryPoint:GetXStage()
    if not self.StageId then
        return
    end
    return XDataCenter.CerberusGameManager.GetXStageById(self.StageId)
end

function XCerberusGameStoryPoint:GetCommunicationId()
    return self.CommunicationId
end

function XCerberusGameStoryPoint:GetStoryLineId()
    for k, v in pairs(XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameStoryLine)) do
        if table.contains(v.StoryPointIds, self:GetId()) then
            return v.Id
        end
    end
end

-- 获取上阵的指定角色
function XCerberusGameStoryPoint:GetTargetCharacterList()
    if self:GetType() ~= XCerberusGameConfig.StoryPointType.Battle then
        return nil
    end

    local res = {}
    local params = self:GetConfig().StoryPointTypeParams
    for i = 2, #params, 1 do
        local charId = params[i]
        if charId then
            table.insert(res, tonumber(charId))
        end
    end

    return res
end

function XCerberusGameStoryPoint:GetType()
    return self.Type
end

return XCerberusGameStoryPoint