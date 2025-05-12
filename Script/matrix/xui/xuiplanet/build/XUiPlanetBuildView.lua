local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPlanetBuildGridView
local XUiPlanetBuildGridView = XClass(nil, "XUiPlanetBuildGridView")

function XUiPlanetBuildGridView:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPlanetBuildGridView:Refresh(buildId, count)
    local icon = XPlanetWorldConfigs.GetBuildingIconUrl(buildId)
    local name = XPlanetTalentConfigs.GetTalentBuildingName(buildId)
    local eventIdList = XPlanetTalentConfigs.GetTalentBuildingEventList(buildId)
    if not string.IsNilOrEmpty(icon) then
        self.RImgIcon:SetRawImage(icon)
    end
    self.TxtTitle.text = name
    self.TxtBuff2.text = "x" .. count

    if XTool.IsNumberValid(eventIdList[1]) then
        self.TxtTitle02.text = XPlanetStageConfigs.GetEventDesc(eventIdList[1])
    end
    if XTool.IsNumberValid(eventIdList[2]) then
        self.TxtTitle03.text = XPlanetStageConfigs.GetEventDesc(eventIdList[2])
    end

    self.TxtTitle02.gameObject:SetActiveEx(XTool.IsNumberValid(eventIdList[1]))
    self.TxtTitle03.gameObject:SetActiveEx(XTool.IsNumberValid(eventIdList[2]))
end

--===============================================================================================

local XUiPlanetBuildView = XLuaUiManager.Register(XLuaUi, "UiPlanetBuildView")

function XUiPlanetBuildView:OnAwake()
    self.PlanetViewModel = XDataCenter.PlanetManager.GetViewModel()
    self.PlanetMainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    self:InitDynamicTable()
    self:AddBtnClickListener()
end

function XUiPlanetBuildView:OnStart()
    
end

function XUiPlanetBuildView:OnEnable()
    self:UpdateDynamicTable()
end

function XUiPlanetBuildView:OnDisable()
end

--region 数据列表
function XUiPlanetBuildView:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewList)
    self.DynamicTable:SetProxy(XUiPlanetBuildGridView, self)
    self.DynamicTable:SetDelegate(self)
    self.GridNewbieTaskItem.gameObject:SetActiveEx(false)
end

function XUiPlanetBuildView:UpdateDynamicTable()
    self.BuildIdList = self.PlanetViewModel:GetReformCurHaveBuildList()
    self.DynamicTable:SetDataSource(self.BuildIdList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPlanetBuildView:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local buildId = self.BuildIdList[index]
        grid:Refresh(buildId, self.PlanetMainScene:GetBuildingCount(buildId))
    end
end
--endregion


--region 按钮绑定
function XUiPlanetBuildView:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end
--endregion