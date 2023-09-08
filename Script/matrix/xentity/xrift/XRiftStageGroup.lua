-- 大秘境【关卡节点】实例
-- 1个关卡节点对应1个关卡库id(关卡库id由服务器随机下发)
-- 1个关卡库对应多个关卡(stage)
-- 所以可用关卡库数据生成关卡节点实例
---@class XRiftStageGroup
local XRiftStageGroup = XClass(nil, "XRiftStageGroup")
local XRiftStage = require("XEntity/XRift/XRiftStage")

function XRiftStageGroup:Ctor(index, parentFightLayer)
    ---@type XRiftStage[]
    self.AllEntityStages = {} -- 所有关卡实例
    self.NodePositionIndex = index
    -- 服务端下发后确认的数据(所有的StageGroup都必须在服务器下发数据后才能创建)
    self.s_AllStages = {} -- 所有关卡流水id
    self.s_AllMonsters = {} --不重复怪物
    self.s_AllAffixDic = {} 
    self.s_AllAffix = {} -- 不重复的词缀顺序列表
    ---@type XRiftFightLayer
    self.s_ParentFightLayer = parentFightLayer -- 建立1个向上关系，有唯一1个父节点
end

-- 向下建立关系
function XRiftStageGroup:InitRelationshipChainDown(stageData)
    self.s_AllStages = stageData
    local allConfigs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftStage)
    for k, data in ipairs(stageData) do
        -- 初始化所有拥有的配置关卡（向下单向关系：1个关卡可以重复配置在不同的关卡库）
        local xStage = XRiftStage.New(allConfigs[data.RiftStageId], k, self)

        xStage:InitRelationshipChainDown(data.MonsterDatas)
        xStage:SyncData(data)
        table.insert(self.AllEntityStages, xStage)

        -- 顺便保存所有的怪物(不重复) 这下面的代码都和建立关系无关，只是方便接口调用，暂时存数据
        local monsters = xStage:GetAllEntityMonsters()
        local dic = {}
        for k, xMonster in pairs(monsters) do
            dic[xMonster:GetId()] = xMonster
        end
        for k, xMonster in pairs(dic) do
            if not table.contains(self.s_AllMonsters, xMonster) then
                table.insert(self.s_AllMonsters, xMonster)
            end
        end
    end

    for k, xMonster in pairs(self:GetAllEntityMonsters()) do
        -- 不重复词缀
        for k, affixId in pairs(xMonster:GetAllAffixs()) do
            self.s_AllAffixDic[affixId] = affixId
        end
    end
    for affixId, v in pairs(self.s_AllAffixDic) do
        table.insert(self.s_AllAffix, affixId)
    end
end

-- 【获取】Id (id是layer表里NodePositionIndex列表对应的下标)
function XRiftStageGroup:GetId()
    return self.NodePositionIndex
end

-- 【获取】父层
---@return XRiftFightLayer
function XRiftStageGroup:GetParent()
    return self.s_ParentFightLayer
end

-- 【获取】节点名
function XRiftStageGroup:GetName()
    return self.s_ParentFightLayer:GetConfig().NodeName[self.NodePositionIndex]
end

-- 【获取】节点描述
function XRiftStageGroup:GetDesc()
    return self.s_ParentFightLayer:GetConfig().NodeDesc[self.NodePositionIndex]
end

-- 【获取】Pos
function XRiftStageGroup:GetPos()
    return self.s_ParentFightLayer:GetConfig().NodePositions[self.NodePositionIndex] or self.NodePositionIndex -- 如果父节点没配NodePositionIndex，一般是幸运节点
end

-- 【获取】关卡节点的头像
function XRiftStageGroup:GetBossHead()
    for k, xMonster in pairs(self:GetAllEntityMonsters()) do
        if XTool.IsNumberValid(xMonster.Config.IsShowMark) then
            return xMonster:GetMonsterHeadIcon()
        end
    end
end


-- 【检查】当前是否处于作战中
function XRiftStageGroup:CheckIsOwnFighting()
    local curr, total = self:GetProgress()
    return curr > 0 and curr < total
end

-- 【检查】红点
function XRiftStageGroup:CheckRedPoint()
    return false
end

-- 【检查】上锁
function XRiftStageGroup:CheckHasLock()
    if self.NodePositionIndex == 1 then
        return false -- 第一个位置没有前置
    end

    local preStageGroup = self:GetParent():GetAllStageGroups()[self.NodePositionIndex - 1]
    if preStageGroup and not preStageGroup:CheckHasPassed() then
        return true
    end

    return false
end

-- 【检查】通过该关卡节点
function XRiftStageGroup:CheckHasPassed()
    local curr, total = self:GetProgress()
    return curr >= total
end

-- 【检查】通关数/总数
function XRiftStageGroup:GetProgress()
    local curr = 0
    local total = #self.AllEntityStages
    for k, xStage in pairs(self.AllEntityStages) do
        if xStage:CheckHasPassed() then
            curr = curr + 1
        end
    end
    return curr, total
end

-- 【获取】所有关卡实例
function XRiftStageGroup:GetAllEntityStages()
    return self.AllEntityStages
end

-- 关卡节点的4种类型
function XRiftStageGroup:GetType()
    local type = nil
    --位置不为幸运位置
    if self.s_ParentFightLayer:GetType() == XRiftConfig.LayerType.Zoom then
        -- 跃升节点：如果父层是跃升层，且位置不为幸运位置则是
        type = XRiftConfig.StageGroupType.Zoom
    elseif self.s_ParentFightLayer:GetType() == XRiftConfig.LayerType.Normal and #self.AllEntityStages == 1 then
        -- 普通节点：父层是普通层，且配置的StageId数为1
        type = XRiftConfig.StageGroupType.Normal
    elseif self.s_ParentFightLayer:GetType() == XRiftConfig.LayerType.Multi and #self.AllEntityStages > 1 then
        -- 多队伍节点：父层是普通层，且配置的StageId数为1
        type = XRiftConfig.StageGroupType.Multi
    end
    return type
end

function XRiftStageGroup:GetAllEntityMonsters()
    return self.s_AllMonsters
end

-- 【获取】关卡节点的所有词缀，对应词缀库表id
function XRiftStageGroup:GetAllAffixs()
    return self.s_AllAffix, self.s_AllAffixDic
end

function XRiftStageGroup:SyncData()
end

return XRiftStageGroup