local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiGridFubenRepeatchallengeLevel = require("XUi/XUiFubenRepeatchallenge/XUiGridFubenRepeatchallengeLevel")
local XUiFubenRepeatchallengeLevelDes = XLuaUiManager.Register(XLuaUi, "UiFubenRepeatchallengeLevelDes")

function XUiFubenRepeatchallengeLevelDes:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.TxtDayExp.gameObject:SetActiveEx(false)
end

function XUiFubenRepeatchallengeLevelDes:OnEnable()
    self:Refresh()
end

function XUiFubenRepeatchallengeLevelDes:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridFubenRepeatchallengeLevel)
    self.GridRepeatChallengeLevel.gameObject:SetActiveEx(false)
end

function XUiFubenRepeatchallengeLevelDes:Refresh()
    self:UpdateDynamicTable()
end

function XUiFubenRepeatchallengeLevelDes:UpdateDynamicTable()
    self.LevelList = XFubenRepeatChallengeConfigs.GetLevelConfigs()
    self.DynamicTable:SetDataSource(self.LevelList)
    self.DynamicTable:ReloadDataSync(-1)
end

function XUiFubenRepeatchallengeLevelDes:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index)
    end
end

function XUiFubenRepeatchallengeLevelDes:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiFubenRepeatchallengeLevelDes:OnBtnCloseClick()
    self:Close()
end