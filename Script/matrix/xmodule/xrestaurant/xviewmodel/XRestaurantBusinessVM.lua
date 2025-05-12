local XRestaurantViewModel = require("XModule/XRestaurant/XViewModel/XRestaurantViewModel")

---@class XRestaurantBusinessVM : XRestaurantViewModel
---@field Data XRestaurantBusiness
---@field Property XRestaurantBusinessProperty
local XRestaurantBusinessVM = XClass(XRestaurantViewModel, "XRestaurantBusinessVM")

function XRestaurantBusinessVM:InitData()
    self.AreaBuffDict = {}
    self._Model:UpdateUnlockProduct()
end

function XRestaurantBusinessVM:UpdateAccount(offlineBill, offlineBillUpdateTime)
    self.Data:UpdateAccount(offlineBill, offlineBillUpdateTime)
end

function XRestaurantBusinessVM:UpdateViewModel()
    self:UpdateAreaBuff()
    self._Model:UpdateHotSale()
end

function XRestaurantBusinessVM:LevelUp(level)
    self.Data:UpdateLevel(level)
    self._Model:UpdateUnlockProduct()
    self._OwnControl:UpdateProduct()
end

function XRestaurantBusinessVM:UpdateAreaBuff()
    local applyBuff = self.Data.BuffMgt:GetApplyBuff()
    for _, info in ipairs(applyBuff) do
        self.AreaBuffDict[info.SectionType] = info.BuffId
    end
    local defaultIds = self.Data.BuffMgt:GetDefaultBuffIds()
    for _, buffId in ipairs(defaultIds) do
        local areaType = self._Model:GetBuffAreaType(buffId)
        if not self.AreaBuffDict[areaType] then
            self.AreaBuffDict[areaType] = buffId
        end
    end
end

function XRestaurantBusinessVM:GetAreaBuffId(areaType)
    return self.AreaBuffDict[areaType]
end

function XRestaurantBusinessVM:IsInBusiness()
    return self._Model:IsInBusiness()
end

function XRestaurantBusinessVM:IsShowOfflineBill()
    local offlineBillUpdateTime = self.Data:GetOfflineBillUpdateTime()
    if offlineBillUpdateTime <= 0 then
        return false
end
    local billTime = self:GetOfflineBillTime()
    if billTime < 0 then
        return false
    end
    local nowTime = XTime.GetServerNowTimestamp()

    if nowTime - offlineBillUpdateTime < billTime then
        return false
    end
    return true
end

function XRestaurantBusinessVM:GetOfflineBillTime()
    local template = self._Model:GetActivityConfigTemplate()
    if not template then
        return -1
    end
    return template.OfflineBillTime
end

function XRestaurantBusinessVM:IsLevelUp()
    return self.Data:IsLevelUp()
end

function XRestaurantBusinessVM:IsGetSignReward()
    return self.Data:IsGetSignReward()
end

function XRestaurantBusinessVM:IsSignOpen()
    local template = self._Model:GetSignTemplate()
    if not template then
        return false
    end
    return XFunctionManager.CheckInTimeByTimeId(template.TimeId)
end

function XRestaurantBusinessVM:GetSignCurDay()
    if not self:IsSignOpen() then
        return 0
    end
    return XTime.GetDayCountUntilTime(self._Model:GetSignBeginTime(), true) + 1
end

function XRestaurantBusinessVM:GetSignRewardId()
    local template = self._Model:GetSignRewardTemplate(self:GetSignCurDay())
    if not template then
        return 0
    end
    return template.RewardId
end


function XRestaurantBusinessVM:GetSignNpcImgUrl()
    local template = self._Model:GetSignRewardTemplate(self:GetSignCurDay())
    if not template then
        return 0
    end
    return template.NpcImgUrl
end


function XRestaurantBusinessVM:GetSignDescription()
    local template = self._Model:GetSignRewardTemplate(self:GetSignCurDay())
    if not template then
        return ""
    end
    return XUiHelper.ReplaceTextNewLine(template.SignDesc)
end

function XRestaurantBusinessVM:GetSignReply()
    local template = self._Model:GetSignRewardTemplate(self:GetSignCurDay())
    if not template then
        return ""
    end
    return XUiHelper.ReplaceTextNewLine(template.ReplyBtnDesc)
end

function XRestaurantBusinessVM:GetSignActivityName()
    local template = self._Model:GetSignTemplate()
    if not template then
        return ""
    end
    return template.Name
end

function XRestaurantBusinessVM:UpdateSignData(isGetSignReward, signActivityId)
    self.Data:UpdateSignData(isGetSignReward, signActivityId)
end

function XRestaurantBusinessVM:UpdatePerformInfo(infos)
    self.Data:UpdatePerformInfos(infos)
end

function XRestaurantBusinessVM:UpdateMenuRedPointMarkCount()
    self.Data:UpdateMenuRedPointMarkCount()
end

function XRestaurantBusinessVM:UpdateLevelConditionEventChange()
    self.Data:UpdateLevelConditionEventChange()
end

function XRestaurantBusinessVM:UpdateBuffRedPointMarkCount()
    self.Data:UpdateBuffRedPointMarkCount()
end

function XRestaurantBusinessVM:GetAccelerateCount()
    return self._Model:GetAccelerateCount()
end

function XRestaurantBusinessVM:GetAccelerateUseTimes()
    return self.Data:GetAccelerateUseTimes()
end

function XRestaurantBusinessVM:GetAccelerateUseLimit()
    return self._Model:GetAccelerateUseLimit()
end

function XRestaurantBusinessVM:IsAccelerateUpperLimit()
    return self._Model:IsAccelerateUpperLimit()
end

function XRestaurantBusinessVM:GetAccelerateTime()
    return self._Model:GetAccelerateTime()
end

function XRestaurantBusinessVM:GetHotSaleDataList(day)
    local dict = self._Model:GetHotSaleDataDict(day)
    if not dict then
        return {}
    end
    local list = {}
    for foodId, addition in pairs(dict) do
        table.insert(list, {
            Id = foodId,
            Addition = addition
        })
    end
    return list
end

function XRestaurantBusinessVM:GetMenuTabList()
    return self._Model:GetMenuTabList()
end

function XRestaurantBusinessVM:GetTabMenuName(tabId)
    local template = self._Model:GetMenuTabTemplate(tabId)
    return template and template.TabName or ""
end

function XRestaurantBusinessVM:GetTabMenuTimeId(tabId)
    local template = self._Model:GetMenuTabTemplate(tabId)
    return template and template.TimeId or 0
end

function XRestaurantBusinessVM:CheckMenuTabInTime(tabId)
    local template = self._Model:GetMenuTabTemplate(tabId)
    if not template then
        return false
    end
    return XFunctionManager.CheckInTimeByTimeId(template.TimeId, true)
end

function XRestaurantBusinessVM:GetMenuTabUnlockTimeStr(tabId, format)
    local timeId = self:GetTabMenuTimeId(tabId)
    local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(timeId)
    return XTime.TimestampToGameDateTimeString(timeOfBgn, format)
end

function XRestaurantBusinessVM:GetSubTimeTip(subTime)
    local tip = self._Model:GetClientConfigValue("OfflineBillText", 1)
    return string.format(tip, XUiHelper.GetTime(subTime, XUiHelper.TimeFormatType.TO_A_MINUTE))
end

function XRestaurantBusinessVM:GetTalkTemplate(talkId)
    return self._Model:GetTalkTemplate(talkId)
end

return XRestaurantBusinessVM