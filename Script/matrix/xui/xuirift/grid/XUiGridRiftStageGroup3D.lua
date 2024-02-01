-- 大秘境关卡节点3D格子
---@class XUiGridRiftStageGroup3D
local XUiGridRiftStageGroup3D = XClass(nil, "XUiGridRiftStageGroup3D")

local State = 
{
    ---上锁
    Lock = 1,
    ---作战中
    Fighting = 2,
    ---通过
    Passed = 3,
    ---已解锁 还没打
    UnLockProgress0 = 4,
}

function XUiGridRiftStageGroup3D:Ctor(ui, object3D, rootUi, rootChapter3D, camera2D, camera3D)
    ---@type XUiRiftMain
    self.RootUi2D = rootUi
    self.RootChapter3D = rootChapter3D
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Camera2D = camera2D
    self.Camera3D = camera3D
    XTool.InitUiObject(self)
    self.Object3D = {}
    XTool.InitUiObjectByUi(self.Object3D, object3D) -- 将3d的内容加进这
    self.AffixsGridDic = {}

    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OpenDetail)
end

function XUiGridRiftStageGroup3D:SetState(state)
    self.Object3D.Normal.gameObject:SetActiveEx(true)
    self.Object3D.Lock.gameObject:SetActiveEx(false)
    self.Object3D.Ing.gameObject:SetActiveEx(false)
    self.Object3D.Finish.gameObject:SetActiveEx(false)
    if state == State.Lock then                     -- 1.上锁
        self.Object3D.Lock.gameObject:SetActiveEx(true)
    elseif state == State.Fighting then             -- 2.作战中
        self.Object3D.Ing.gameObject:SetActiveEx(true)
    elseif state == State.Passed then               -- 3.通过
        self.Object3D.Normal.gameObject:SetActiveEx(false)
        self.Object3D.Lock.gameObject:SetActiveEx(true)
        self.Object3D.Finish.gameObject:SetActiveEx(true) 
    elseif state == State.UnLockProgress0 then      -- 4.已解锁 还没打

    end

    self.GameObject:SetActiveEx(true)
    self.Object3D.GameObject:SetActiveEx(true)
    self.TxtFinish.gameObject:SetActiveEx(state == State.Passed)
end

function XUiGridRiftStageGroup3D:UpdateData(layerId)
    self.LayerId = layerId
    self.TxtNormalLayerNum.text = string.format("%skm", layerId)
    if XDataCenter.RiftManager.IsLayerLock(layerId) then
        self:SetState(State.Lock)  -- 1.上锁
    elseif XDataCenter.RiftManager.IsLayerPass(layerId) then
        self:SetState(State.Passed) -- 3.通过
    elseif XDataCenter.RiftManager.IsCurrPlayingLayer(layerId) then
        self:SetState(State.Fighting) -- 2.作战中
    else
        self:SetState(State.UnLockProgress0) -- 4.已解锁 还没打
    end
end

function XUiGridRiftStageGroup3D:ClearData()
    -- 清空数据。设为空数据状态
    self.GameObject:SetActiveEx(false)
    self.Object3D.GameObject:SetActiveEx(false)
end

-- 摄像机聚焦到关卡节点
function XUiGridRiftStageGroup3D:SetCameraFocusStageGroup(flag)
    if not self.RootChapter3D.IsCurrFocusOnChapter then -- 当前chapter没有打开的话 返回
        return
    end

    self.Camera2D.gameObject:SetActiveEx(flag)
    self.Camera3D.gameObject:SetActiveEx(flag)
    self.Object3D.Select.gameObject:SetActiveEx(flag)
    if flag then
        self.RootUi2D.ChildUi.Transform:Find("Animation/UiDisable"):PlayTimelineAnimation(function ()
            self.RootUi2D.ChildUi.PanelSelectControl.gameObject:SetActiveEx(false)
        end)
    else
        self.RootUi2D.ChildUi.PanelSelectControl.gameObject:SetActiveEx(true)
        self.RootUi2D.ChildUi.Transform:Find("Animation/UiEnable"):PlayTimelineAnimation(function ()
            self.RootUi2D.ChildUi.PanelSelectControl.gameObject:GetComponent("CanvasGroup").alpha = 1
        end)
    end
end

function XUiGridRiftStageGroup3D:OpenDetail()
    self.RootUi2D.ChildUi:OnShowDetail()
end

function XUiGridRiftStageGroup3D:OnBtnDetailClick()
    local _, layer = XDataCenter.RiftManager.GetCurrPlayingChapter()
    local stageGroup = layer:GetStage()
    if not stageGroup then
        return
    end

    if stageGroup:CheckHasLock() then
        XUiManager.TipError(CS.XTextManager.GetText("RiftNodeEnterPreLock"))
        return
    end

    -- 根据当前作战层类型，打开不同的详情界面
    local targetUiName = "UiRiftNormalStageDetail"
    self.RootChapter3D:OnStageGroupClickToFocusCamera(self) -- 点击时打开关卡节点摄像头
    if stageGroup:GetType() == XRiftConfig.StageGroupType.Normal then
        targetUiName = "UiRiftNormalStageDetail"
    elseif stageGroup:GetType() == XRiftConfig.StageGroupType.Zoom then
        if stageGroup:GetParent():IsSeasonLayer() then
            targetUiName = "UiRiftSeasonStageDetail"
        else
            targetUiName = "UiRiftZoomStageDetail"
        end
    elseif stageGroup:GetType() == XRiftConfig.StageGroupType.Multi then
        targetUiName = "UiRiftMultiStageDetail"
    end
    XDataCenter.RiftManager.SetCurrSelectRiftStage(stageGroup)
    XLuaUiManager.Open(targetUiName, self.LayerId, handler(self, self.OnStageGroupClickToFocusCamera))
end

---关闭详情界面时，关闭关卡节点摄像头
function XUiGridRiftStageGroup3D:OnStageGroupClickToFocusCamera()
    self.RootChapter3D:OnStageGroupClickToFocusCamera(nil)
end

return XUiGridRiftStageGroup3D