---@class XUiGridTheatre4Building : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4Building = XClass(XUiNode, "XUiGridTheatre4Building")

function XUiGridTheatre4Building:OnStart(callback)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self.Red.gameObject:SetActiveEx(false)
    self.Callback = callback
end

---@param buildingData { Id:number, Icon:string, Count:number }
function XUiGridTheatre4Building:Refresh(buildingData)
    if not buildingData then
        return
    end
    self.BuildingId = buildingData.Id or 0
    self.BuildingIcon = buildingData.Icon or ""
    self.BuildingCount = buildingData.Count or 0
    self:RefreshBuilding()
end

function XUiGridTheatre4Building:RefreshBuilding()
    -- 图标
    local icon
    if XTool.IsNumberValid(self.BuildingId) then
        icon = self._Control:GetBuildingIcon(self.BuildingId)
    else
        icon = self.BuildingIcon
    end
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
    -- 数量
    self.TxtNum.transform.parent.gameObject:SetActiveEx(self.BuildingCount > 0)
    self.TxtNum.text = string.format("×%s", self.BuildingCount)
end

-- 红点
function XUiGridTheatre4Building:ShowRedDot(isShow)
    self.Red.gameObject:SetActiveEx(isShow)
end

function XUiGridTheatre4Building:OnBtnClick()
    if self.Callback then
        self.Callback(self)
    end
end

return XUiGridTheatre4Building
