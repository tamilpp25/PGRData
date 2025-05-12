---@class XRiftFightLayer:XEntity 大秘境【作战层】
---@field _OwnControl XRiftControl
---@field _ParentChapter XRiftChapter
local XRiftFightLayer = XClass(XEntity, "XRiftFightLayer")

function XRiftFightLayer:OnInit()

end

function XRiftFightLayer:OnRelease()

end

function XRiftFightLayer:SetConfig(config)
    ---@type XTableRiftLayer
    self._Config = config
    ---@type XTableRiftLayerDetail
    self._ClientConfig = self._OwnControl:GetLayerDetailConfigById(self._Config.Id)
end

-- 【获取】Id
function XRiftFightLayer:GetFightLayerId()
    return self._Config.Id
end

-- 【获取】Config
function XRiftFightLayer:GetConfig()
    return self._Config
end

-- 【获取】父区域
---@return XRiftChapter
function XRiftFightLayer:GetParent()
    if not self._ParentChapter then
        self._ParentChapter = self._OwnControl:GetEntityChapterById(self._Config.ChapterId)
    end
    return self._ParentChapter
end

-- 【检查】当前作战层是否处于作战中
function XRiftFightLayer:CheckIsOwnFighting()
    local curr, total = self:GetProgress()
    return curr > 0 and curr < total
end

-- 【获取】当前作战层进度,注意：层pass不代表进度大于1，因为层pass是首通，层可以反复打
function XRiftFightLayer:GetProgress()
    local curr = 0
    local total = 0
    local stageGroup = self:GetStageGroup()
    if stageGroup then
        for _, xStage in pairs(stageGroup:GetAllEntityStages()) do
            if xStage:CheckHasPassed() then
                curr = curr + 1
            end
            total = total + 1
        end
    end
    return curr, total
end

---【检查】是否首通过该作战层
function XRiftFightLayer:CheckFirstPassed()
    return self._OwnControl:CheckLayerFirstPassed(self._Config.Id)
end

---当前关卡是否已通关
function XRiftFightLayer:CheckHasPassed()
    return self._OwnControl:CheckLayerPassed(self._Config.Id)
end

-- 【检查】红点(查看该层后，或者被领取跃升奖励后消失)
function XRiftFightLayer:CheckRedPoint()
    return not self:CheckHasLock() and not self:CheckHadFirstEntered()
end

-- 【检查】上锁
function XRiftFightLayer:CheckHasLock()
    return self:GetConfig().Order > self._OwnControl:GetMaxUnLockFightLayerId()
end

-- 【检查】是否是当前区域最后一个作战层
function XRiftFightLayer:CheckIsLastLayerInChapter()
    local allLayerList = self:GetParent():GetAllFightLayersOrderList()
    local lastLayer = allLayerList[#allLayerList]
    return lastLayer:GetFightLayerId() == self:GetFightLayerId()
end

-- 【获取】关卡节点(不包含幸运关卡节点)
function XRiftFightLayer:GetStageGroup()
    return self._OwnControl:GetStageGroup(self:GetFightLayerId())
end

-- 【获取】作战层类型
function XRiftFightLayer:GetType()
    return self:GetConfig().Type
end

function XRiftFightLayer:GetTotalStagePassTime()
    local passTime = 0
    local group = self:GetStageGroup()
    if group then
        for _, xStage in pairs(group:GetAllEntityStages()) do
            passTime = passTime + (xStage:GetPassTime() or 0)
        end
    end
    return passTime
end

function XRiftFightLayer:GetRecordPluginDrop()
    local data = self._OwnControl:GetFightLayerDataById(self:GetFightLayerId())
    return data and data.PluginDropRecords or nil
end

function XRiftFightLayer:GetRecordPluginDropChangeCount()
    local decomposeCount = 0
    local additionCount = 0
    local pluginDrop = self:GetRecordPluginDrop()
    if pluginDrop then
        for _, dropData in pairs(pluginDrop) do
            decomposeCount = decomposeCount + dropData.DecomposeCount
            additionCount = additionCount + dropData.ExtraDecomposeCount
        end
    end
    return decomposeCount, additionCount
end

-- 【保存】首次进入(跃升领奖也调用一次，功能相似)
function XRiftFightLayer:SaveFirstEnter()
    self._OwnControl:SaveFirstEnter(self:GetFightLayerId())
end

-- 【检查】是否有过首次进入
function XRiftFightLayer:CheckHadFirstEntered()
    return self._OwnControl:CheckHadFightLayerFirstEntered(self:GetFightLayerId())
end

---插件掉落概率
function XRiftFightLayer:GetPluginDrop(index)
    return self._ClientConfig.PluginDropList[index] or 0
end

-- 关卡内会刷N波怪物 玩家最终打败的波次进度
function XRiftFightLayer:GetFightProgress()
    local curWave = self:GetWave() - 1
    if curWave <= 0 then
        return 0
    end
    return curWave / self:GetAllWave()
end

function XRiftFightLayer:GetWave()
    local count = 0
    local stages = self:GetStageGroup():GetAllEntityStages()
    for _, stage in pairs(stages) do
        count = count + stage:GetStageData().Wave
    end
    return count
end

function XRiftFightLayer:GetAllWave()
    local count = 0
    local stages = self:GetStageGroup():GetAllEntityStages()
    for _, stage in pairs(stages) do
        count = count + #stage:GetConfig().MonsterWaveRandomGroupIds
    end
    return count
end

---是否有故事剧情
function XRiftFightLayer:HasStory()
    return XTool.IsNumberValid(self:GetConfig().StoryId)
end

function XRiftFightLayer:IsChallenge()
    return self:GetType() == XEnumConst.Rift.LayerType.Challenge
end

return XRiftFightLayer