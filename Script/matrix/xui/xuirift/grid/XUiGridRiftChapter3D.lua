local XUiGridRiftChapter3D = XClass(nil, "XUiGridRiftChapter3D")
local XUiGridRiftStageGroup3D = require("XUi/XUiRift/Grid/XUiGridRiftStageGroup3D") -- 进入区域后的关卡节点格子，对应关卡节点

---@class XUiGridRiftChapter3D
function XUiGridRiftChapter3D:Ctor(rootUi, rootPanel3D, ui, object3D, camera2D, camera3D, xChapter)
    self.RootUi2D = rootUi
    self.RootPanel3D = rootPanel3D
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Camera2D = camera2D
    self.Camera3D = camera3D
    XTool.InitUiObject(self)
    self.Object3D = {}
    XTool.InitUiObjectByUi(self.Object3D, object3D) -- 将3d的内容都加进来
    self.XChapter = xChapter
    ---@type XUiGridRiftStageGroup3D[]
    self.GridStageGroupDic = {}
    self.GridOutliersList = {}
    
    self.Button.CallBack = function () self:OnGridClick() end
    self:InitGridStageGroup()
end

---------------在【主界面】时调用的方法
--region
function XUiGridRiftChapter3D:RefreshRedPoint()
    local isRed = self.XChapter:CheckRedPoint()
    self.Button:ShowReddot(isRed)
end

function XUiGridRiftChapter3D:OnGridClick()
    self.RootUi2D:OnChapterSelected(self)
end
--endregion
---------------在【主界面】时调用的方法

---------------在【区域界面】时调用的方法
--region
function XUiGridRiftChapter3D:ClearStageGroup()
    for k, gridStageGroup in pairs(self.GridStageGroupDic) do
        gridStageGroup:ClearData()
    end
end

-- 先初始化各个关卡节点
function XUiGridRiftChapter3D:InitGridStageGroup()
    for i = 1, 5 do -- 每层5个预留的关卡节对象
        local uiParent2D = self["StageGroup"..i]
        local uiParent3D = self.Object3D["PanelGuanqia"..i]
        local stageGroupTemplate2D = self.RootPanel3D.PanelChapterParent:Find("UiRiftGuanqia")
        local stageGroupTemplate3D = i == 5 and self.RootPanel3D.PanelMapEffect:Find("RiftGuanqiaBig") or self.RootPanel3D.PanelMapEffect:Find("RiftGuanqia")
        local object2D = CS.UnityEngine.Object.Instantiate(stageGroupTemplate2D, uiParent2D)
        local object3D = CS.UnityEngine.Object.Instantiate(stageGroupTemplate3D, uiParent3D)
        local camera2D = self.RootPanel3D.PanelStageCam3D:Find("PanelGuanqiaCamNearStage".. self.XChapter:GetId().."/UiCamNearGuanqia"..self.XChapter:GetId()..i)
        local camera3D = self.RootPanel3D.PanelStageCamUi:Find("PanelCamGuanqiaStage".. self.XChapter:GetId().."/UiCamGuanqia"..self.XChapter:GetId()..i)
        local gridStageGroup = XUiGridRiftStageGroup3D.New(object2D, object3D, self.RootUi2D, self, camera2D, camera3D)
        self.GridStageGroupDic[i] = gridStageGroup
    end
    self:ClearStageGroup()
end

-- 加载本区域当前选择的作战层关卡库数据 (v2.0 一层只有一个节点)
---@param xFightLayer XRiftFightLayer
function XUiGridRiftChapter3D:SetGridStageGroupData(xFightLayer)
    local nodePosition = xFightLayer:GetConfig().NodePositions[1]
    self.CurStage = self.GridStageGroupDic[nodePosition]
    self.CurStage:UpdateData(xFightLayer:GetId())
end

function XUiGridRiftChapter3D:OnStageGroupClickToFocusCamera(clickGrid)
    if not clickGrid then
        for k, grid in pairs(self.GridStageGroupDic) do
            grid:SetCameraFocusStageGroup(false)
        end
        return
    end
    clickGrid:SetCameraFocusStageGroup(true)
end

-- 摄像机聚焦到该层
function XUiGridRiftChapter3D:SetCameraFocusOpen(flag)
    self.IsCurrFocusOnChapter = flag
    self.Camera2D.gameObject:SetActiveEx(flag)
    self.Camera3D.gameObject:SetActiveEx(flag)
    self.bg2.gameObject:SetActiveEx(flag)
    self.bg3.gameObject:SetActiveEx(flag)
    self.bg4.gameObject:SetActiveEx(flag)
    self.Object3D.FxUiRiftXiJie1.gameObject:SetActiveEx(flag)
    self.Object3D.FxUiRiftAnDi3.gameObject:SetActiveEx(flag)
end

function XUiGridRiftChapter3D:AutoOpenDetail()
    if self.CurStage then
        self.CurStage:OnBtnDetailClick()
    end
end

--endregion
---------------在【区域界面】时调用的方法
function XUiGridRiftChapter3D:OnDestroy()
end

return XUiGridRiftChapter3D