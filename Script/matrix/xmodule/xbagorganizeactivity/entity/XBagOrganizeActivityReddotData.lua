--- 背包整理玩法红点封装类
---@class XBagOrganizeActivityReddotData
local XBagOrganizeActivityReddotData = XClass(nil, 'XBagOrganizeActivityReddotData')

function XBagOrganizeActivityReddotData:UpdateUniqueKeyByActivityId(activityId)
    self._UniqueKey = 'BagOrganizeActivity_'..tostring(activityId)..'_'..tostring(XPlayer.Id)
end

function XBagOrganizeActivityReddotData:GetUniqueKey()
    return self._UniqueKey    
end

--region 章节蓝点

function XBagOrganizeActivityReddotData:CheckChapterIsNew(chapterId)
    if string.IsNilOrEmpty(self._UniqueKey) then
        return false
    end
    
    local reddotTable = XSaveTool.GetData(self._UniqueKey)

    if reddotTable == nil or XTool.IsTableEmpty(reddotTable.ChapterReddot) or not reddotTable.ChapterReddot[chapterId] then
        return true
    end
    
    return false
end

function XBagOrganizeActivityReddotData:SetChapterToOld(chapterId)
    if string.IsNilOrEmpty(self._UniqueKey) then
        return
    end
    
    local reddotTable = XSaveTool.GetData(self._UniqueKey)

    if reddotTable == nil then
        reddotTable = {}
        XSaveTool.SaveData(self._UniqueKey, reddotTable)
    end

    if reddotTable.ChapterReddot == nil then
        reddotTable.ChapterReddot = {}
    end

    if not reddotTable.ChapterReddot[chapterId] then
        reddotTable.ChapterReddot[chapterId] = true

        XSaveTool.SaveData(self._UniqueKey, reddotTable)
    end
end

--endregion

--region 商店蓝点

--endregion

--region 关卡攻略提示蓝点

function XBagOrganizeActivityReddotData:GetStageTipsShowStateByStateId(stageId)
    if string.IsNilOrEmpty(self._UniqueKey) then
        return false
    end

    local reddotTable = XSaveTool.GetData(self._UniqueKey)

    if reddotTable == nil or XTool.IsTableEmpty(reddotTable.StageTipsReddot) or not reddotTable.StageTipsReddot[stageId] then
        return true
    end

    return false
end

function XBagOrganizeActivityReddotData:SetStageTipsShowStageByStateId(stageId)
    if string.IsNilOrEmpty(self._UniqueKey) then
        return
    end

    local reddotTable = XSaveTool.GetData(self._UniqueKey)

    if reddotTable == nil then
        reddotTable = {}
        XSaveTool.SaveData(self._UniqueKey, reddotTable)
    end

    if reddotTable.StageTipsReddot == nil then
        reddotTable.StageTipsReddot = {}
    end

    if not reddotTable.StageTipsReddot[stageId] then
        reddotTable.StageTipsReddot[stageId] = true

        XSaveTool.SaveData(self._UniqueKey, reddotTable)
    end
end

--endregion

return XBagOrganizeActivityReddotData