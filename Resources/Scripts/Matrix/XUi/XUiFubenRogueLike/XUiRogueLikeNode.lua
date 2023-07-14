local XUiRogueLikeNode = XClass(nil, "XUiRogueLikeNode")
local half_alpha = 0.3
local full_alpha = 1

function XUiRogueLikeNode:Ctor(ui, uiParent, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.UiParent = uiParent
    self.Transform.localPosition = CS.UnityEngine.Vector3.zero

    XTool.InitUiObject(self)
    self.BtnNode = self.Transform:GetComponent("XUiButton")
    self.BtnNode.CallBack = function() self:PlaySelectNodeAnimation() end
    self.LineList = {}
    self.LineCanvasGroupList = {}
end

-- Finish节点
-- 记下历史节点
-- 上次选中的节点
function XUiRogueLikeNode:UpdateNode(nodeInfo)
    self.NodeInfo = nodeInfo
    self.NodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(self.NodeInfo.NodeId)
    self.NodeConfig = XFubenRogueLikeConfig.GetNodeConfigteById(self.NodeInfo.NodeId)
    local sectionInfo = XDataCenter.FubenRogueLikeManager.GetCurSectionInfo()

    -- 自己已经完成
    self.PanelComplete.gameObject:SetActiveEx(sectionInfo.FinishNode[self.NodeInfo.NodeId])
    if sectionInfo.FinishNode[self.NodeInfo.NodeId] then
        self.BtnNode:SetButtonState(XUiButtonState.Normal)
        self.NodeUsable = true
    else
        self.BtnNode:SetButtonState(XUiButtonState.Disable)
        self.NodeUsable = false
    end
    -- 父节点已经完成
    for i = 1, #self.NodeInfo.FatherNodes do
        local fatherNodeId = self.NodeInfo.FatherNodes[i]
        if sectionInfo.FinishNode[fatherNodeId] then
            self.BtnNode:SetButtonState(XUiButtonState.Normal)
            self.NodeUsable = true
            break
        end
    end
    -- 首节点
    if #self.NodeInfo.FatherNodes <= 0 then
        self.BtnNode:SetButtonState(XUiButtonState.Normal)
        self.NodeUsable = true
    end
    -- 同级节点判断，如果有同级节点完成/不可逆节点选中
    local tierDatas = XFubenRogueLikeConfig.GetGroup2TierMapDatas(self.NodeInfo.Group, self.NodeInfo.TierIndex)
    local hasSameTier = false

    
    for _, v in pairs(tierDatas and tierDatas.Nodes or {}) do
        
        if v ~= self.NodeInfo.NodeId then
            if sectionInfo.FinishNode[v] then
                hasSameTier = true
            end
            
            if sectionInfo.SelectNodeInfo[v] then
                -- 类型是随机事件、商店需要处理
                local selectNodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(v)
                if selectNodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Shop or
                selectNodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Event or 
                selectNodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Rest then
                    hasSameTier = true
                end
            end
        end
    end

    if hasSameTier then
        self.BtnNode:SetButtonState(XUiButtonState.Disable)
        self.NodeUsable = false
    end

    -- 特效
    if self.PanelEffect then
        self.PanelEffect.gameObject:SetActiveEx(self.NodeUsable and (not sectionInfo.FinishNode[self.NodeInfo.NodeId]))
    end

    self:UpdateNodeTab()

    -- 界面显示
    self:UpdateNodeUi()

    self:UpdateNodeLines()
end

function XUiRogueLikeNode:UpdateNodeTab()
    if self.ImgTab and self.NodeTemplate then
        local sectionInfo = XDataCenter.FubenRogueLikeManager.GetCurSectionInfo()
        self.ImgTab.gameObject:SetActiveEx(self.NodeUsable and (not sectionInfo.FinishNode[self.NodeInfo.NodeId])
        and self.NodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Fight
        and XDataCenter.FubenRogueLikeManager.CanSwitch2Assist())
    end
end

function XUiRogueLikeNode:UpdateNodeUi()
    -- 界面显示
    if self.NodeTemplate.Type ~= XFubenRogueLikeConfig.XRLNodeType.Fight then
        self.RogueLikeTabNor:SetRawImage(XFubenRogueLikeConfig.NodeTabBg[self.NodeTemplate.Type])
    else
        local fightType = self.NodeConfig.Param[1] or 0
        self.RogueLikeTabNor:SetRawImage(XFubenRogueLikeConfig.NodeFightTabBg[fightType])
    end

    self.TxtNumber.text = self.NodeConfig.Name

    if not self.NodeUsable then
        if self.NodeTemplate.Type ~= XFubenRogueLikeConfig.XRLNodeType.Fight then
            self.RogueLikeTabDis:SetRawImage(XFubenRogueLikeConfig.NodeTabDisBg[self.NodeTemplate.Type], function()
                self.RogueLikeTabDis:SetNativeSize()
            end)
        else
            local fightType = self.NodeConfig.Param[1] or 0
            self.RogueLikeTabDis:SetRawImage(XFubenRogueLikeConfig.NodeFightTabDisBg[fightType], function()
                self.RogueLikeTabDis:SetNativeSize()
            end)
        end
    end
end

function XUiRogueLikeNode:HideAllLines()
    for _, line in pairs(self.LineList or {}) do
        if line then
            line.gameObject:SetActiveEx(false)
        end
    end
end

function XUiRogueLikeNode:HideTargetLines(targetNodeId)
    if not self.NodeInfo then return end
    local curNdoeIndex = self.UiRoot:GetNodeIndex(self.NodeInfo.NodeId)
    local targetNodeIndex = self.UiRoot:GetNodeIndex(targetNodeId)
    local cur2TargetLine = string.format("Line%d_%d", curNdoeIndex, targetNodeIndex)
    if self.LineList[cur2TargetLine] then
        self.LineList[cur2TargetLine].gameObject:SetActiveEx(false)
    end
end


function XUiRogueLikeNode:UpdateNodeLines()
    local childNodes = self.UiRoot:GetChildNode(self.NodeInfo.NodeId)
    local curNdoeIndex = self.UiRoot:GetNodeIndex(self.NodeInfo.NodeId)
    for childNodeId, _ in pairs(childNodes or {}) do
        -- 缓存
        local childNodeIndex = self.UiRoot:GetNodeIndex(childNodeId)
        local cur2ChildLine = string.format("Line%d_%d", curNdoeIndex, childNodeIndex)
        if not self.LineList[cur2ChildLine] then
            self.LineList[cur2ChildLine] = self.UiParent:Find(cur2ChildLine)
            if self.LineList[cur2ChildLine] then
                self.LineCanvasGroupList[cur2ChildLine] = self.LineList[cur2ChildLine]:GetComponent("CanvasGroup")
                if not self.LineCanvasGroupList[cur2ChildLine] then
                    XLog.Error(string.format("%s 不存在", cur2ChildLine))
                end
                self.LineCanvasGroupList[cur2ChildLine].interactable = false
                self.LineCanvasGroupList[cur2ChildLine].blocksRaycasts = false
            end
        end
        -- 默认，当前节点还没有完成，全部子节点低透明度显示
        if self.LineList[cur2ChildLine] then
            self.LineCanvasGroupList[cur2ChildLine].alpha = half_alpha
            self.LineCanvasGroupList[cur2ChildLine].gameObject:SetActiveEx(true)
        end
    end
    local sectionInfo = XDataCenter.FubenRogueLikeManager.GetCurSectionInfo()
    -- 看子节点、如果有子节点完成，那么只有一条线高透明度显示，如果没有子节点完成，则全部显示
    if sectionInfo.FinishNode[self.NodeInfo.NodeId] then
        local hasChildFinishOrSelected = false
        local finishOrSelectedChildNodeId = 0
        for childNodeId, _ in pairs(childNodes or {}) do
            local hasSelect = false
            local selectNodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(childNodeId)
            if sectionInfo.SelectNodeInfo[childNodeId] and
            (selectNodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Shop or
            selectNodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Event or 
            selectNodeTemplate.Type == XFubenRogueLikeConfig.XRLNodeType.Rest ) then
                hasSelect = true
            end
            if sectionInfo.FinishNode[childNodeId] or hasSelect then
                hasChildFinishOrSelected = true
                finishOrSelectedChildNodeId = childNodeId
                break
            end
        end
        if hasChildFinishOrSelected and finishOrSelectedChildNodeId > 0 then
            for childNodeId, _ in pairs(childNodes or {}) do
                local childNodeIndex = self.UiRoot:GetNodeIndex(childNodeId)
                local cur2ChildLine = string.format("Line%d_%d", curNdoeIndex, childNodeIndex)
                if self.LineCanvasGroupList[cur2ChildLine] then
                    if childNodeId == finishOrSelectedChildNodeId then
                        self.LineCanvasGroupList[cur2ChildLine].alpha = full_alpha
                        -- self.LineCanvasGroupList[cur2ChildLine].gameObject:SetActiveEx(true)
                    else
                        self.LineCanvasGroupList[cur2ChildLine].alpha = half_alpha
                        -- self.LineCanvasGroupList[cur2ChildLine].gameObject:SetActiveEx(false)
                    end
                end
            end
        else
            for childNodeId, _ in pairs(childNodes or {}) do
                local childNodeIndex = self.UiRoot:GetNodeIndex(childNodeId)
                local cur2ChildLine = string.format("Line%d_%d", curNdoeIndex, childNodeIndex)
                if self.LineCanvasGroupList[cur2ChildLine] then
                    self.LineCanvasGroupList[cur2ChildLine].alpha = full_alpha
                    -- self.LineCanvasGroupList[cur2ChildLine].gameObject:SetActiveEx(true)
                end
            end
        end
    end
end

function XUiRogueLikeNode:PlaySelectNodeAnimation()
    if self.UiRoot:OpenSetTeamView() then
        return
    end
    local sectionInfo = XDataCenter.FubenRogueLikeManager.GetCurSectionInfo()
    if sectionInfo.FinishNode[self.NodeInfo.NodeId] then
        XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeCurrentNodeFinish"))
        return
    end
   
    if not self.NodeUsable then
        return
    end

    if not self:CheckActionPointEnouth() and false then
        XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeNotActionPoint"))
        return
    end

    self.UiRoot:SelectNodeAnimation(self.Transform, function()
        self:OnBtnNodeClick()
    end)
end

function XUiRogueLikeNode:CheckActionPointEnouth()

    if XFubenRogueLikeConfig.NoNeedCheckActionPointType(self.NodeTemplate.Type) then
        return true
    end

    local actionPoint = XDataCenter.FubenRogueLikeManager.GetRogueLikeActionPoint()
    return actionPoint > 0 
    
end

function XUiRogueLikeNode:OnBtnNodeClick()

    if not XDataCenter.FubenRogueLikeManager.IsInActivity() then
        XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
        return
    end

    local args = {}
    args.NodeInfo = self.NodeInfo
    local sectionInfo = XDataCenter.FubenRogueLikeManager.GetCurSectionInfo()
    local hasSelectNode = sectionInfo.SelectNodeInfo[self.NodeInfo.NodeId] ~= nil
    hasSelectNode = hasSelectNode or (XDataCenter.FubenRogueLikeManager.GetShowSelectNodeById(self.NodeInfo.NodeId) ~= nil)
    local getNodePositionFunc = function() return self:GetNodePosition() end
    if hasSelectNode or XFubenRogueLikeConfig.IsRequestBeforeSelectType(self.NodeTemplate.Type) then
        XLuaUiManager.Open("UiRogueLikeFightTips", args, getNodePositionFunc)
    else
        XDataCenter.FubenRogueLikeManager.SelectNode(self.NodeInfo.NodeId, function()
            -- 选择节点成功打开界面
            XLuaUiManager.Open("UiRogueLikeFightTips", args, getNodePositionFunc)
        end)
    end
end

function XUiRogueLikeNode:GetNodePosition()
    return self.Transform.position
end

return XUiRogueLikeNode