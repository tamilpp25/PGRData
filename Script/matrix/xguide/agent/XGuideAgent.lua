--弹框位置类型
local InfoPosType = {
    --左上
    TopLeft     = 0,
    --右上
    TopRight    = 1,
    --自定义
    Custom      = 2
}

local CsVector2 = CS.UnityEngine.Vector2

---@class XGuideAgent : XLuaBehaviorAgent
---@field UiGuide XUiGuideNew
local XGuideAgent = XLuaBehaviorManager.RegisterAgent(XLuaBehaviorAgent, "Guide")

function XGuideAgent:OnAwake()
    self.UiGuide = nil
end

--获取Ui
function XGuideAgent:GetUi(uiName)
    local isUiShow = CsXUiManager.Instance:IsUiShow(uiName)
    if not isUiShow then
        XLog.Error(uiName .. " is not showing")
        return
    end

    local ui = CsXUiManager.Instance:FindTopUi(uiName)
    if not ui then
        XLog.Error(uiName .. " is not on Top")
        return
    end

    local proxy = ui.UiProxy.UiLuaTable
    return proxy
end

--获取UiGuide
---@return XUiGuideNew
function XGuideAgent:GetUiGuide()
    if self.UiGuide and self.UiGuide.Transform and self.UiGuide.Transform:Exist() then
        return self.UiGuide
    end

    local isUiGuideShow = CsXUiManager.Instance:IsUiShow("UiGuide")
    if not isUiGuideShow then
        XLuaUiManager.Open("UiGuide")
    end

    local uiGuide = CsXUiManager.Instance:FindTopUi("UiGuide")
    local proxy = nil
    if uiGuide then
        proxy = uiGuide.UiProxy.UiLuaTable
    end

    self.UiGuide = proxy

    return proxy
end


--UI是否显示中
function XGuideAgent:IsUiShowAndOnTop(uiName, needOnTop)
    local isUiShow = CsXUiManager.Instance:IsUiShow(uiName)
    if not isUiShow then
        return false
    end

    if not needOnTop then
        return true
    end

    local ui = CsXUiManager.Instance:FindTopUi(uiName)
    if not ui then
        return false
    end

    return true
end

---显示对话头像
function XGuideAgent:ShowDialog(image, name, content, pos, uiName, gridName, position)
    local uiGuide = self:GetUiGuide()
    local anchorMax, anchorMin, anchorPosition
    if pos == InfoPosType.TopLeft then
        anchorMax = CsVector2(0, 1)
        anchorMin = CsVector2(0, 1)
        anchorPosition = CS.UnityEngine.Vector2(500, -380)
    elseif pos == InfoPosType.Custom then
        local target = self:FindTransformInUi(uiName, gridName)
        anchorMax = target.anchorMax
        anchorMin = target.anchorMin
        anchorPosition = position
    else
        anchorMax = CsVector2(1, 1)
        anchorMin = CsVector2(1, 1)
        anchorPosition = CsVector2(-500, -380)
    end
    uiGuide:ShowDialog(image, name, content, anchorMax, anchorMin, anchorPosition)
end

---隐藏对话头像
function XGuideAgent:HideDialog()
    local uiGuide = self:GetUiGuide()
    uiGuide:HideDialog()
end

---显示遮罩
function XGuideAgent:ShowMask(isShowMask, isBlockRaycast)
    local uiGuide = self:GetUiGuide()
    uiGuide:ShowMark(isShowMask, isBlockRaycast)
end


---显示遮罩新
function XGuideAgent:ShowMaskNew(isShowMask, isBlockRaycast)
    local uiGuide = self:GetUiGuide()
    uiGuide:ShowMarkNew(isShowMask, isBlockRaycast)
end

--ui是否显示中
function XGuideAgent:IsUiActive(uiName, panel)
    local target = self:FindTransformInUi(uiName, panel)

    if not target then
        return false
    end

    return target.gameObject.activeSelf
end

--聚焦UI
function XGuideAgent:FocusOn(uiName, panel, eulerAngles, passEvent, sizeDelta, offset)
    local target = self:FindActiveTransformInUi(uiName, panel)
    local uiGuide = self:GetUiGuide()
    uiGuide:FocusOnPanel(target, eulerAngles, passEvent, sizeDelta, offset)
end

function XGuideAgent:FocusOn3D(sceneRoot, camera, panel, eulerAngles, passEvent, offset, sizeDelta)
    local root = self:FindSceneRoot(sceneRoot)
    local cam = self:FindSceneCamera(root, camera)
    local tar = self:FindSceneTransform(root, panel)
    local uiGuide = self:GetUiGuide()
    uiGuide:FocusOn3DPanel(cam, tar, offset, eulerAngles, passEvent, sizeDelta)
end

