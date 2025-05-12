---@class XGridTheatre3SwitchLineNode : XUiNode
---@field ImgType
---@field TxtTitle
---@field PropGrid
---@field _Control XTheatre3Control
local XGridTheatre3SwitchLineNode = XClass(XUiNode, "XGridTheatre3SwitchLineNode")

function XGridTheatre3SwitchLineNode:OnStart()
    self:InitRewardGrid()
end

function XGridTheatre3SwitchLineNode:OnEnable()

end

function XGridTheatre3SwitchLineNode:OnDisable()

end

---@param nodeData XTheatre3Node
---@param nodeSlot XTheatre3NodeSlot
function XGridTheatre3SwitchLineNode:Refresh(nodeData, nodeSlot)
    self._NodeData = nodeData
    self._NodeSlot = nodeSlot
    
    if not self._NodeSlot then
        return
    end
    local nodeCfg
    if self._NodeSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Event) then
        nodeCfg = self._Control:GetEventNodeCfgById(self._NodeSlot:GetEventId())
    elseif self._NodeSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Fight) then
        nodeCfg = self._Control:GetFightNodeCfgById(self._NodeSlot:GetFightId())
    elseif self._NodeSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Shop) then
        nodeCfg = self._Control:GetShopNodeCfgById(self._NodeSlot:GetShopId())
    end
    if nodeCfg then
        self.TxtTitle.text = nodeCfg.NodeName
        if not string.IsNilOrEmpty(nodeCfg.NodeIcon) then
            self.ImgType:SetRawImage(nodeCfg.NodeIcon)
        end
    end

    -- 节点特效
    if self.Effect and not string.IsNilOrEmpty(nodeCfg.NodeEffectUrl) then
        local effectUrl = self._Control:GetClientConfig(nodeCfg.NodeEffectUrl, 2)
        if not string.IsNilOrEmpty(effectUrl) then
            self.Effect:LoadUiEffect(effectUrl)
        end
    end
    
    local rewardList = self._NodeSlot:GetNodeRewards()
    if XTool.IsTableEmpty(rewardList) then
        self._Reward:Close()
    else
        self._NodeReward = rewardList[1]
        self._Reward:Open()
        self:_RefreshRewardGrid()
    end
end

--region Ui - Reward
function XGridTheatre3SwitchLineNode:InitRewardGrid()
    local XUiGridTheatre3Reward = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward")
    ---@type XUiGridTheatre3Reward
    self._Reward = XUiGridTheatre3Reward.New(self.PropGrid, self)
end

function XGridTheatre3SwitchLineNode:_RefreshRewardGrid()
    local cfg = self._Control:GetRewardBoxConfig(self._NodeReward:GetType(), self._NodeReward:GetConfigId())
    self._Reward:SetNodeSlotData(cfg.Icon, cfg.Quality, function()
        self._Control:OpenAdventureTips(nil, nil, {
            Name = cfg.Name,
            Icon = cfg.Icon,
            Desc = cfg.Desc,
            WorldDesc = cfg.WorldDesc,
            Count = cfg.Count and cfg.Count or 0,
        })
    end, not self._Control:IsAdventureALine())
    self._Reward:ShowRed(false)
end
--endregion

return XGridTheatre3SwitchLineNode