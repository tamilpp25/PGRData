---@class XCerberusGameStoryPoint
local XCerberusGameStoryPoint = XClass(nil, "XCerberusGameStoryPoint")
-- 剧情节点

function XCerberusGameStoryPoint:Ctor(config)
    self.Id = config.Id
    self.Config = config
    self.Type = config.StoryPointType
    if self.Type == XEnumConst.CerberusGame.StoryPointType.Communicate then
        self.CommunicationId = tonumber(config.StoryPointTypeParams[1])
    else
        self.StageId = tonumber(config.StoryPointTypeParams[1])
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
        local xPreStoryPoint = XMVCA.XCerberusGame:GetXStoryPointById(preStortyPointId)
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
    return XMVCA.XCerberusGame:GetXStageById(self.StageId)
end

function XCerberusGameStoryPoint:GetCommunicationId()
    return self.CommunicationId
end

function XCerberusGameStoryPoint:GetStoryLineId()
    if self.StoryLineId then
        return self.StoryLineId
    end

    for k, v in pairs(XMVCA.XCerberusGame:GetModelCerberusGameStoryLine()) do
        if table.contains(v.StoryPointIds, self:GetId()) then
            self.StoryLineId = v.Id
            return v.Id
        end
    end
end

function XCerberusGameStoryPoint:GetChapterId()
    if self.ChapterId then
        return self.ChapterId
    end

    local storyLineId = self:GetStoryLineId()
    if not storyLineId then
        return
    end

    for k, v in pairs(XMVCA.XCerberusGame:GetModelCerberusGameStoryLine()) do
        if v.Id == storyLineId then
            self.ChapterId = v.ChapterId
            return v.ChapterId
        end
    end
end

-- 获取上阵的指定角色
function XCerberusGameStoryPoint:GetTargetCharacterList()
    if self:GetType() ~= XEnumConst.CerberusGame.StoryPointType.Battle then
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