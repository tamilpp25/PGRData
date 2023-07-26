local XANode = XClass(nil, "XANode")

function XANode:Ctor()
    self.NodeType = XBiancaTheatreConfigs.NodeType.None
    self.SlotId = nil
    -- 原始数据，用于保存服务器下发的初始事件数据
    self.RawData = nil
    -- -- TheatreNode
    -- self.NodeConfig = nil
end

--[[
    //唯一标识
    public int SlotId;

    //卡位类型，XBiancaTheatreNodeSlotType
    public int SlotType;

    //是否已经被选择
    public int Selected;


    //==============战斗节点==============
    //BiancaTheatreFightNode的ID
    public int FightId;

    //BiancaTheatreFightStageTemplate的ID
    public int FightTemplateId;

    //节点随机奖励, 只是作为展示用
    public List<XBiancaTheatreNodeReward> NodeRewards = new List<XBiancaTheatreNodeReward>();
    
    //已通关的关卡ID
    public List<int> PassedStageIds = new List<int>();

    //================事件节点===============
    public int EventId;

    //事件的当前步骤ID
    public int CurStepId;

    //已经完成的事件步骤
    public List<int> PassedStepId = new List<int>();
    
    //BiancaTheatreFightNode的ID
    //public int FightId;
    
    //事件里会有战斗，战斗读取FightStageTemplate表ID
    //public int FightTemplateId;

    //================商店节点===============
    public int ShopId;

    public List<XBiancaTheatreNodeShopItem> ShopItems = new List<XBiancaTheatreNodeShopItem>();
]]
function XANode:InitWithServerData(data)
    self.RawData = data
    self.SlotId = data.SlotId
    self.NodeType = data.SlotType
    -- self.NodeConfig = XBiancaTheatreConfigs.GetTheatreNode(data.SlotId)
end

function XANode:SetCurStepId(stepId)
    self.RawData.CurStepId = stepId
end

function XANode:GetCurStepId()
    return self.RawData.CurStepId
end

function XANode:GetEventId()
    return self.RawData.EventId
end

function XANode:SetFightTemplateId(fightTemplateId)
    self.RawData.FightTemplateId = fightTemplateId
end

function XANode:GetFightStageId()
    return XBiancaTheatreConfigs.GetTheatreFightStageId(self.RawData.FightTemplateId)
end

function XANode:GetIsSelected()
    return self.RawData.Selected == 1
end

-- 获取是否已经禁用
function XANode:GetIsDisable()
    local isHasNodeSelected = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter():GetIsHasNodeSelected()
    return isHasNodeSelected and not self:GetIsSelected()
end

-- 获取节点类型
function XANode:GetNodeType()
    return self.NodeType
end

function XANode:Trigger(callback)
    if self:GetIsSelected() then
        if callback then callback() end
        return
    end
    -- 触发节点
    local currentChapter = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter()
    currentChapter:RequestTriggerNode(self.SlotId, function()
        -- 设置已被选择
        self.RawData.Selected = 1
        if callback then callback() end
    end)
end

function XANode:GetNodeTypeIcon()
    return XBiancaTheatreConfigs.GetNodeTypeIcon(self.NodeType)
end

function XANode:GetNodeTypeSmallIcon()
    return XBiancaTheatreConfigs.GetTheatreClientConfig("NodeTypeSmallIcon").Values[self.NodeType]
end

function XANode:GetNodeTypeDesc()
    return XBiancaTheatreConfigs.GetNodeTypeDesc(self.NodeType)
end

function XANode:GetNodeTypeName()
    return XBiancaTheatreConfigs.GetNodeTypeName(self.NodeType)
end

function XANode:GetNodeTypeEffectUrl()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeEffectUrl then
        return self.EventClientConfig.NodeTypeEffectUrl
    end
end

function XANode:GetShowDatas()
    return {}
end

function XANode:GetIsBattle()
    return false
end

function XANode:GetBgAsset()
    
end

function XANode:GetIsTriggerWithDirect()
    return false
end


return XANode