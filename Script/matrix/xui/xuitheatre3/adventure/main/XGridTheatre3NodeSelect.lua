local XUiGridTheatre3Reward = require("XUi/XUiTheatre3/Adventure/Prop/XUiGridTheatre3Reward")

---@class XGridTheatre3NodeSelect : XUiNode
---@field _Control XTheatre3Control
local XGridTheatre3NodeSelect = XClass(XUiNode, "XGridTheatre3NodeSelect")

function XGridTheatre3NodeSelect:OnStart()
    self:InitRewardGrid()
    self:AddBtnListener()
end

function XGridTheatre3NodeSelect:OnEnable()
    self:AddEventListener()
end

function XGridTheatre3NodeSelect:OnDisable()
    self:RemoveEventListener()
end

--region Ui - Refresh
---@param nodeData XTheatre3Node
---@param nodeSlot XTheatre3NodeSlot
function XGridTheatre3NodeSelect:Refresh(nodeData, nodeSlot)
    self._NodeData = nodeData
    self._NodeSlot = nodeSlot
    self:_RefreshCanSelect()
    self:_RefreshNode()
end

function XGridTheatre3NodeSelect:_RefreshCanSelect()
    -- 刷新后节点不处于选择状态
    self:_RefreshSelect(false)
    -- 选择节点后状态固定
    if self._NodeData:CheckIsSelect() then
        if not self._NodeSlot:CheckIsSelected() then
            self.GridStage:SetButtonState(CS.UiButtonState.Disable)
        else
            self.GridStage:SetButtonState(CS.UiButtonState.Select)
        end
    end
end

function XGridTheatre3NodeSelect:_RefreshNode()
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
        self.TxtTiTLE.text = nodeCfg.NodeName
        self.TxtDescribe.text = XUiHelper.ConvertLineBreakSymbol(nodeCfg.NodeDesc)
        if not string.IsNilOrEmpty(nodeCfg.NodeIcon) then
            self.ImgType:SetRawImage(nodeCfg.NodeIcon)
        end
        if not string.IsNilOrEmpty(nodeCfg.NodeBg) then
            self.ImgBg:SetRawImage(nodeCfg.NodeBg)
        end
        -- 节点特效
        if self.Effect and not string.IsNilOrEmpty(nodeCfg.NodeEffectUrl) then
            self.Effect:LoadUiEffect(nodeCfg.NodeEffectUrl)
        end
    end
    local rewardList = self._NodeSlot:GetNodeRewards()
    if XTool.IsTableEmpty(rewardList) then
        if self.Bg3 then
            self.Bg3.gameObject:SetActiveEx(false)
        end
        self._Reward:Close()
    else
        self._NodeReward = rewardList[1]
        self:_RefreshRewardGrid()
    end
end

function XGridTheatre3NodeSelect:SetIsSelect(nodeSlot)
    -- 已选择了其他的节点
    if self._NodeData:CheckIsSelect() then
        if self._NodeSlot:CheckIsSelected() then
            self:_RefreshSelect(self._NodeSlot:CheckIsSelected())
        else
            self.GridStage:SetButtonState(CS.UiButtonState.Disable)
        end
        return
    end
    self:_RefreshSelect(nodeSlot == self._NodeSlot)
end

function XGridTheatre3NodeSelect:_RefreshSelect(isSelect)
    if isSelect then
        self.GridStage:SetButtonState(CS.UiButtonState.Select)
    else
        self.GridStage:SetButtonState(CS.UiButtonState.Normal)
    end
end
--endregion

--region Ui - Reward
function XGridTheatre3NodeSelect:InitRewardGrid()
    if not self.Bg3 then
        ---@type UnityEngine.RectTransform
        self.Bg3 = XUiHelper.TryGetComponent(self.Transform, "PanelStage/Bg/Bg (3)")
    end
    ---@type XUiGridTheatre3Reward
    self._Reward = XUiGridTheatre3Reward.New(self.Grid128, self)
end

function XGridTheatre3NodeSelect:_RefreshRewardGrid()
    local cfg = self._Control:GetRewardBoxConfig(self._NodeReward:GetType(), self._NodeReward:GetConfigId())
    self._Reward:SetNodeSlotData(cfg.Icon, cfg.Quality, function()
        XLuaUiManager.Open("UiTheatre3Tips", nil, nil, {
            Name = cfg.Name,
            Icon = cfg.Icon,
            Desc = cfg.Desc,
            WorldDesc = cfg.WorldDesc,
            Count = cfg.Count and cfg.Count or 0,
        })
    end)
    self._Reward:ShowRed(false)
end
--endregion

--region Ui - BtnListener
function XGridTheatre3NodeSelect:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.GridStage, self.OnBtnCharacterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
end

function XGridTheatre3NodeSelect:OnBtnCharacterClick()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_ADVENTURE_MAIN_CHOOSE_NODE, self._NodeSlot)
end

function XGridTheatre3NodeSelect:OnBtnYesClick()
    if self._NodeSlot:CheckIsSelected() then
        -- 战斗不Pop
        self._Control:CheckAndOpenAdventureNodeSlot(self._NodeSlot, not self._NodeSlot:CheckIsFight())
        return
    end
    self._Control:RequestAdventureSelectNode(self._NodeData, self._NodeSlot, function()
        self._Control:CheckAndOpenAdventureNodeSlot(self._NodeSlot, not self._NodeSlot:CheckIsFight())
    end)
end
--endregion

--region Event
function XGridTheatre3NodeSelect:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_MAIN_CHOOSE_NODE, self.SetIsSelect, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_MAIN_SELECT_NODE, self._RefreshCanSelect, self)
end

function XGridTheatre3NodeSelect:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_MAIN_CHOOSE_NODE, self.SetIsSelect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_MAIN_SELECT_NODE, self._RefreshCanSelect, self)
end
--endregion

return XGridTheatre3NodeSelect