--索引动态列表
function XGuideAgent:IndexDynamicTable(uiName, dynamicName, indexKey, indexValue, focusTransform, passEvent, sizeDelta, offset, passAll)
    local target = self:FindTransformInUi(uiName, dynamicName)

    local dynamicTable = target:GetComponent(typeof(CS.XDynamicTableNormal))
    if not dynamicTable then
        XLog.Error(string.format("DynamicTable is null uiName:%s dynamicName:%s", uiName, dynamicName))
        return
    end


    local gridIndex = dynamicTable.LuaTableDelegate:GuideGetDynamicTableIndex(indexKey, indexValue)
    dynamicTable:ReloadDataSync(gridIndex)
    if gridIndex == -1 then
        XLog.Error("找不到该动态节点,请检查ID参数是否正确 KEY:" .. tostring(indexKey) .. " ID:" .. tostring(indexValue))
        return nil
    end

    local grid = dynamicTable:GetGridByIndex(gridIndex)
    if not grid then
        XLog.Error("找不到该动态节点,请检查ID参数是否正确 KEY:" .. tostring(indexKey) .. " ID:" .. tostring(indexValue) .. " Index:" .. tostring(gridIndex))
        return nil
    end

    if focusTransform == nil or focusTransform == "" or focusTransform == "@" then
        self.UiGuide:FocusOnPanel(grid.transform, nil, passEvent, sizeDelta, offset, passAll)
    else
        local tmpTarget = grid.transform:FindTransformWithSplit(focusTransform)
        self.UiGuide:FocusOnPanel(tmpTarget, nil, passEvent, sizeDelta, offset, passAll)
    end
end

--索引Curve动态列表 1.（索引指示）列表Grid点击 → 2.（指引卡住流程）开始索引 → 3.（不会执行）播放动画列表滚动结束 → 4.（下一个指引出现）
function XGuideAgent:IndexCurveDynamicTable(uiName, dynamicName, indexKey, indexValue, focusTransform, passEvent, sizeDelta, offset, passAll)
    local target = self:FindTransformInUi(uiName, dynamicName)

    local dynamicTable = target:GetComponent(typeof(CS.XDynamicTableCurve))
    if not dynamicTable then
        XLog.Error(string.format("DynamicTable is null uiName:%s dynamicName:%s", uiName, dynamicName))
        return
    end
    
    local gridIndex = dynamicTable.LuaTableDelegate:GuideGetDynamicTableIndex(indexKey, indexValue)

    if dynamicTable.LuaTableDelegate.ChapterGuide then
        dynamicTable.LuaTableDelegate.Delegate.CurrentSelectedIndex = gridIndex
    end

    if dynamicTable.LuaTableDelegate.Delegate.GuideCallback then
        XDataCenter.GuideManager.SetGridNextCb(dynamicTable.LuaTableDelegate.Delegate.GuideCallback, dynamicTable.LuaTableDelegate.Delegate)
    end
    dynamicTable:ReloadData(gridIndex)
    if gridIndex == -1 then
        XLog.Error("找不到该动态节点,请检查ID参数是否正确 KEY:" .. tostring(indexKey) .. " ID:" .. tostring(indexValue))
        return nil
    end

    local grid = dynamicTable:GetGridByIndex(gridIndex)
    if not grid then
        XLog.Error("找不到该动态节点,请检查ID参数是否正确 KEY:" .. tostring(indexKey) .. " ID:" .. tostring(indexValue) .. " Index:" .. tostring(gridIndex))
        return nil
    end

    if focusTransform == nil or focusTransform == "" or focusTransform == "@" then
        self.UiGuide:FocusOnPanel(grid.transform, nil, passEvent, sizeDelta, offset, passAll)
    else
        local tmpTarget = grid.transform:FindTransformWithSplit(focusTransform)
        self.UiGuide:FocusOnPanel(tmpTarget, nil, passEvent, sizeDelta, offset, passAll)
    end
end

--索引3d固定动态列表
function XGuideAgent:Index3DFixedDynamicTable(sceneRoot, camera, dynamicName, indexKey, indexValue, passEvent, sizeDelta, offset)
    local root = self:FindSceneRoot(sceneRoot)
    local cam = self:FindSceneCamera(root, camera)
    local target = self:FindSceneTransform(root, dynamicName)

    local dynamicTableCs = target:GetComponent(typeof(CS.XDynamicTableFixed3D))
    if not dynamicTableCs then
        XLog.Error(string.format("XDynamicTableFixed3D is null uiName:%s dynamicName:%s", dynamicName))
        return
    end

    local dynamicTableLua = dynamicTableCs.LuaTableDelegate
    local gridIndex = dynamicTableLua:GuideGetDynamicTableIndex(indexKey, indexValue)
    local csIndex = gridIndex - 1
    dynamicTableLua:FocusIndex(csIndex, -1)
    if gridIndex == -1 then
        XLog.Error("找不到该动态节点,请检查ID参数是否正确 KEY:" .. tostring(indexKey) .. " ID:" .. tostring(indexValue))
        return nil
    end

    -- local grid = dynamicTableLua:GetGridByIndex(gridIndex)
    local gridGo = dynamicTableCs.UsingGridsList[csIndex]
    if not gridGo then
        XLog.Error("找不到该动态节点,请检查ID参数是否正确 KEY:" .. tostring(indexKey) .. " ID:" .. tostring(indexValue) .. " Index:" .. tostring(gridIndex))
        return nil
    end

    local targetTransform = gridGo.transform
    if XTool.UObjIsNil(targetTransform) then
        targetTransform = dynamicTableCs.transform
    end

    local uiGuide = self:GetUiGuide()
    offset = offset or CS.UnityEngine.Vector3.zero
    uiGuide:FocusOn3DPanel(cam, targetTransform, offset, nil, passEvent, sizeDelta)
