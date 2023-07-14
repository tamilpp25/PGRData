---@class XPurchaseRecommend
local XPurchaseRecommend = XClass(nil, "XPurchaseRecommend")

function XPurchaseRecommend:Ctor(id)
    self.Config = XDataCenter.PurchaseManager.GetRecommendManager():GetPurchaseRecommendConfig(id)
    -- v1.28-采购优化-修正PurchasePackAgeId读取
    local config = self.Config.PurchasePackageId and {self.Config.PurchasePackageId} or self.Config.PurchasePackageIds
    self.PurchasePackageIds = config
    self.PurchasePackage = {}
    for index, packageId in ipairs(config) do
        local package = XDataCenter.PurchaseManager.GetPurchasePackageById(packageId)
        if package then self.PurchasePackage[index] = package end
    end
end

function XPurchaseRecommend:GetPurchasePackageId()
    return self.Config.Id
end

-- v1.28-采购优化-获取PurchasePackageId
function XPurchaseRecommend:GetPurchasePackageIdList()
    return self.PurchasePackageIds
end

function XPurchaseRecommend:GetName()
    return self.Config.Name
end

-- return ：剩余天数
function XPurchaseRecommend:GetLeaveTimeTip()
    return XUiHelper.GetTime(self:GetEndTime()
        - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XPurchaseRecommend:GetIsShowTimeTip()
    if string.IsNilOrEmpty(self.Config.EndTimeStr) then
        return false
    end
    if self:GetEndTime() <= 0 then
        return false
    end
    return true
end

function XPurchaseRecommend:GetIsRare()
    return self.Config.IsRare or false
end

function XPurchaseRecommend:GetStartTimeDate()
    return XTime.TimestampToGameDateTimeString(self:GetStartTime(), "MM.dd")
end

function XPurchaseRecommend:GetEndTimeDate()
    return XTime.TimestampToGameDateTimeString(self:GetEndTime(), "MM.dd")
end

function XPurchaseRecommend:GetStartTime()
    return XTime.ParseToTimestamp(self.Config.StartTimeStr) or 0
end

function XPurchaseRecommend:GetEndTime()
    return XTime.ParseToTimestamp(self.Config.EndTimeStr) or 0
end

function XPurchaseRecommend:GetIsInTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local startTime = self:GetStartTime()
    if startTime > 0 and nowTime < startTime then
        return false
    end
    local endTime = self:GetEndTime()
    if endTime > 0 and nowTime >= endTime then
        return false
    end
    --[[
    -- 配好礼包Id但一个礼包数据都找不到
    if #self:GetPurchasePackageIdList() and XTool.IsTableEmpty(self:GetPurchasePackage()) then
        return false
    end
    ]]
    return true
end

function XPurchaseRecommend:GetIsShow()
    if self.Config.IsLockShow then
        return true
    end
    return self:GetIsInTime()
end

function XPurchaseRecommend:GetPurchasePackage()
    -- 默认为{}
    return self.PurchasePackage
end

function XPurchaseRecommend:GetAssetPath()
    return self.Config.AssetPath
end

-- v1.28-采购优化-根据UiType获取SkipSteps
function XPurchaseRecommend:GetSkipSteps()
    -- 优化前判空逻辑过渡
    if not XTool.IsTableEmpty(self.Config.SkipSteps) then return self.Config.SkipSteps end
    local skipSteps = {}

    -- 配置SkipId跳转
    if self.Config.SkipType == XPurchaseConfigs.RecommendSkipType.SkipId and self.Config.SkipId then
        skipSteps[1] = self.Config.SkipType
        skipSteps[2] = self.Config.SkipId
        return skipSteps

    -- 默认礼包内跳转
    elseif self.Config.UiType then
        local tabsCfg = XPurchaseConfigs.GetGroupConfigType()
        local index = 1
        for step1, tab in pairs(tabsCfg)do
            local childs = tab.Childs
            for step2, uiTypes in pairs(childs)do
                if uiTypes.UiType == self.Config.UiType then
                    skipSteps[1] = XPurchaseConfigs.RecommendSkipType.Lb
                    skipSteps[2] = step1
                    skipSteps[3] = step2
                    return skipSteps
                end
            end
        end
    end
    return skipSteps
end

-- v1.28-采购优化-礼包售光逻辑修改
function XPurchaseRecommend:GetIsSellOut()
    if self.PurchasePackage == nil or #self.PurchasePackage == 0 then
        return false
    end
    for _, package in pairs(self.PurchasePackage) do
        if not package:GetIsSellOut() then
            return false
        end
    end
    return true
end

function XPurchaseRecommend:GetIsShowRedPoint()
    local value = XSaveTool.GetData("XPurchaseRecommend" .. XPlayer.Id .. self.Config.Period .. self.Config.Id)
    return value == nil
end

function XPurchaseRecommend:SetShowRedPoint()
    XSaveTool.SaveData("XPurchaseRecommend" .. XPlayer.Id .. self.Config.Period .. self.Config.Id, true)
end

return XPurchaseRecommend