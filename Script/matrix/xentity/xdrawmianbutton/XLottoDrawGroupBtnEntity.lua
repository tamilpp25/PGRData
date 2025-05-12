local XDrawGroupBtnBaseEntity = require("XEntity/XDrawMianButton/XDrawGroupBtnBaseEntity")
local XLottoDrawGroupBtnEntity = XClass(XDrawGroupBtnBaseEntity, "XLottoDrawGroupBtnEntity")

function XLottoDrawGroupBtnEntity:Ctor()
    self.data = {}
end

function XLottoDrawGroupBtnEntity:UpdateData(data)
    self.data = data or {}
    self.Id = data:GetId()
    self.Banner = data:GetBanner()
    self.UiPrefab = data:GetUiPrefab()
    self.UiBackGround = data:GetUiBackGround()
    self.Tag = data:GetTag()
    local drawData = data:GetDrawData()
    self.BannerBeginTime = drawData:GetBeginTime()
    self.BannerEndTime = drawData:GetEndTime()
    self.BottomTimes = drawData:GetCurRewardCount()
    self.MaxBottomTimes = drawData:GetMaxRewardCount()

    self.UseItemIdList = {}
    table.insert(self.UseItemIdList, XDataCenter.ItemManager.ItemId.FreeGem)
    table.insert(self.UseItemIdList, drawData:GetConsumeId())
end

function XLottoDrawGroupBtnEntity:GetRuleType()
    return XDrawConfigs.RuleType.Lotto
end

function XLottoDrawGroupBtnEntity:GetName()
    return self.data:GetName() or ""
end

function XLottoDrawGroupBtnEntity:GetRareRank()
    return 0
end

function XLottoDrawGroupBtnEntity:GetGroupBtnBg()
    return self.data:GetGroupBtnBg()
end

function XLottoDrawGroupBtnEntity:GetTopRewardData()
    local drawData = self.data:GetDrawData()
    return drawData:GetTopRewardData()
end

function XLottoDrawGroupBtnEntity:GetBottomText()
    local bottomText = CS.XTextManager.GetText("NewDrawMainBottomText")
    return string.format("%s%d/%d", bottomText, self.BottomTimes, self.MaxBottomTimes)
end

function XLottoDrawGroupBtnEntity:GetSwitchText()
    return ""
end

function XLottoDrawGroupBtnEntity:GoDraw(cb)
    if cb then cb() end
    XLuaUiManager.Open(self:GetUiPrefab(), self.data, function()
        end, self:GetUiBackGround())
end

function XLottoDrawGroupBtnEntity:IsShowTag()
    local IsShowNewTag = false

    if self.BannerBeginTime > 0 then
        if XDataCenter.DrawManager.IsShowNewTag(self.BannerBeginTime, XDrawConfigs.RuleType.Lotto, self.Id) then
            IsShowNewTag = true
        end
    end
    return IsShowNewTag
end

return XLottoDrawGroupBtnEntity