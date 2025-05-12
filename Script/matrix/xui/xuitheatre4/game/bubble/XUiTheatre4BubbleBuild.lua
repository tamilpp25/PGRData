local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre4BubbleBuild = require("XUi/XUiTheatre4/Game/Bubble/XUiGridTheatre4BubbleBuild")
---@class XUiTheatre4BubbleBuild : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4BubbleBuild = XLuaUiManager.Register(XLuaUi, "UiTheatre4BubbleBuild")

function XUiTheatre4BubbleBuild:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

---@param isClick boolean 是否接受点击
function XUiTheatre4BubbleBuild:OnStart(position, sizeDelta, isClick)
    self:SetPosition(position, sizeDelta)
    self.IsClick = isClick
    self.TxtAddNum.gameObject:SetActiveEx(false)
    self.GridBuild.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

-- 设置坐标
function XUiTheatre4BubbleBuild:SetPosition(position, sizeDelta)
    XScheduleManager.ScheduleOnce(function()
        -- 世界坐标转Ui坐标
        local localPosition = self.Transform:InverseTransformPoint(position)
        localPosition.x = localPosition.x - sizeDelta.x / 2
        localPosition.y = localPosition.y + sizeDelta.y / 2 + self.PanelBuild.sizeDelta.y / 2
        self.PanelBuild.localPosition = localPosition
    end, 1) --异形屏适配需要延迟一帧
end

function XUiTheatre4BubbleBuild:OnEnable()
    self:RefreshBuildPoint()
    self:RefreshAddEnergy()
    self:SetupDynamicTable()
end

-- 刷新建筑点信息
function XUiTheatre4BubbleBuild:RefreshBuildPoint()
    -- 建造点图片
    local bpIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.BuildPoint)
    if bpIcon then
        self.RImgEnergy:SetRawImage(bpIcon)
    end
    -- 建造点数量
    self.TxtNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.BuildPoint)
end

-- 刷新每回合开始时增加的建造点
function XUiTheatre4BubbleBuild:RefreshAddEnergy()
    local addEnergy = self._Control.AssetSubControl:GetTotalRecoverEnergy()
    local formatAddText = self._Control:GetClientConfig("BuildPointDailyAdd", 1) or ""

    self.TxtAddNum.gameObject:SetActiveEx(addEnergy > 0)
    if addEnergy > 0 then
        self.TxtAddNum.text = XUiHelper.FormatText(formatAddText, addEnergy)
    end
end

function XUiTheatre4BubbleBuild:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBuildList)
    self.DynamicTable:SetProxy(XUiGridTheatre4BubbleBuild, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTheatre4BubbleBuild:SetupDynamicTable()
    self.DataList = self._Control.MapSubControl:GetBuildingTalentIds()
    if XTool.IsTableEmpty(self.DataList) then
        return
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridTheatre4BubbleBuild
function XUiTheatre4BubbleBuild:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayGridAnimation()
    end
end

function XUiTheatre4BubbleBuild:OnBtnCloseClick()
    self:Close()
end

function XUiTheatre4BubbleBuild:PlayGridAnimation()
    ---@type XUiGridTheatre4BubbleBuild[]
    local grids = self.DynamicTable:GetGrids()
    if XTool.IsTableEmpty(grids) then
        return
    end
    RunAsyn(function()
        for _, grid in pairs(grids) do
            if grid then
                asynWaitSecond(0.05)
                grid:PlayBuildInAnimation()
            end
        end
    end)
end

return XUiTheatre4BubbleBuild
