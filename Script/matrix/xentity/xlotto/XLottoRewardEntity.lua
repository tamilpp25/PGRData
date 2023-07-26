---@class XLottoRewardEntity
local XLottoRewardEntity = XClass(nil, "XLottoRewardEntity")

function XLottoRewardEntity:Ctor(id)
    self.Id = id
    self.IsGeted = false
end

function XLottoRewardEntity:MarkGeted()
    self.IsGeted = true
end

function XLottoRewardEntity:GetRewardCfg()
    return XLottoConfigs.GetLottoRewardCfgById(self.Id)
end

function XLottoRewardEntity:GetProbCfg()
    return XLottoConfigs.GetLottoProbShowCfgById(self.Id)
end

function XLottoRewardEntity:GetId()
    return self.Id
end

function XLottoRewardEntity:GetIsGeted()
    return self.IsGeted
end

function XLottoRewardEntity:GetTemplateId()
    return self:GetRewardCfg().TemplateId
end

function XLottoRewardEntity:GetCount()
    return self:GetRewardCfg().Count
end

function XLottoRewardEntity:GetRareLevel()
    return self:GetProbCfg().RareLevel
end

function XLottoRewardEntity:GetPriority()
    return self:GetProbCfg().Priority
end

function XLottoRewardEntity:GetProbShowList()
    return self:GetProbCfg().ProbShow
end

return XLottoRewardEntity