local XRewardPreviewViewModel = XClass(nil, "XRewardPreviewViewModel")

function XRewardPreviewViewModel:Ctor()
    --[[ SpecialRewards && NormalRewards
        data : {
            TemplateId,
            Count,
            StockCount, -- 库存数量
        }
    ]]
    -- 特殊奖励
    self.SpecialRewards = nil
    self.SpecialTitle = nil
    -- 普通奖励
    self.NormalRewards = nil
    self.NormalTitle = nil
    -- 标题
    self.ShowTitle = nil
    -- 当前获得数量
    self.CurrentCount = nil
    -- 最大可获得数量
    self.MaxCount = nil
    -- 是否优先展示特殊奖励
    self.IsFirstShowSpecial = nil
end

function XRewardPreviewViewModel:SetSpecialRewards(datas)
    self.SpecialRewards = datas
    if self.IsFirstShowSpecial == nil then self.IsFirstShowSpecial = true end
end

function XRewardPreviewViewModel:GetSpecialRewards()
    return self.SpecialRewards or {}
end

function XRewardPreviewViewModel:SetNormalRewards(datas)
    self.NormalRewards = datas
    if self.IsFirstShowSpecial == nil then self.IsFirstShowSpecial = false end
end

function XRewardPreviewViewModel:GetNormalRewards()
    return self.NormalRewards or {}
end

function XRewardPreviewViewModel:SetTitle(value)
    self.ShowTitle = value
end

function XRewardPreviewViewModel:GetTitle()
    return self.ShowTitle
end

function XRewardPreviewViewModel:SetCurrentCount(value)
    self.CurrentCount = value
end

function XRewardPreviewViewModel:GetCurrentCount()
    return self.CurrentCount or 0
end

function XRewardPreviewViewModel:SetMaxCount(value)
    self.MaxCount = value
end

function XRewardPreviewViewModel:GetMaxCount()
    return self.MaxCount or 0
end

function XRewardPreviewViewModel:SetSpecialTitle(value)
    self.SpecialTitle = value
end

function XRewardPreviewViewModel:GetSpecialTitle()
    return self.SpecialTitle
end

function XRewardPreviewViewModel:SetNormalTitle(value)
    self.NormalTitle = value
end

function XRewardPreviewViewModel:GetNormalTitle()
    return self.NormalTitle
end

function XRewardPreviewViewModel:GetIsFirstShowSpecial()
    if self.IsFirstShowSpecial == nil then return true end
    return self.IsFirstShowSpecial
end

return XRewardPreviewViewModel