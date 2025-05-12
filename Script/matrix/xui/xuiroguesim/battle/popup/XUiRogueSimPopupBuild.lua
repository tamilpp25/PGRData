local XUiGridRogueSimBuild = require("XUi/XUiRogueSim/Common/XUiGridRogueSimBuild")
---@class XUiRogueSimPopupBuild : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimPopupBuild = XLuaUiManager.Register(XLuaUi, "UiRogueSimPopupBuild")

function XUiRogueSimPopupBuild:OnAwake()
    self:RegisterUiEvents()
    self.GridBuild.gameObject:SetActiveEx(false)
    self.PanelNone.gameObject:SetActiveEx(false)
end

---@param grid XRogueSimGrid
function XUiRogueSimPopupBuild:OnStart(grid)
    self.Grid = grid
    ---@type XUiGridRogueSimBuild[]
    self.GridBuildList = {}
    ---@type XUiGridRogueSimBuild
    self.CurSelectBuildGrid = false
end

function XUiRogueSimPopupBuild:OnEnable()
    self:RefreshTitle()
    self:RefreshGrids()
    self:RefreshBuildBtn()
end

function XUiRogueSimPopupBuild:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_BUILDING_BLUEPRINT_CHANGE,
    }
end

function XUiRogueSimPopupBuild:OnNotify(event, ...)
    if event == XEventId.EVENT_ROGUE_SIM_BUILDING_BLUEPRINT_CHANGE then
        self.CurSelectBuildGrid = nil
        self:RefreshGrids()
        self:RefreshBuildBtn()
    end
end

function XUiRogueSimPopupBuild:OnDestroy()
    self.Grid = nil
    self.CurSelectBuildGrid = nil
end

-- 刷新标题
function XUiRogueSimPopupBuild:RefreshTitle()
    -- 图片
    local icon = self._Control:GetClientConfig("PopupBuildIcon")
    if icon then
        self.ImgIcon:SetSprite(icon)
    end
    -- 标题
    self.TxtTitle.text = self._Control:GetClientConfig("PopupBuildTitle")
    -- 提示
    self.TxtTips.text = self._Control:GetClientConfig("PopupBuildTips")
end

function XUiRogueSimPopupBuild:RefreshGrids()
    self.DataList = self._Control.MapSubControl:GetBuildingBluePrintIds()
    self.NewIdList = self._Control.MapSubControl:GetBuildingBluePrintNewIdList()
    if XTool.IsTableEmpty(self.DataList) then
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end
    self:SortBluePrintData()
    for index, bluePrintId in pairs(self.DataList) do
        local grid = self.GridBuildList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridBuild, self.Content)
            grid = XUiGridRogueSimBuild.New(go, self, handler(self, self.OnSelectGridClick))
            self.GridBuildList[index] = grid
        end
        grid:Open()
        grid:RefreshByBluePrintId(bluePrintId)
        grid:ShowNew(self.NewIdList[bluePrintId])
        grid:SetSelect(self.CurSelectBuildGrid and self.CurSelectBuildGrid:GetBluePrintId() == bluePrintId)
    end
    for i = #self.DataList + 1, #self.GridBuildList do
        self.GridBuildList[i]:Close()
    end
end

-- 排序建筑蓝图数据
function XUiRogueSimPopupBuild:SortBluePrintData()
    table.sort(self.DataList, function(a, b)
        local isNewA = self.NewIdList[a] and 1 or 0
        local isNewB = self.NewIdList[b] and 1 or 0
        if isNewA ~= isNewB then
            return isNewA > isNewB
        end
        return a < b
    end)
end

-- 选择建筑
---@param grid XUiGridRogueSimBuild
function XUiRogueSimPopupBuild:OnSelectGridClick(grid)
    -- 选择相同的建筑
    if self.CurSelectBuildGrid and self.CurSelectBuildGrid:GetBluePrintId() == grid:GetBluePrintId() then
        return
    end
    -- 检查金币是否充足
    if not grid:CheckBuildingGoldIsEnough() then
        return
    end
    -- 取消之前选择
    if self.CurSelectBuildGrid then
        self.CurSelectBuildGrid:SetSelect(false)
    end
    -- 选择当前
    grid:SetSelect(true)
    -- 记录当前选择
    self.CurSelectBuildGrid = grid
    self:RefreshBuildBtn()
end

-- 刷新建造按钮
function XUiRogueSimPopupBuild:RefreshBuildBtn()
    local hasData = not XTool.IsTableEmpty(self.DataList)
    self.BtnYes.gameObject:SetActiveEx(hasData)
    if hasData then
        local isSelect = self.CurSelectBuildGrid and self.CurSelectBuildGrid:GetBluePrintId() > 0
        self.BtnYes:SetDisable(not isSelect)
    end
end

function XUiRogueSimPopupBuild:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnYes, self.OnBtnYesClick)
end

-- 关闭
function XUiRogueSimPopupBuild:OnBtnCloseClick()
    self._Control:ClearGridSelectEffect()
    self._Control:CheckNeedShowNextPopup(self.Name, true)
end

-- 确认建造
function XUiRogueSimPopupBuild:OnBtnYesClick()
    -- 检查是否选择了建筑
    if not self.CurSelectBuildGrid or self.CurSelectBuildGrid:GetBluePrintId() <= 0 then
        XUiManager.TipMsg(self._Control:GetClientConfig("BuildingBluePrintNotSelectTips"))
        return
    end
    -- 检查金币是否充足
    if not self.CurSelectBuildGrid:CheckBuildingGoldIsEnough() then
        return
    end
    -- 请求建造
    local gridId = self.Grid:GetId()
    local bluePrintId = self.CurSelectBuildGrid:GetBluePrintId()
    self._Control:RogueSimBuildByBluePrintRequest(gridId, bluePrintId, function()
        self:OnBtnCloseClick()
    end)
end

return XUiRogueSimPopupBuild
