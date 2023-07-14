local XUiRogueLikeFightTips = XLuaUiManager.Register(XLuaUi, "UiRogueLikeFightTips")

local XUiRogueLikeFightEntrance = require("XUi/XUiFubenRogueLike/XUiRogueLikeFightEntrance")
local XUiRogueLikeStoryEntrance = require("XUi/XUiFubenRogueLike/XUiRogueLikeStoryEntrance")
local XUiRogueLikeRestEntrance = require("XUi/XUiFubenRogueLike/XUiRogueLikeRestEntrance")
local XUiRogueLikeShopEntrance = require("XUi/XUiFubenRogueLike/XUiRogueLikeShopEntrance")
local XUiRogueLikeBoxEntrance = require("XUi/XUiFubenRogueLike/XUiRogueLikeBoxEntrance")

-- 重新计算位置间隔
local FRAME_GAP = 10


function XUiRogueLikeFightTips:OnAwake()

    self.EntranceFight = XUiRogueLikeFightEntrance.New(self.PanelEnterFight, self)
    self.EntranceStory = XUiRogueLikeStoryEntrance.New(self.PanelStory, self)
    self.EntranceRest = XUiRogueLikeRestEntrance.New(self.PanelRest, self)
    self.EntranceShop = XUiRogueLikeShopEntrance.New(self.PanelShop, self)
    self.EntranceBox = XUiRogueLikeBoxEntrance.New(self.PanelBaoxiang, self)

    self.BtnCloseMask.CallBack = function() self:OnBtnCloseMask() end

    local behaviour = self.GameObject:GetComponent(typeof(CS.XLuaBehaviour))
    if not behaviour then
        behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    end
    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end
end

function XUiRogueLikeFightTips:Update()

    if self.FrameCount % FRAME_GAP ~= 0 then return end

    local nodePosition = self.GetNodePosition and self.GetNodePosition() or CS.UnityEngine.Vector3.zero
    if XFubenRogueLikeConfig.XRLNodeType.Fight == self.NodeType then
        self.EntranceFight.Transform.position = nodePosition
    end

    if XFubenRogueLikeConfig.XRLNodeType.Event == self.NodeType then
        self.EntranceStory.Transform.position = nodePosition
    end

    if XFubenRogueLikeConfig.XRLNodeType.Rest == self.NodeType then
        self.EntranceRest.Transform.position = nodePosition
    end

    if XFubenRogueLikeConfig.XRLNodeType.Shop == self.NodeType then
        self.EntranceShop.Transform.position = nodePosition
    end

    if XFubenRogueLikeConfig.XRLNodeType.Box == self.NodeType then
        self.EntranceBox.Transform.position = nodePosition
    end
end

function XUiRogueLikeFightTips:OnStart(args, get_node_position)
    self.Args = args
    self.GetNodePosition = get_node_position
    self.FrameCount = 0
    self.NodeInfo = self.Args.NodeInfo
    local nodeId = self.NodeInfo.NodeId
    self.NodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(nodeId)
    self.NodeType = self.NodeTemplate.Type

    local isStoryType = XFubenRogueLikeConfig.XRLNodeType.Event == self.NodeType
    if isStoryType then
        local sectionInfo = XDataCenter.FubenRogueLikeManager.GetCurSectionInfo()
        local selectionNode = sectionInfo.SelectNodeInfo[nodeId]
        local eventTemplate = XFubenRogueLikeConfig.GetEventTemplateById(selectionNode.EventId)
        if eventTemplate.Type == XFubenRogueLikeConfig.XRLEventType.Other then
            self.NodeType = XFubenRogueLikeConfig.XRLNodeType.Event
        else
            local selectNodeInfo = sectionInfo.SelectNodeInfo[nodeId]
            local targetNodeId = selectNodeInfo.Value
            self.EventNodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(targetNodeId)
            self.NodeType = self.EventNodeTemplate.Type
        end
    end

    self:ShowFightEntrance()
    self:ShowRestEntrance()
    self:ShowShopEntrance()
    self:ShowBoxEntrance()
    self:ShowStoryEntrance()
end

function XUiRogueLikeFightTips:OnEnable()
    XDataCenter.FubenRogueLikeManager.CheckRogueLikeDayResetOnUi("UiRogueLikeFightTips")
end

function XUiRogueLikeFightTips:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_NODE_ADJUSTION)
end

function XUiRogueLikeFightTips:ShowFightEntrance()
    local isFightType = XFubenRogueLikeConfig.XRLNodeType.Fight == self.NodeType
    self.EntranceFight.GameObject:SetActiveEx(isFightType)
    if isFightType then
        self.EntranceFight:UpdateByNode(self.NodeTemplate, self.EventNodeTemplate, self.NodeInfo.Index)
        self:PlaySaftyAnimation("PanelEnterFightEnable")

    end
end

function XUiRogueLikeFightTips:ShowStoryEntrance()
    local isStoryType = XFubenRogueLikeConfig.XRLNodeType.Event == self.NodeType
    self.EntranceStory.GameObject:SetActiveEx(isStoryType)
    if isStoryType then
        self.EntranceStory:UpdateByNode(self.NodeTemplate)
        self:PlaySaftyAnimation("PanelStoryEnable")

    end
end

function XUiRogueLikeFightTips:ShowRestEntrance()
    local isRestType = XFubenRogueLikeConfig.XRLNodeType.Rest == self.NodeType
    self.EntranceRest.GameObject:SetActiveEx(isRestType)
    if isRestType then
        self.EntranceRest:UpdateByNode(self.NodeTemplate, self.EventNodeTemplate)
        self:PlaySaftyAnimation("PanelRestEnable")

    end
end

function XUiRogueLikeFightTips:ShowShopEntrance()
    local isShopType = XFubenRogueLikeConfig.XRLNodeType.Shop == self.NodeType
    self.EntranceShop.GameObject:SetActiveEx(isShopType)
    if isShopType then
        self.EntranceShop:UpdateByNode(self.NodeTemplate, self.EventNodeTemplate)
        self:PlaySaftyAnimation("PanelShopEnable")

    end
end

function XUiRogueLikeFightTips:ShowBoxEntrance()
    local isBoxType = XFubenRogueLikeConfig.XRLNodeType.Box == self.NodeType
    self.EntranceBox.GameObject:SetActiveEx(isBoxType)
    if isBoxType then
        self.EntranceBox:UpdateByNode(self.NodeTemplate, self.EventNodeTemplate)
        self:PlaySaftyAnimation("PanelBaoxiangEnable")
    end
end

function XUiRogueLikeFightTips:OnBtnCloseMask()
    self:Close()
end

function XUiRogueLikeFightTips:PlaySaftyAnimation(animName, endCb, startCb)
    self:PlayAnimation(animName, function()
        if endCb then
            endCb()
        end
        XLuaUiManager.SetMask(false)
    end,
    function()
        if startCb then
            startCb()
        end
        XLuaUiManager.SetMask(true)
    end)
end

function XUiRogueLikeFightTips:OnDestroy()

end