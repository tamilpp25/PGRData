-- 大秘境【作战层】实例
local XRiftFightLayer = XClass(nil, "XRiftFightLayer")
local XRiftStageGroup = require("XEntity/XRift/XRiftStageGroup")

function XRiftFightLayer:Ctor(config)
    self.Config = config
    self.ClientConfig = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftLayerDetail)[config.Id]
    self.ParentChapter = nil
    self.StageGroupCount = config.NodePositions and #config.NodePositions or 0
    -- 服务端下发后确认的数据
    self.s_Passed = nil
    self.s_Lock = true
    self.s_StageGroupDic = {} -- 所有的关卡节点（最多3个）
    self.s_LuckStageGroup = nil -- + 1个幸运关卡节点(不含在all内)
    self.s_RecordPluginDrop = {} -- 记录每次作战累计的插件掉落，用于层结算
    self.s_HasJumpCount = 0 -- 该跃升进行了多少层
end

-- 向上建立关系(固定)
function XRiftFightLayer:InitRelationshipChainUp()
    self.ParentChapter = XDataCenter.RiftManager.GetEntityChapterById(self.Config.ChapterId)
    self.ParentChapter:InitRelationshipChainDown(self)
end

-- 向下建立关系
function XRiftFightLayer:InitRelationshipChainDown(stageGroupList)
    for k, StageGroupData in pairs(stageGroupList) do -- StageGroupData里面是关卡节点的Stage
        local xStageGroup = XRiftStageGroup.New(k, self)
        xStageGroup:InitRelationshipChainDown(StageGroupData.StageDatas)
        self.s_StageGroupDic[k] = xStageGroup
    end
end

-- 清除与关卡节点的关系（幸运关卡固定，不会重置数据）
function XRiftFightLayer:ClearRelationShipChainDown()
    self.s_StageGroupDic = {}
    self.s_RecordPluginDrop = {}
end

-- 【获取】Id
function XRiftFightLayer:GetId()
    return self.Config.Id
end

-- 【获取】Config
function XRiftFightLayer:GetConfig()
    return self.Config
end

-- 【获取】父区域
function XRiftFightLayer:GetParent()
    return self.ParentChapter
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
    for k, xStageGroup in pairs(self.s_StageGroupDic) do
        for k, xStage in pairs(xStageGroup:GetAllEntityStages()) do
            if xStage:CheckHasPassed() then
                curr = curr + 1
            end
            total = total + 1
        end
    end
    return curr, total
end

-- 【检查】是否解锁了，但是还没下发数据
function XRiftFightLayer:CheckNoneData()
    return XTool.IsTableEmpty(self.s_StageGroupDic)
end

-- 【检查】是否下发作战层关卡库数据，但是还没通过任意一关
function XRiftFightLayer:CheckHasStartedButNotFight()
    return not XTool.IsTableEmpty(self.s_StageGroupDic) and self:GetProgress() == 0
end

-- 【检查】是否点击了开始作战，下发数据
function XRiftFightLayer:CheckHasStarted()
    return not XTool.IsTableEmpty(self.s_StageGroupDic)
end

-- 【检查】是否首通过该作战层
function XRiftFightLayer:CheckHasPassed()
    return self.s_Passed
end

function XRiftFightLayer:SetHasPassed(value)
    self.s_Passed = value
end

-- 【检查】奖励是否已被领取
function XRiftFightLayer:CheckHadReceiveReward()
    return false
end

-- 【检查】红点(查看该层后，或者被领取跃升奖励后消失)
function XRiftFightLayer:CheckRedPoint()
    return not self:CheckHasLock() and not self:CheckHadFirstEntered()
end

-- 【检查】上锁
function XRiftFightLayer:CheckHasLock()
    return self.s_Lock
end

function XRiftFightLayer:SetHasLock(value)
    self.s_Lock = value
end

