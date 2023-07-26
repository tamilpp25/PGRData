local XUiExpeditionRecruitCoreMemberPanel = XClass(nil, "XUiExpeditionRecruitCoreMemberPanel")
local XUiExpeditionRecruitCoreMemberGrid = require("XUi/XUiExpedition/Recruit/XUiExpeditionMemberPanel/XUiExpeditionRecruitCoreMemberGrid")

function XUiExpeditionRecruitCoreMemberPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GridSample = rootUi.CoreGridCharacter
    self.GridSample.gameObject:SetActiveEx(false)
    self.PanelCharacter = rootUi.PanelCharacter
    self.GridCoreCharacter = {}
end

function XUiExpeditionRecruitCoreMemberPanel:UpdateData()
    local team = XDataCenter.ExpeditionManager.GetTeam()
    local coreTeamList = team:GetCoreChara()
    for i = 1, #coreTeamList do
        local chara = coreTeamList[i]
        local grid = self.GridCoreCharacter[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridSample, self.PanelCharacter)
            grid = XUiExpeditionRecruitCoreMemberGrid.New(go, self.RootUi)
            self.GridCoreCharacter[i] = grid
        end
        grid:Refresh(chara)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #coreTeamList + 1, #self.GridCoreCharacter do
        self.GridCoreCharacter[i].GameObject:SetActiveEx(false)
    end
end

return XUiExpeditionRecruitCoreMemberPanel