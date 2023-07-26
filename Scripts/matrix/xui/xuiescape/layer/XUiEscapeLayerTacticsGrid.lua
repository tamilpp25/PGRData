---@class XUiEscapeLayerTacticsGrid
local XUiEscapeLayerTacticsGrid = XClass(nil, "XUiEscapeLayerTacticsGrid")

function XUiEscapeLayerTacticsGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)

    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
    self:InitUi()
    self:InitClickEvent()
end

function XUiEscapeLayerTacticsGrid:InitUi()
    self.Clear = XUiHelper.TryGetComponent(self.Transform, "Clear")
    self.Btn = self.Transform:GetComponent("XUiButton")
    self.CanvasGroup = self.Transform:GetComponent("CanvasGroup")
    self.Lock = XUiHelper.TryGetComponent(self.Transform, "Lock")
    self.GameObject:AddComponent(typeof(CS.UnityEngine.UI.XEmpty4Raycast))
end

function XUiEscapeLayerTacticsGrid:InitClickEvent()
    XUiHelper.RegisterClickEvent(self, self.Btn, self.OnSelectTacticsClick)
end

function XUiEscapeLayerTacticsGrid:Refresh(chapterId, layerId, tacticsNodeId)
    if not chapterId or not layerId or not tacticsNodeId then
        self:SetCanvasGroupAlpha(0)
        return
    end
    self.ChapterId = chapterId
    self.LayerId = layerId
    self.TacticsNodeId = tacticsNodeId

    --节点名
    local name = XEscapeConfigs.GetTacticsNodeName(tacticsNodeId)
    self.Btn:SetNameByGroup(0, name)
    --节点描述
    local desc = XEscapeConfigs.GetTacticsNodeDesc(tacticsNodeId)
    self.Btn:SetNameByGroup(1, desc)
    --节点展示图标
    local showIcon = XEscapeConfigs.GetTacticsNodeShowIcon(tacticsNodeId)
    if not string.IsNilOrEmpty(showIcon) then
        self.Btn:SetRawImage(showIcon)
    end

    local layerState = XDataCenter.EscapeManager.GetLayerChallengeState(chapterId, layerId)
    local isClear = self.EscapeData:IsCurChapterTacticsNodeClear(tacticsNodeId)
    self.Lock.gameObject:SetActiveEx(layerState == XEscapeConfigs.LayerState.Lock)
    self.Btn:SetDisable(not isClear and layerState == XEscapeConfigs.LayerState.Pass)
    self.Clear.gameObject:SetActiveEx(isClear)
    self:SetCanvasGroupAlpha(1)
end

function XUiEscapeLayerTacticsGrid:SetCanvasGroupAlpha(alpha)
    if not XTool.UObjIsNil(self.CanvasGroup) then
        self.CanvasGroup.alpha = alpha
    end
end

function XUiEscapeLayerTacticsGrid:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

function XUiEscapeLayerTacticsGrid:OnSelectTacticsClick()
    local chapterId = self.ChapterId
    local layerId = self.LayerId
    local tacticsNodeId = self.TacticsNodeId
    if not chapterId or not layerId or not tacticsNodeId then
        return
    end

    -- 选过tip
    local layerState, challengeConditionDesc = XDataCenter.EscapeManager.GetLayerChallengeState(chapterId, layerId)
    local isLayerSelect, isNodeSelect = self.EscapeData:IsCurChapterTacticsNodeSelect(layerId, tacticsNodeId)
    if layerState == XEscapeConfigs.LayerState.Pass then
        XUiManager.TipErrorWithKey("EscapeCurLayerClear")
        return
    end
    -- 未解锁tip
    if layerState == XEscapeConfigs.LayerState.Lock then
        XUiManager.TipError(challengeConditionDesc)
        return
    end
    -- 该层已选择策略节点且未选择策略但该节点不是被选的节点tip
    --if isLayerSelect and not isNodeSelect then
    --    XUiManager.TipErrorWithKey("EscapeCurLayerSelectTacticsNode")
    --    return
    --end
    -- 该层已选择策略节点但未选择策略
    if isLayerSelect and isNodeSelect then
        XLuaUiManager.Open("UiEscape2Tactics", chapterId, layerId, tacticsNodeId)
        return
    end
    XDataCenter.EscapeManager.RequestEscapeCheckTacticsNode(chapterId, layerId, tacticsNodeId, function()
        XLuaUiManager.Open("UiEscape2Tactics", chapterId, layerId, tacticsNodeId)
    end)
end

return XUiEscapeLayerTacticsGrid