local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTeamSelectGrid = require("XUi/XUiBiancaTheatre/Common/XUiTeamSelectGrid")

local XUiChoiceTeamPanel = XClass(nil, "XUiChoiceTeamPanel")

--分队选择布局
function XUiChoiceTeamPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)
end

function XUiChoiceTeamPanel:Init()
    self.DynamicTable = XDynamicTableNormal.New(self.Transform:GetComponent(typeof(CS.XDynamicTableNormal)))
    self.DynamicTable:SetProxy(XUiTeamSelectGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridChallengeBanner.gameObject:SetActiveEx(false)
    
    self.TeamIdList = XDataCenter.BiancaTheatreManager.GetTeamIdList()
    self:RewriteRootUiFunc()
    self.GameObject:SetActiveEx(true)
end

function XUiChoiceTeamPanel:Refresh()
    self.DynamicTable:SetDataSource(self.TeamIdList)
    self.DynamicTable:ReloadDataASync()
end

local isSelect
function XUiChoiceTeamPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        isSelect = self.CurSelectId and self.CurSelectId == self.TeamIdList[index]
        grid:Refresh(self.TeamIdList[index], isSelect)
        grid.Btn:SetName(XBiancaTheatreConfigs.GetClientConfig("BtnSelectName"))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if grid:GetIsUnlock() then
            self:ClickGridFunc(grid)
        end
    end
end

function XUiChoiceTeamPanel:ClickGridFunc(grid)
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelectActive(false)
    end
    self.CurSelectGrid = grid
    self.CurSelectTeamId = grid:GetTeamId()
    grid:SetSelectActive(true)
end

--######################## 重写父UI按钮点击回调 ########################
function XUiChoiceTeamPanel:RewriteRootUiFunc()
    XUiHelper.RegisterClickEvent(self, self.RootUi.BtnNextStep, self.OnBtnNextStepClicked)
end

--点击下一步
function XUiChoiceTeamPanel:OnBtnNextStepClicked()
    if not XTool.IsNumberValid(self.CurSelectTeamId) then
        XUiManager.TipError(XBiancaTheatreConfigs.GetClientConfig("NotSelectTeam"))
        return
    end
    
    XDataCenter.BiancaTheatreManager.RequestSelectTeam(self.CurSelectTeamId, function()
        XEventManager.DispatchEvent(XEventId.EVENT_BIANCA_THEATRE_SELECT_TEAM_UPGRADE)
    end)
end

return XUiChoiceTeamPanel