end

function XGuideAgent:FindTargetFilter(uiName, filterName)
    local target = self:FindTransformInUi(uiName, filterName)
    return target
end

--寻找Ui
function XGuideAgent:FindTransformInUi(uiName, panel)
    local ui = self:GetUi(uiName)
    if ui == nil then
        XLog.Error("错误!!引导未能找到 Ui:" .. uiName .. " 请检查引导流程")
        return
    end

    local target = ui.Transform:FindTransformWithSplit(panel)
    if not target then
        XLog.Error(uiName .. " 未能找到该节点：" .. panel)
        return
    end

    return target
end

--获取未隐藏的Target
function XGuideAgent:FindActiveTransformInUi(uiName, panel)
    local ui = self:GetUi(uiName)
    if ui == nil then
        XLog.Error("错误!!引导未能找到 Ui:" .. uiName .. " 请检查引导流程")
        return
    end
    
    local target = ui.Transform:FindActiveTransformWithSplit(panel)
    if not target then
        XLog.Error(uiName .. " 未能找到该节点：" .. panel)
        return
    end
    
    return target
end

function XGuideAgent:FindSceneRoot(rootPath)
    local root = CS.UnityEngine.GameObject.Find(rootPath)
    if XTool.UObjIsNil(root) then
        XLog.Error("错误，未能找到场景根节点：" .. rootPath)
        return
    end
    return root
end

function XGuideAgent:FindSceneCamera(root, camera)
    if not root then
        XLog.Error("错误，场景根节点不存在" )
        return
    end
    local cam = root.transform:Find(camera)
    if XTool.UObjIsNil(cam) then
        XLog.Error("错误，未能找到场景相机：" .. camera)
        return
    end
    
    local component = cam.gameObject:GetComponent("Camera")
    if XTool.UObjIsNil(component) then
        XLog.Error("错误，节点上未能找到相机组件:" .. camera)
        return
    end
    return component
end

function XGuideAgent:FindSceneTransform(root, panel)
    if not root then
        XLog.Error("错误，场景根节点不存在" )
        return
    end
    local target = root.transform:Find(panel)
    if XTool.UObjIsNil(target) then
        XLog.Error("错误，未能找到场景节点：" .. panel)
        return
    end
    return target
end

--跳转关卡
function XGuideAgent:FubenJumpToStage(stageId)

    local uiFubenMainLineChapter = CsXUiManager.Instance:FindTopUi("UiFubenMainLineChapter")
    local proxy = nil
    if uiFubenMainLineChapter then
        proxy = uiFubenMainLineChapter.UiProxy.UiLuaTable
    end

    if proxy then
        proxy:GoToStage(stageId)
    end

end

--ScrollRect滑动到节点
function XGuideAgent:FocuOnScrollRect(uiName, scroll, target)

    local targetScroll = self:FindTransformInUi(uiName, scroll)

    local scrollRect = targetScroll:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    if not scrollRect then
        XLog.Error(string.format("scrollRect 不存在 uiName:%s dynamicName:%s", uiName, scroll))
        return false
    end


    local targetTrans = self:FindTransformInUi(uiName, target)

    if not targetTrans then
        XLog.Error(string.format("节点不存在 uiName:%s dynamicName:%s", uiName, target))
        return false
    end

    CS.XUiHelper.ScrollItemToView(targetScroll, scrollRect.viewport, scrollRect.content, targetTrans, nil)

    return true

end

function XGuideAgent:CheckAnimIsPlaying(uiName, animName)
    local target = self:FindTransformInUi(uiName, animName)
    if not target then
        return false
    end
    local component = target.transform:GetComponent("XUiPlayAnimatorAnimation")
    if not component then
        component = target.transform:GetComponent("XUiPlayTimelineAnimation")
    end
    if not component then
        return false
    end
    return component.IsPlaying
end

-- 节点记录埋点
function XGuideAgent:NodeBuryingPoint(nodeId)
    XDataCenter.GuideManager.RecordBuryingPoint(XDataCenter.GuideManager.BuryingPointType.FocusOn, { nodeId })
end
