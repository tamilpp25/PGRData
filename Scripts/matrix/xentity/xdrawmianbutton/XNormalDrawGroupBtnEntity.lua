local XDrawGroupBtnBaseEntity = require("XEntity/XDrawMianButton/XDrawGroupBtnBaseEntity")
---@class XNormalDrawGroupBtnEntity:XDrawGroupBtnBaseEntity
local XNormalDrawGroupBtnEntity = XClass(XDrawGroupBtnBaseEntity, "XNormalDrawGroupBtnEntity")
local CSTextManagerGetText = CS.XTextManager.GetText
function XNormalDrawGroupBtnEntity:Ctor()
    
end

function XNormalDrawGroupBtnEntity:GetCfg()
    return XDrawConfigs.GetDrawGroupRuleById(self.Id)
end

function XNormalDrawGroupBtnEntity:UpdateData(data)
    self.Id = data.Id
    self.Banner = data.Banner
    self.UiPrefab = data.UiPrefab
    self.UiBackGround = data.UiBackGround
    self.Tag = data.Tag
    self.BannerBeginTime = data.BannerBeginTime;
    self.BannerEndTime = data.BannerEndTime;
    self.BottomTimes = data.BottomTimes;
    self.MaxBottomTimes = data.MaxBottomTimes;
    self.SwitchDrawIdCount = data.SwitchDrawIdCount
    self.MaxSwitchDrawIdCount = data.MaxSwitchDrawIdCount
    self.Order = data.Order

    self.UseItemIdList = {}
    table.insert(self.UseItemIdList, XDataCenter.ItemManager.ItemId.FreeGem)
    table.insert(self.UseItemIdList, data.UseItemId)
end

function XNormalDrawGroupBtnEntity:GetRuleType()
    return XDrawConfigs.RuleType.Normal
end

function XNormalDrawGroupBtnEntity:GetRuleType()
    return XDrawConfigs.RuleType.Normal
end

function XNormalDrawGroupBtnEntity:GetName()
    return self:GetCfg().TitleCN
end

function XNormalDrawGroupBtnEntity:GetRareRank()
    return self:GetCfg().RareRank
end

function XNormalDrawGroupBtnEntity:GetGroupBtnBg()
    return self:GetCfg().GroupBtnBg
end

function XNormalDrawGroupBtnEntity:GetGroupBtnBg()
    return self:GetCfg().GroupBtnBg
end

function XNormalDrawGroupBtnEntity:GetNewHandBottomCount()
    return self:GetCfg().NewHandBottomCount
end

function XNormalDrawGroupBtnEntity:GetGroupType()
    return self:GetCfg().SpecialBottomMin > 0 and 
    self:GetCfg().SpecialBottomMax > 0 and 
    XDrawConfigs.GroupType.Destiny or XDrawConfigs.GroupType.Normal
end

function XNormalDrawGroupBtnEntity:GetBottomText()
    local bottomText = CSTextManagerGetText("NewDrawMainBottomText")
    if self:GetCfg().SpecialBottomMin > 0 and self:GetCfg().SpecialBottomMax > 0 then
        return string.format("%s%d/%d~%d", bottomText, self.BottomTimes, self:GetCfg().SpecialBottomMin, self:GetCfg().SpecialBottomMax)
    else
        return string.format("%s%d/%d", bottomText, self.BottomTimes, self.MaxBottomTimes)
    end
end

function XNormalDrawGroupBtnEntity:GetSwitchText()
    if self.MaxSwitchDrawIdCount > 0 then
        local count = self.MaxSwitchDrawIdCount - self.SwitchDrawIdCount
        return count > 0 and CSTextManagerGetText("DrawBannerSelectCountText", count) or CSTextManagerGetText("DrawBannerSelectNotCountText")
    end
    return ""
end

function XNormalDrawGroupBtnEntity:GoDraw(cb)
    XDataCenter.DrawManager.GetDrawInfoList(self:GetId(), function()
            if cb then cb() end
            XLuaUiManager.Open(self:GetUiPrefab(), self:GetId(), function()
                end, self:GetUiBackGround())
        end) 
end

function XNormalDrawGroupBtnEntity:IsShowTag()
    local IsShowNewTag = false

    if self.BannerBeginTime > 0 then
        if XDataCenter.DrawManager.IsShowNewTag(self.BannerBeginTime, XDrawConfigs.RuleType.Normal, self.Id) then
            IsShowNewTag = true
        end
    end
    return IsShowNewTag
end

function XNormalDrawGroupBtnEntity:IsShowFreeTip()
    return XDataCenter.DrawManager.CheckHasFreeTicket(self:GetId())
end

return XNormalDrawGroupBtnEntity