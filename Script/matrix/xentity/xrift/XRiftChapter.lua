---@class XRiftChapter 大秘境【区域】实例（一共6个）
local XRiftChapter = XClass(nil, "XRiftChapter")

function XRiftChapter:Ctor(config)
    self.Config = config
    ---@type XRiftFightLayer[]
    self.EntityFightLayersDic = {}
    self.EntityFightLayersList = {}
    self.OutliersList = {}
    -- 服务端下发后确认的数据
    self.s_UnlockedLayerOrderMax = nil -- 已解锁最高层数
    self.s_PassedLayerOrderMax = nil -- 已通关最高层数
    self.s_LeftSweepTimes = nil --剩余扫荡次数
end

-- 向下建立关系
function XRiftChapter:InitRelationshipChainDown(xFightLayer)
    self.EntityFightLayersDic[xFightLayer:GetId()] = xFightLayer
end

-- 【获取】Id
function XRiftChapter:GetId()
    return self.Config.Id
end

-- 【获取】Config
function XRiftChapter:GetConfig()
    return self.Config
end

-- 【检查】是否处于未作战状态，如果为false，说明区域内有作战层处于作战状态，并返回作战层id
function XRiftChapter:CheckNoneData()
    local res = true
    local fightLayerId = nil
    for k, xFightLayer in pairs(self:GetAllFightLayers()) do
        if not xFightLayer:CheckNoneData() then
            res = false
            fightLayerId = xFightLayer:GetId()
            break
        end
    end
    return res, fightLayerId
end

-- 【检查】红点
function XRiftChapter:CheckRedPoint()
    return not self:CheckHasLock() and not self:CheckHadFirstEntered()
end

function XRiftChapter:CheckPreLock()
    -- 前置区域没通过 或者 没到达开放时间，都会上锁
    local preLock = true
    if self:GetId() <= 1 then
        preLock = false
    elseif XDataCenter.RiftManager.GetEntityChapterById(self:GetId() - 1):CheckHasPassed() then
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
    local curr, total = self:GetProgress()
    return curr >= total
end

-- 【获取】开启区域的剩余时间
function XRiftChapter:GetOpenLeftTime()
    local nowTime = XTime.GetServerNowTimestamp() -- 使用目标时间点做标记来替代计时器
    local passTime = nowTime - XDataCenter.RiftManager.GetActivityStartTime()
    local leftTime = self:GetConfig().UnlockTime - passTime
    local timeDesc = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    return leftTime, timeDesc
end

-- 【获取】所有作战层
function XRiftChapter:GetAllFightLayers()
    return self.EntityFightLayersDic
end

-- 【获取】按Id排序的顺序表
---@return XRiftFightLayer[]
function XRiftChapter:GetAllFightLayersOrderList()
    if not XTool.IsTableEmpty(self.EntityFightLayersList) then
        return self.EntityFightLayersList
    end

    for k, xFightLayer in pairs(self.EntityFightLayersDic) do
        table.insert(self.EntityFightLayersList, xFightLayer)
    end

    table.sort(self.EntityFightLayersList, function (a, b)
        return a:GetId() < b:GetId()
    end)

    return self.EntityFightLayersList
end

-- 【获取】所有异常点(多队伍作战层)
function XRiftChapter:GetAllOutliersList()
    if not XTool.IsTableEmpty(self.OutliersList) then
        return self.OutliersList
    end

    for k, xFightLayer in pairs(self.EntityFightLayersDic) do
        if xFightLayer:GetType() == XRiftConfig.LayerType.Multi then
            table.insert(self.OutliersList, xFightLayer)
        end
    end

    table.sort(self.OutliersList, function (a, b)
        return a:GetId() < b:GetId()
    end)

    return self.OutliersList
end

-- 【获取】当前区域正在作战的层
function XRiftChapter:GetCurPlayingFightLayer()
    for k, xFightLayer in pairs(self:GetAllFightLayersOrderList()) do
        if xFightLayer:CheckHasStarted() then
            return xFightLayer
        end
    end
end

-- 【获取】当前区域进度
function XRiftChapter:GetProgress()
    local allFightLayers = self:GetAllFightLayersOrderList()
    local firstLayerInCurChapter = allFightLayers[1]
    local total = #allFightLayers
    local finalCur = (self.s_PassedLayerOrderMax or 0) - firstLayerInCurChapter:GetId() + 1
    finalCur = finalCur < 0 and 0 or finalCur

    return finalCur, total
end

-- 【检查】检查当前chapter是否刚刚完成首通，是的话打开弹窗 并执行传入的sureCb
function XRiftChapter:CheckFirstPassAndOpenTipFun(afterSureCb)
    local nextChapter = XDataCenter.RiftManager.GetEntityChapterById(self:GetId() + 1)
    if self:CheckHasPassed() and nextChapter and not nextChapter:CheckHasLock() and XDataCenter.RiftManager.GetIsFirstPassChapterTrigger() then
        local title = CS.XTextManager.GetText("TipTitle")
        local content = CS.XTextManager.GetText("RiftChapterFirstPassTip")
        local sureCallback = function ()
            if afterSureCb then
                afterSureCb(nextChapter)
            end
        end
        XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
    end
end

-- 【保存】首次进入
function XRiftChapter:SaveFirstEnter()
    local key = "RiftChapter"..XPlayer.Id..self:GetId()
    XSaveTool.SaveData(key, true)
end

-- 【检查】是否有过首次进入
function XRiftChapter:CheckHadFirstEntered()
    local key = "RiftChapter"..XPlayer.Id..self:GetId()
    return XSaveTool.GetData(key)
end

-- 【获取】已通关最高作战层
function XRiftChapter:GetPassedLayerOrderMaxFightLayer()
    if self:GetProgress() <= 0 then
        return
    end

    local list = self:GetAllFightLayersOrderList()
    local initOrder = list[1]:GetConfig().Order -- 先拿到服务器下发的最高通关的序号（没错，服务器只发当前最高通关作战层的order，不是id.）
    local order = (self.s_PassedLayerOrderMax or initOrder) - initOrder + 1
    local xFightLayer = self:GetAllFightLayersOrderList()[order]
    return xFightLayer
end

function XRiftChapter:GetMaxUnlockLayer()
    return self.s_UnlockedLayerOrderMax or 0
end

function XRiftChapter:GetMaxPassLayer()
    return self.s_PassedLayerOrderMax or 0
end

function XRiftChapter:SyncData(data)
    self.s_UnlockedLayerOrderMax = data.UnlockedLayerOrderMax -- 已解锁最高层数
    self.s_PassedLayerOrderMax = data.PassedLayerOrderMax -- 已通关最高层数
end

---获取区域进度
function XRiftChapter:GetChapterProgress()
    local count = 0
    local datas = self:GetAllFightLayersOrderList()
    for _, data in ipairs(datas) do
        if data:CheckHasPassed() then
            count = count + 1
        end
    end
    return count, #datas
end

return XRiftChapter