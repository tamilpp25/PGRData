local XUiGridRogueSimBuild = require("XUi/XUiRogueSim/Common/XUiGridRogueSimBuild")
---@class XUiRogueSimPopupCity : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimPopupCity = XLuaUiManager.Register(XLuaUi, "UiRogueSimPopupCity")

function XUiRogueSimPopupCity:OnAwake()
    self.PanelMain.gameObject:SetActiveEx(false)
    self.PanelCity.gameObject:SetActiveEx(false)
    self.GridBuild.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

---@param grid XRogueSimGrid
function XUiRogueSimPopupCity:OnStart(grid)
    self.Grid = grid
    -- 当前选择的建筑蓝图id
    self.CurSelectBluePrintId = 0
end

function XUiRogueSimPopupCity:OnEnable()
    if self.Grid:GetLandType() == XEnumConst.RogueSim.LandformType.Main then
        self:OpenPanelMain()
    elseif self.Grid:GetLandType() == XEnumConst.RogueSim.LandformType.City then
        self:OpenPanelCity()
    end
end

function XUiRogueSimPopupCity:OnDestroy()
    self.Grid = nil
end

-- 打开主城详情界面
function XUiRogueSimPopupCity:OpenPanelMain()
    if not self.UiPanelMainDetail then
        ---@type XUiGridRogueSimMainDetail
        self.UiPanelMainDetail = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimMainDetail").New(self.PanelMain, self)
    end
    self.UiPanelMainDetail:Open()
    self.UiPanelMainDetail:Refresh()
end

-- 打开城邦详情界面
function XUiRogueSimPopupCity:OpenPanelCity()
    if not self.UiPanelCityDetail then
        ---@type XUiGridRogueSimCityDetail
        self.UiPanelCityDetail = require("XUi/XUiRogueSim/Battle/Grid/XUiGridRogueSimCityDetail").New(self.PanelCity, self)
    end
    self.UiPanelCityDetail:Open()
    self.UiPanelCityDetail:Refresh(self.Grid:GetId())
end

-- 打开建筑详情界面
---@param bluePrintId number 建筑蓝图Id
function XUiRogueSimPopupCity:OpenPanelBuild(bluePrintId)
    if not self.UiPanelBuildDetail then
        ---@type XUiGridRogueSimBuild
        self.UiPanelBuildDetail = XUiGridRogueSimBuild.New(self.GridBuild, self)
    end
    self.UiPanelBuildDetail:Open()
    self.UiPanelBuildDetail:RefreshByBluePrintId(bluePrintId)
end

-- 关闭建筑详情界面
function XUiRogueSimPopupCity:ClosePanelBuild()
    if self.UiPanelBuildDetail then
        self.UiPanelBuildDetail:Close()
    end
    self.CurSelectBluePrintId = 0
end

-- 点击选择建筑蓝图
---@param bluePrintId number 建筑蓝图Id
function XUiRogueSimPopupCity:OnSelectBuildClick(bluePrintId)
    if self.CurSelectBluePrintId == bluePrintId then
        self:ClosePanelBuild()
        return
    end
    self.CurSelectBluePrintId = bluePrintId
    self:OpenPanelBuild(bluePrintId)
end

function XUiRogueSimPopupCity:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick, nil, true)
end

function XUiRogueSimPopupCity:OnBtnCloseClick()
    if self.CurSelectBluePrintId > 0 then
        self:ClosePanelBuild()
        return
    end
    self:OnCloseCity()
end

-- 关闭界面
function XUiRogueSimPopupCity:OnCloseCity()
    self._Control:ClearGridSelectEffect()
    self._Control:CheckNeedShowNextPopup(self.Name, true)
end

function XUiRogueSimPopupCity:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiRogueSimPopupCity
