local XBasePoint = XClass(nil, "XBasePoint")

local DefualtNil = 0

function XBasePoint:Ctor(root, ui)
    self.Root = root
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    if self.PanelMe then
        self.PanelMe.gameObject:SetActiveEx(false)
    end
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(false)
    end
    if self.BtnStage then
        XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnClick)
    end
end

-- 数据相关
--========================================================================

function XBasePoint:SetPointId(pointId)
    self._PointId = pointId
end

function XBasePoint:GetPointId()
    return self._PointId
end

-- 获取该点位在地图位置
function XBasePoint:GetPositionId()
    if not XTool.IsNumberValid(self._PointId) then
        return DefualtNil
    end
    return XColorTableConfigs.GetPointPositionId(self._PointId)
end

-- 获取该点位颜色，剧情点和隐藏Boss点默认无色
function XBasePoint:GetColorType()
    if not XTool.IsNumberValid(self._PointId) then
        return DefualtNil
    end
    return XColorTableConfigs.GetPointColor(self._PointId)
end

-- 获取该点位类型
function XBasePoint:GetType()
    if not XTool.IsNumberValid(self._PointId) then
        return DefualtNil
    end
    return XColorTableConfigs.GetPointType(self._PointId)
end

function XBasePoint:GetPointParams()
    if not XTool.IsNumberValid(self._PointId) then
        return
    end
    return XColorTableConfigs.GetPointParams(self._PointId)
end

-- 获取该点位名称
function XBasePoint:GetName()
    if not XTool.IsNumberValid(self._PointId) then
        return
    end
    return XColorTableConfigs.GetPointName(self._PointId)
end

function XBasePoint:GetIcon()
    if not XTool.IsNumberValid(self._PointId) then
        return
    end
    return XColorTableConfigs.GetPointIcon(self._PointId)
end

function XBasePoint:GetTipIcon()
    if not XTool.IsNumberValid(self._PointId) then
        return
    end
    return XColorTableConfigs.GetPointTipIcon(self._PointId)
end

-- 获取该点位描述
function XBasePoint:GetPointDesc()
    if not XTool.IsNumberValid(self._PointId) then
        return
    end
    return XColorTableConfigs.GetPointPointDesc(self._PointId)
end

-- 获取该点位效果描述
function XBasePoint:GetEffectDesc()
    if not XTool.IsNumberValid(self._PointId) then
        return
    end
    return XColorTableConfigs.GetPointEffectDesc(self._PointId)
end

-- 是否是地图行动点
function XBasePoint:IsMapPoint()
    return false
end

-- 是否是剧情点
function XBasePoint:IsMoviePoint()
    return false
end

function XBasePoint:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

--========================================================================



-- 点位操作
--========================================================================

-- 执行该点位行动
function XBasePoint:Excute()
end

function XBasePoint:RefreshSelectState(active)
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(active)
    end
end

-- 打开提示弹窗
function XBasePoint:SetTipPanelActive(active)
end

function XBasePoint:OnBtnClick()
    if self.Root then
        self.Root:SelectPoint(self)
    end
end

--========================================================================

return XBasePoint