---@class XRiftChapter:XEntity 大秘境【区域】
---@field _OwnControl XRiftControl
---@field _Config XTableRiftChapter
---@field _EntityFightLayersDic XRiftFightLayer[]
---@field _EntityFightLayersList XRiftFightLayer[]
---@field _OutliersList XRiftFightLayer[] 所有多队伍作战层
local XRiftChapter = XClass(XEntity, "XRiftChapter")

function XRiftChapter:OnInit()

end

function XRiftChapter:OnRelease()

end

function XRiftChapter:SetConfig(config)
    self._Config = config
end

-- 【获取】Id
function XRiftChapter:GetChapterId()
    return self._Config.Id
end

-- 【获取】Config
function XRiftChapter:GetConfig()
    return self._Config
end

-- 【检查】红点
function XRiftChapter:CheckRedPoint()
    return not self:CheckHasLock() and not self:CheckHadFirstEntered()
end

function XRiftChapter:CheckPreLock()
    -- 前置区域没通过 或者 没到达开放时间，都会上锁
    local preLock = true
    if self:GetChapterId() <= 1 then
        preLock = false
    elseif self._OwnControl:GetEntityChapterById(self:GetChapterId() - 1):CheckHasPassed() then
        preLock = false
    end

    return preLock
end

function XRiftChapter:CheckTimeLock()
    local timeLock = true
    if self:GetOpenLeftTime() <= 0 then
        timeLock = false
    end

    return timeLock
end

-- 【检查】上锁
function XRiftChapter:CheckHasLock()
    -- 前置区域没通过 或者 没到达开放时间，都会上锁
    local preLock = self:CheckPreLock()
    local timeLock = self:CheckTimeLock()

    return timeLock or preLock
end

-- 【检查】通过该区域
function XRiftChapter:CheckHasPassed()
    local layers = self:GetAllFightLayersOrderList()
    return layers[#layers]:CheckFirstPassed()
end

-- 【获取】开启区域的剩余时间
function XRiftChapter:GetOpenLeftTime()
    local nowTime = XTime.GetServerNowTimestamp() -- 使用目标时间点做标记来替代计时器
    local passTime = nowTime - self._OwnControl:GetActivityStartTime()
    local leftTime = self:GetConfig().UnlockTime - passTime
    local timeDesc = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    return leftTime, timeDesc
end

-- 【获取】所有作战层
function XRiftChapter:GetAllFightLayers()
    if not self._EntityFightLayersDic then
        self._EntityFightLayersDic = {}
        local layerIds = self._OwnControl:GetLayerIdsByChapterId(self._Config.Id)
        for _, id in pairs(layerIds) do
            self._EntityFightLayersDic[id] = self._OwnControl:GetEntityFightLayerById(id)
        end
    end
    return self._EntityFightLayersDic
end

-- 【获取】按Id排序的顺序表
---@return XRiftFightLayer[]
function XRiftChapter:GetAllFightLayersOrderList()
    if not XTool.IsTableEmpty(self._EntityFightLayersList) then
        return self._EntityFightLayersList
    end

    self._EntityFightLayersList = {}
    for _, xFightLayer in pairs(self:GetAllFightLayers()) do
        table.insert(self._EntityFightLayersList, xFightLayer)
    end

    table.sort(self._EntityFightLayersList, function(a, b)
        return a:GetFightLayerId() < b:GetFightLayerId()
    end)

    return self._EntityFightLayersList
end

-- 【获取】当前区域进度
--function XRiftChapter:GetProgress()
--    local allFightLayers = self:GetAllFightLayersOrderList()
--    local firstLayerInCurChapter = allFightLayers[1]
--    local total = #allFightLayers
--    local finalCur = self:GetMaxPassLayer() - firstLayerInCurChapter:GetFightLayerId() + 1
--    finalCur = finalCur < 0 and 0 or finalCur
--
--    return finalCur, total
--end

-- 【检查】检查当前chapter是否刚刚完成首通，是的话打开弹窗 并执行传入的sureCb
function XRiftChapter:CheckFirstPassAndOpenTipFun(afterSureCb)
    local nextChapterId = self:GetChapterId() + 1
    local nextChapter = self._OwnControl:GetEntityChapterById(nextChapterId)
    if self:CheckHasPassed() and nextChapter and not nextChapter:CheckHasLock() and self._OwnControl:GetIsFirstPassChapterTrigger() then
        local title = CS.XTextManager.GetText("TipTitle")
        local content = CS.XTextManager.GetText("RiftChapterFirstPassTip")
        local sureCallback = function()
            if not afterSureCb then
                return
            end
            if self._OwnControl:IsCurrPlayingChapter(nextChapterId) then
                afterSureCb(nextChapterId)
            else
                self._OwnControl:RequestRiftStartChapter(nextChapterId, function()
                    afterSureCb(nextChapterId)
                end)
            end
        end
        XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
    end
end

-- 【保存】首次进入
function XRiftChapter:SaveFirstEnter()
    local key = "RiftChapter" .. XPlayer.Id .. self:GetChapterId()
    XSaveTool.SaveData(key, true)
end

-- 【检查】是否有过首次进入
function XRiftChapter:CheckHadFirstEntered()
    local key = "RiftChapter" .. XPlayer.Id .. self:GetChapterId()
    return XSaveTool.GetData(key)
end

---已解锁最高层数
--function XRiftChapter:GetMaxUnlockLayer()
--    local chapterData = self._OwnControl:GetChapterData(self._Config.Id)
--    return chapterData and chapterData.UnlockedLayerOrderMax or 0
--end

---已通关最高层数
--function XRiftChapter:GetMaxPassLayer()
--    local chapterData = self._OwnControl:GetChapterData(self._Config.Id)
--    return chapterData and chapterData.PassedLayerOrderMax or 0
--end

---获取区域进度
--function XRiftChapter:GetChapterProgress()
--    local count = 0
--    local datas = self:GetAllFightLayersOrderList()
--    for _, data in ipairs(datas) do
--        if data:CheckHasPassed() then
--            count = count + 1
--        end
--    end
--    return count, #datas
--end

-- 章节最后一关挑战关的通关时间（最佳时间）
function XRiftChapter:GetPassTime()
    local chapterData = self._OwnControl:GetChapterData(self._Config.Id)
    return chapterData and chapterData.TotalPassTime or 0
end

return XRiftChapter