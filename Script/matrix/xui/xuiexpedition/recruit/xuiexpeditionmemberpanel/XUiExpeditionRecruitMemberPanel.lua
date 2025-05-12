local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--虚像地平线招募界面：成员列表控件
local XUiExpeditionRecruitMemberPanel = XClass(nil, "XUiExpeditionRecruitMemberPanel")
local XUiExpeditionMemberGrid = require("XUi/XUiExpedition/Recruit/XUiExpeditionMemberPanel/XUiExpeditionRecruitMemberGrid")

function XUiExpeditionRecruitMemberPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridSample = rootUi.FetterGridCharacter
    self.GridSample.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiExpeditionRecruitMemberPanel:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiExpeditionMemberGrid)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiExpeditionRecruitMemberPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.TeamPosList and self.TeamPosList[index] then
            grid:RefreshDatas(self.TeamPosList[index], index)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if XDataCenter.ExpeditionManager.CheckCharaIsInDisplayByIndex(index) then
            self.RootUi:OpenRoleDetailsPanel(
                    XDataCenter.ExpeditionManager.GetTeam():GetFetterCharaByPos(index),
                    XExpeditionConfig.MemberDetailsType.FireMember,
                    index,
                    function()
                        grid.PanelSelected.gameObject:SetActiveEx(true)
                        self.SelectIndex = index
                    end,
                    function()
                        for _, v in pairs(self.DynamicTable:GetGrids() or {}) do
                            v.PanelSelected.gameObject:SetActiveEx(false)
                        end
                    end)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:InitEffect()
    end
end

function XUiExpeditionRecruitMemberPanel:UpdateData()
    self.TeamPosList = XDataCenter.ExpeditionManager.GetTeamPosDisplayList()
    self.DynamicTable:SetDataSource(self.TeamPosList)
    self.DynamicTable:ReloadDataASync(1)
end

return XUiExpeditionRecruitMemberPanel