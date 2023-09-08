---@class XUiPanelRiftMain3D 大秘境主界面3D面板
local XUiPanelRiftMain3D = XClass(nil, "XUiPanelRiftMain3D")
local XUiGridRiftChapter3D = require("XUi/XUiRift/Grid/XUiGridRiftChapter3D")

function XUiPanelRiftMain3D:Ctor(ui, rootui)
    self.RootUi2D = rootui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XUiGridRiftChapter3D[]
    self.GirdChapterDic = {}
    self.Drag3DDic = {}
    
    self:InitChapter()
end

function XUiPanelRiftMain3D:Refresh()
    self:RefreshRedPoint()
    self:RefreshChapterLockGameObj()
end

------------------------------------ (主界面专用)
function XUiPanelRiftMain3D:InitChapter()
    for i = 1, 6 do
        local gridChapter = self.GirdChapterDic[i]
        if not gridChapter then
            local ui2D = self.PanelChapterParent:Find("Chapter"..i)
            local objtect3D = self.PanelMapEffect:Find("PanelChapterEffect"..i)
            local chapterCam3D = self.PanelChapterCam3D:Find("UiCamNearChapter"..i)
            local chapterCam2D = self.PanelChapterCamUi:Find("UiCamChapter"..i)
            local XChapter = XDataCenter.RiftManager.GetEntityChapterById(i)
            if XChapter then
                gridChapter = XUiGridRiftChapter3D.New(self.RootUi2D, self, ui2D, objtect3D, chapterCam3D, chapterCam2D, XChapter)
                self.GirdChapterDic[i] = gridChapter
                -- 由于按钮是3D场景里的，所以拖拽区域不能放2D里，不然会覆盖住按钮。
                -- 所以将拖拽区域直接挂在3D场景里的区域按钮上，但是为了防止拖拽区域不连贯，按钮必须无缝接合且每个区域按钮都要挂载，每个拖拽区域功能必须相同
                self.Drag3DDic[i] = gridChapter.Button.gameObject:GetComponent(typeof(CS.XDragArea3D))
            end
        end
    end
end

-- 滑动相机，定位到指定的3D区域
function XUiPanelRiftMain3D:FocusTargetNodeIndex(targetIndex, duration, cb)
    local drag3D = self.Drag3DDic[1]
    drag3D:FocusTargetNodeIndex(targetIndex - 1, duration, cb)
end

function XUiPanelRiftMain3D:ImmediatelyGoToNodeIndex(targetIndex)
    local drag3D = self.Drag3DDic[1]
    drag3D:FocusTargetNodeIndex(targetIndex - 1, 0)
end

-- 设置自动吸附结束后的回调
function XUiPanelRiftMain3D:SetDragCallBack(autoSorptionCb, startDragCb)
    for _, drag3D in ipairs(self.Drag3DDic) do
        drag3D:SetAutoSorptionCallBack(function(index)
            autoSorptionCb(self.GirdChapterDic[index + 1])
        end)
        drag3D:SetBeginDragCallBack(function()
            startDragCb()
        end)
    end
end

function XUiPanelRiftMain3D:GetMaxLayer()
    return #self.Drag3DDic
end

function XUiPanelRiftMain3D:RefreshRedPoint()
    for _, gridChapter in pairs(self.GirdChapterDic) do
        gridChapter:RefreshRedPoint()
    end
end
------------------------------------ (主界面专用)

------------------------------------ (作战层选择界面专用)
function XUiPanelRiftMain3D:SetGridStageGroupData(xFightLayer) -- 传入作战层即可，会自动根据作战层找到所在区域
    local chapterId = xFightLayer.ParentChapter:GetId()
    local gridChapter = self.GirdChapterDic[chapterId]
    gridChapter:ClearStageGroup()
    gridChapter:SetGridStageGroupData(xFightLayer)
end

function XUiPanelRiftMain3D:ClearAllStageGroup() -- 清除所有区域的关卡格子信息
    for k, gridChapter in pairs(self.GirdChapterDic) do
        gridChapter:ClearStageGroup()
    end
end

function XUiPanelRiftMain3D:AutoOpenDetail(xFightLayer)
    local chapterId = xFightLayer.ParentChapter:GetId()
    local gridChapter = self.GirdChapterDic[chapterId]
    if gridChapter then
        gridChapter:AutoOpenDetail()
    end
end
------------------------------------ (作战层选择界面专用)
-- 使用当前cinemachine的摄像机视角
-- 进入区域界面后，使用该方法显示当前区域的镜头
function XUiPanelRiftMain3D:SetCameraAngleByChapterId(chapterId)
    for index, grid in pairs(self.GirdChapterDic) do -- 同一时间 只有唯一一个chapter的区域摄像机可以打开
        grid:SetCameraFocusOpen(chapterId == index)
        -- local isShowUi = (not chapterId) or (chapterId == index)
        -- grid.GameObject:SetActive(isShowUi) -- 在主界面时要显示所有ui，聚焦时只显示对应区域的ui
        -- grid.Object3D.GameObject:SetActive(isShowUi)
    end
end

function XUiPanelRiftMain3D:SetOtherGameObjectShowByChapterId(chapterId)
    for index, grid in pairs(self.GirdChapterDic) do -- 同一时间 只有唯一一个chapter的区域摄像机可以打开
        local isShowUi = (not chapterId) or (chapterId == index)
        grid.GameObject:SetActive(isShowUi) -- 在主界面时要显示所有ui，聚焦时只显示对应区域的ui
        grid.Object3D.GameObject:SetActive(isShowUi)
    end
end

-- 进出作战层界面要关闭主界面的相机拖拽功能
function XUiPanelRiftMain3D:SetDragComponentEnable(flag)
    for index, grid in pairs(self.GirdChapterDic) do -- 同一时间 只有唯一一个chapter的区域摄像机可以打开
        grid.Button.gameObject:SetActiveEx(flag)
    end
end

-- 刷新区域对应解锁时显示的物体
function XUiPanelRiftMain3D:RefreshChapterLockGameObj()
    for index, grid in pairs(self.GirdChapterDic) do -- 同一时间 只有唯一一个chapter的区域摄像机可以打开
        local xChapter = grid.XChapter
        grid.Object3D.glow02.gameObject:SetActiveEx(not xChapter:CheckHasLock())
        grid.Object3D.mountain02.gameObject:SetActiveEx(not xChapter:CheckHasLock())
    end
end

return XUiPanelRiftMain3D