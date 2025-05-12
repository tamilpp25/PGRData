---@class XAnniversaryModel : XModel
local XAnniversaryModel = XClass(XModel, "XAnniversaryModel")

local NormalTableKeyMap = {
    AnniversaryActivity = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = 'ID' },
}

function XAnniversaryModel:OnInit()
    --初始化内部变量
    self._ConfigUtil:InitConfigByTableKey('MiniActivity/AnniversaryActivity', NormalTableKeyMap, XConfigUtil.CacheType.Normal)

    self._ReviewActivityServerConfigs = nil
    self._ReviewSlapFaceIsShown = false
    self._ReviewActivityId = 1
    self._ReviewData = nil
end

function XAnniversaryModel:ClearPrivate()
    --这里执行内部数据清理
end

function XAnniversaryModel:ResetAll()
    --这里执行重登数据清理
    self._ReviewActivityServerConfigs = nil
    self._ReviewSlapFaceIsShown = false
    self._ReviewActivityId = 1
    self._ReviewData = nil
end

--region ActivityData
function XAnniversaryModel:SetReviewActivityServerConfig(activityConfigs)
    self._ReviewActivityServerConfigs = {}
    for index, config in pairs(activityConfigs) do
        self._ReviewActivityServerConfigs[index] = config
    end
end

function XAnniversaryModel:RefreshReviewData(reviewData)
    self:RefreshActivityId(reviewData.ActivityId)
    self:SetReviewIsShown(reviewData.SlapFaceState)
    self._ReviewData = reviewData
end

function XAnniversaryModel:SetReviewIsShown(value)
    self._ReviewSlapFaceIsShown = value
end

function XAnniversaryModel:RefreshActivityId(activityId)
    self._ReviewActivityId = activityId or self._ReviewActivityId
end

function XAnniversaryModel:GetReviewIsShown()
    return self._ReviewSlapFaceIsShown and self:GetActivityInTime()
end

function XAnniversaryModel:GetActivityId()
    return self._ReviewActivityId
end

function XAnniversaryModel:GetActivityInTime()
    if XTool.IsTableEmpty(self._ReviewActivityServerConfigs) then
        return false
    end
    
    local cfg = self._ReviewActivityServerConfigs[self:GetActivityId()]
    if not cfg then 
        return false 
    end
    
    local startTime = cfg.StartTime
    local endTime = cfg.EndTime
    if not startTime or (startTime == 0) then
        return false
    end
    if not endTime or (endTime == 0) then
        return false
    end
    local now = XTime.GetServerNowTimestamp()
    return (startTime <= now) and (endTime > now)
end

function XAnniversaryModel:CheckIsReviewDataEmpty()
    return XTool.IsTableEmpty(self._ReviewData)
end

function XAnniversaryModel:GetReviewActivityServerConfigs()
    return self._ReviewActivityServerConfigs
end
--endregion

----------config start----------

function XAnniversaryModel:GetAnniversaryActivity()
    return self._ConfigUtil:GetByTableKey(NormalTableKeyMap.AnniversaryActivity)
end

----------config end----------


return XAnniversaryModel