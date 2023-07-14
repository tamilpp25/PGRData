local XDrawGroupBtnBaseEntity = XClass(nil, "XDrawGroupBtnBaseEntity")
function XDrawGroupBtnBaseEntity:Ctor()
    self.Id = 0
    self.Banner = ""
    self.UiPrefab = ""
    self.UiBackGround = ""
    self.Tag = 0
    self.BannerBeginTime = 0
    self.BannerEndTime = 0
    self.BottomTimes = 0
    self.MaxBottomTimes = 0
    self.SwitchDrawIdCount = 0
    self.MaxSwitchDrawIdCount = 0
    self.Order = 0
end

function XDrawGroupBtnBaseEntity:GetId()
    return self.Id
end

function XDrawGroupBtnBaseEntity:GetBanner()
    return self.Banner
end

function XDrawGroupBtnBaseEntity:GetUiPrefab()
    return self.UiPrefab
end

function XDrawGroupBtnBaseEntity:GetUiBackGround()
    return self.UiBackGround
end

function XDrawGroupBtnBaseEntity:GetTag()
    return self.Tag
end

function XDrawGroupBtnBaseEntity:GetBannerBeginTime()
    return self.BannerBeginTime
end

function XDrawGroupBtnBaseEntity:GetBannerEndTime()
    return self.BannerEndTime
end

function XDrawGroupBtnBaseEntity:GetBottomTimes()
    return self.BottomTimes
end

function XDrawGroupBtnBaseEntity:GetMaxBottomTimes()
    return self.MaxBottomTimes
end

function XDrawGroupBtnBaseEntity:GetUseItemIdList()
    return self.UseItemIdList
end

function XDrawGroupBtnBaseEntity:GetSwitchDrawIdCount()
    return self.SwitchDrawIdCount
end

function XDrawGroupBtnBaseEntity:GetMaxSwitchDrawIdCount()
    return self.MaxSwitchDrawIdCount
end

function XDrawGroupBtnBaseEntity:GetOrder()
    return self.Order
end

function XDrawGroupBtnBaseEntity:DoSelect(root)
    root:CreateBanner(self)
    return true
end

function XDrawGroupBtnBaseEntity:IsMainButton()
    return false
end

return XDrawGroupBtnBaseEntity