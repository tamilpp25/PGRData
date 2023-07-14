--兵法蓝图章节对象（现阶段一个章节就是一个活动ID）
local XRpgTowerChapter = XClass(nil, "XRpgTowerChapter")
--================
--构造函数，初始化活动数据
--================
function XRpgTowerChapter:Ctor(activityId)
    if activityId then self:RefreshData(activityId) end
end
--================
--重新初始化活动数据
--================
function XRpgTowerChapter:RefreshData(activityId)
    self.ActivityId = activityId
    self.LastPassIndex = 1
    self:RefreshStage()
end
--================
--重新初始化关卡
--================
function XRpgTowerChapter:ResetStage()
    local rStageList = XRpgTowerConfig.GetRStageListByActivityId(self.ActivityId)
    for index = 1, #rStageList do
        local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(rStageList[index].StageId)
        if rStage then rStage:Reset() end
    end
end
--================
--刷新关卡数据
--================
function XRpgTowerChapter:RefreshStage()
    local rStageList = XRpgTowerConfig.GetRStageListByActivityId(self.ActivityId)
    self.AllClear = true
    for index = self.LastPassIndex > 0 and self.LastPassIndex or 1, #rStageList do
        local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(rStageList[index].StageId)
        if index == 1 and (not rStage:GetIsPass()) then
            self.LastPassIndex = 0
        elseif rStage:GetIsPass() then
            self.LastPassIndex = index
        else
            self.AllClear = false
        end
    end
    self.TotalStageNum = #rStageList
    -- 获取当前关卡进度
    self.CurrentIndex = (self.LastPassIndex < self.TotalStageNum and (self.LastPassIndex + 1)) or self.TotalStageNum
    local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(rStageList[self.CurrentIndex].StageId)
    self.CurrentRStage = rStage
end
--================
--获取章节配置ID
--================
function XRpgTowerChapter:GetChapterId()
    return self.ActivityId or -1
end
--================
--获取章节是否全部通关
--================
function XRpgTowerChapter:GetIsClear()
    return self.AllClear
end
--================
--获取最后通关的关卡序号
--================
function XRpgTowerChapter:GetLassPassIndex()
    return self.LastPassIndex
end
--================
--获取当前关卡序号（若全通关则显示最后一关）
--================
function XRpgTowerChapter:GetCurrentIndex()
    return self.CurrentIndex
end
--================
--获取当前关卡的RStage对象
--================
function XRpgTowerChapter:GetCurrentRStage()
    return self.CurrentRStage
end
--================
--获取当前章节通关进度字符串
--================
function XRpgTowerChapter:GetPassProgressStr()
    return CS.XTextManager.GetText("RpgTowerChapterProgressStr", self.LastPassIndex, self.TotalStageNum)
end
--================
--获取关卡动态列表的内容，根据通关情况把可显示的关卡列表传出
--================
function XRpgTowerChapter:GetDynamicRStageList(canShowGridNum, showFurtherNum)
    --先刷新关卡状态
    self:RefreshStage()
    local listLength = self.CurrentIndex + showFurtherNum
    if listLength >= self.TotalStageNum or self.TotalStageNum <= canShowGridNum then
        listLength = self.TotalStageNum
    elseif listLength <= canShowGridNum then
        listLength = canShowGridNum
    end
    local rStageList = XRpgTowerConfig.GetRStageListByActivityId(self.ActivityId)
    local showStageList = {}
    for orderId = 1, listLength do
        showStageList[orderId] = rStageList[orderId]
    end
    return showStageList
end

return XRpgTowerChapter