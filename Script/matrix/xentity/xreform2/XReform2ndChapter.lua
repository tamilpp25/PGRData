---@class XReform2ndChapter
local XReform2ndChapter = XClass(nil, "XReform2ndChapter")

local StringFormat = string.format

function XReform2ndChapter:Ctor(id)
    self.Id = id
end

function XReform2ndChapter:GetId()
    return self.Id
end

function XReform2ndChapter:SetId(id)
    self.Id = id
end

function XReform2ndChapter:GetStarNumber()
    local stageIds = XReform2ndConfigs.GetChapterStageIdById(self.Id)
    local starNumber = 0;

    for i = 1, #stageIds do
        local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[i])

        starNumber = starNumber + stage:GetStarHistory()
    end

    return starNumber
end

function XReform2ndChapter:GetStarDesc()
    local starNumber = self:GetStarNumber()
    local fullNumber = self:GetFullStar()
    
    if starNumber > fullNumber then
        starNumber = fullNumber
    end
    
    return StringFormat("%s/%s", starNumber, fullNumber)
end

function XReform2ndChapter:GetFullStar()
    local stageIds = XReform2ndConfigs.GetChapterStageIdById(self.Id)
    local fullStar = 0

    for i = 1, #stageIds do
        local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[i])

        fullStar = fullStar + stage:GetFullPoint()
    end

    return fullStar
end

function XReform2ndChapter:IsFinished()
    local starNumber = self:GetStarNumber()
    local fullNumber = self:GetFullStar()
    
    return starNumber >= fullNumber
end

function XReform2ndChapter:IsPassed()
    ---@type XReform2ndStage
    local stageIds = XReform2ndConfigs.GetChapterStageIdById(self.Id)

    for i = 1, #stageIds do
        local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[i])

        if not stage:GetIsPassed() then
            return false
        end
    end

    return true
end

function XReform2ndChapter:GetName()
    return XReform2ndConfigs.GetChapterDescById(self.Id)
end

function XReform2ndChapter:GetOpenTime()
    return XReform2ndConfigs.GetChapterOpenTimeById(self.Id)
end

function XReform2ndChapter:GetOrder()
    return XReform2ndConfigs.GetChapterOrderById(self.Id)
end 

function XReform2ndChapter:GetStageIdList()
    return XReform2ndConfigs.GetChapterStageIdById(self.Id)
end

function XReform2ndChapter:GetThemeDesc()
    return XReform2ndConfigs.GetChapterEventDescById(self.Id)
end

function XReform2ndChapter:GetStageListLength()
    return self.StageListLength
end

return XReform2ndChapter
