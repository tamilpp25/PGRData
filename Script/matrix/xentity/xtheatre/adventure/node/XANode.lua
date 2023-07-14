local XANode = XClass(nil, "XANode")

function XANode:Ctor()
    self.NodeType = XTheatreConfigs.NodeType.None
    self.SlotId = nil
    -- 原始数据，用于保存服务器下发的初始事件数据
    self.RawData = nil
    -- -- TheatreNode
    -- self.NodeConfig = nil
end

--[[
    //唯一标识
    public int SlotId;

    //奖励类型，技能1，升级2，装修点3，好感度4
    public int RewardType;

    //如果奖励类型是技能，显示势力
    public int PowerId;

    //TheatreStage表ID
    public int TheatreStageId;

    //卡位类型，事件1，商店2，精英/boss3，随机关卡4
    public int SlotType;

    //事件ID，商店ID，精英/boss的关卡ID
    public int ConfigId;

    //是否已经被选择
    public int Selected;
    
    //关卡ID
    public List<int> StageIds = new List<int>();
    
    //已通关的关卡ID
    public List<int> PassedStageIds = new List<int>();
    
    //商店购买项
    public List<XTheatreNodeShopItem> ShopItems = new List<XTheatreNodeShopItem>();

    //事件的当前步骤ID
    public int CurStepId;
]]
function XANode:InitWithServerData(data)
    self.RawData = data
    self.SlotId = data.SlotId
    self.NodeType = data.SlotType
    -- self.NodeConfig = XTheatreConfigs.GetTheatreNode(data.SlotId)
end

function XANode:GetIsSelected()
    return self.RawData.Selected == 1
end

-- 获取是否已经禁用
function XANode:GetIsDisable()
    local isHasNodeSelected = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentChapter():GetIsHasNodeSelected()
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
    local currentChapter = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentChapter()
    currentChapter:RequestTriggerNode(self.SlotId, function()
        -- 设置已被选择
        self.RawData.Selected = 1
        if callback then callback() end
    end)
end

-- function XANode:GetTitle()
--     return self.NodeConfig.Title
-- end

-- function XANode:GetTitleContent()
--     return self.NodeConfig.TitleContent
-- end

-- function XANode:GetRoleIcon()
--     return self.NodeConfig.RoleIcon
-- end

-- function XANode:GetRoleName()
--     return self.NodeConfig.RoleName
-- end

-- function XANode:GetRoleContent()
--     return self.NodeConfig.RoleContent
-- end

function XANode:GetNodeTypeIcon()
    return XTheatreConfigs.GetNodeTypeIcon(self.NodeType)
end

function XANode:GetNodeTypeDesc()
    return XTheatreConfigs.GetNodeTypeDesc(self.NodeType)
end

function XANode:GetNodeTypeName()
    return XTheatreConfigs.GetNodeTypeName(self.NodeType)
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