-- 【检查】是否可以扫荡
function XRiftFightLayer:CheckSweepEnable()
    -- 不为跃升，且通关
    return self:GetType() ~= XRiftConfig.LayerType.Zoom and self:CheckHasPassed()
end

-- 【检查】是否是当前区域最后一个作战层
function XRiftFightLayer:CheckIsLastLayerInChapter()
    local allLayerList = self:GetParent():GetAllFightLayersOrderList()
    local lastLayer = allLayerList[#allLayerList]
    return lastLayer:GetId() == self:GetId()
end

-- 【获取】所有关卡节点(不包含幸运关卡节点)
function XRiftFightLayer:GetAllStageGroups()
    return self.s_StageGroupDic
end

-- 【获取】幸运关卡节点
function XRiftFightLayer:GetLuckStageGroup()
    return self.s_LuckStageGroup
end

-- 【设置】幸运关卡节点
function XRiftFightLayer:SetLuckStageGroup(data)
    local xStageGroup = XRiftStageGroup.New(XRiftConfig.StageGroupLuckyPos, self)
    xStageGroup:InitRelationshipChainDown(data.StageDatas)
    self:GetParent():SetCurrLuckFightLayer(self) -- 区域缓存唯一有幸运关卡的作战层
    self.s_LuckStageGroup = xStageGroup
end

-- 【获取】气泡奖励展示列表
function XRiftFightLayer:GetShowRewardIds()
end

-- 【获取】幸运关卡奖励列表
function XRiftFightLayer:GetShowFortuneRewardIds()
end

-- 【获取】当前跃升进度（虽然这是显示在关卡详情的数据，但是该数据其实和作战层绑定，而且每层作战层只可能有一关跃升关卡）
function XRiftFightLayer:GetJumpProgress()
end

-- 【获取】作战层类型
function XRiftFightLayer:GetType()
    return self:GetConfig().Type
end

function XRiftFightLayer:GetTypeDesc()
    local textKey = "RiftLayer"
    local isIn, key = table.contains(XRiftConfig.LayerType, self:GetConfig().Type)
    if isIn then
        textKey = textKey..key
    end
    return CS.XTextManager.GetText(textKey)
end

function XRiftFightLayer:GetTotalStagePassTime()
    local passTime = 0
    for _, xStageGroup in pairs(self:GetAllStageGroups()) do
        for _, xStage in pairs(xStageGroup:GetAllEntityStages()) do
            passTime = passTime + (xStage:GetPassTime() or 0)
        end
    end
    return passTime
end

function XRiftFightLayer:SetJumpCount(count)
    -- 只有比之前的大再更新
    self.s_HasJumpCount = count > self.s_HasJumpCount and count or self.s_HasJumpCount
end

function XRiftFightLayer:GetJumpCount()
    return self.s_HasJumpCount
end

function XRiftFightLayer:AddRecordPluginDrop(value)
    self.s_RecordPluginDrop = appendArray(self.s_RecordPluginDrop , value)
end

function XRiftFightLayer:GetRecordPluginDrop()
    return self.s_RecordPluginDrop
end

-- 【保存】首次进入(跃升领奖也调用一次，功能相似)
function XRiftFightLayer:SaveFirstEnter()
    local key = "RiftFightLayer"..XPlayer.Id..self:GetId()
    XSaveTool.SaveData(key, true)
end

-- 【检查】是否有过首次进入
function XRiftFightLayer:CheckHadFirstEntered()
    local key = "RiftFightLayer"..XPlayer.Id..self:GetId()
    return XSaveTool.GetData(key)
end

function XRiftFightLayer:CheckMopupDisable()
    local res = false
    if XDataCenter.RiftManager.GetSweepLeftTimes() <= 0 then
        res = true
    end
    if not self:CheckHasPassed() then
        res = true
    end
    if self:CheckIsOwnFighting() then
        res = true
    end
    return res
end

function XRiftFightLayer:SyncData()
end

return XRiftFightLayer