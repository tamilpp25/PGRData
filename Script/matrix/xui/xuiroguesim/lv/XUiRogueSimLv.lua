---@class XUiRogueSimLv : XLuaUi
---@field private _Control XRogueSimControl
---@field private AssetPanel XUiPanelRogueSimAsset
local XUiRogueSimLv = XLuaUiManager.Register(XLuaUi, "UiRogueSimLv")

function XUiRogueSimLv:OnAwake()
    self:RegisterUiEvents()
    self.GridLv.gameObject:SetActiveEx(false)
end

function XUiRogueSimLv:OnStart()
    -- 显示资源
    self.AssetPanel = require("XUi/XUiRogueSim/Common/XUiPanelRogueSimAsset").New(
        self.PanelAsset,
        self,
        XEnumConst.RogueSim.ResourceId.Gold)
    self.AssetPanel:Open()
    -- 初始化动态列表
    self:InitDynamicTable()
end

function XUiRogueSimLv:OnEnable()
    self:OpenLvUp()
    self:SetupDynamicTable()
end

function XUiRogueSimLv:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP,
    }
end

function XUiRogueSimLv:OnNotify(event, ...)
    if event == XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP then
        self:RefreshLvUp()
        self:SetupDynamicTable()
    end
end

function XUiRogueSimLv:OpenLvUp()
    if not self.LvUp then
        ---@type XUiPanelRogueSimLvUp
        self.LvUp = require("XUi/XUiRogueSim/Lv/XUiPanelRogueSimLvUp").New(self.PanelLvUp, self)
    end
    self.LvUp:Open()
    self.LvUp:Refresh()
end

function XUiRogueSimLv:RefreshLvUp()
    if self.LvUp and self.LvUp:IsNodeShow() then
        self.LvUp:Refresh(true)
    end
end

function XUiRogueSimLv:InitDynamicTable()
    local XUiGridRogueSimLv = require("XUi/XUiRogueSim/Lv/XUiGridRogueSimLv")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelLv)
    self.DynamicTable:SetProxy(XUiGridRogueSimLv, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRogueSimLv:GetCurMainLevelId()
    local curLevel = self._Control:GetCurMainLevel()
    return self._Control:GetMainLevelConfigId(curLevel)
end

function XUiRogueSimLv:SetupDynamicTable()
    self.CurMainLevelId = self:GetCurMainLevelId()
    self:RefreshLvDetail(self.CurMainLevelId)
    self.DataList = self._Control:GetMainLevelList()
    local curIndex = -1
    local contain, index = table.contains(self.DataList, self.CurMainLevelId)
    if contain then
        curIndex = index
    end
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(curIndex)
end

---@param grid XUiGridRogueSimLv
function XUiRogueSimLv:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local id = self.DataList[index]
        local isSelect = id == self.CurMainLevelId
        grid:Refresh(id)
        grid:SetSelect(isSelect)
        if isSelect then
            self.CurSelectGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local id = self.DataList[index]
        if self.CurMainLevelId ~= id then
            if self.CurSelectGrid then
                self.CurSelectGrid:SetSelect(false)
            end
            grid:SetSelect(true)
            self.CurSelectGrid = grid
            self.CurMainLevelId = id
            self:RefreshLvDetail(id)
        end
    end
end

function XUiRogueSimLv:RefreshLvDetail(id)
    if not self.LvDetail then
        ---@type XUiPanelRogueSimLvDetail
        self.LvDetail = require("XUi/XUiRogueSim/Lv/XUiPanelRogueSimLvDetail").New(self.PanelLvDetail, self)
        self.LvDetail:Open()
    end
    self.LvDetail:Refresh(id)
end

function XUiRogueSimLv:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiRogueSimLv:OnBtnBackClick()
    local type = self._Control:GetHasPopupDataType()
    if type == XEnumConst.RogueSim.PopupType.None then
        self:Close()
        return
    end
    -- 弹出下一个弹框
    self._Control:ShowNextPopup(self.Name, type)
end

return XUiRogueSimLv
