local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
local XUiGridAwarenessTeamInfoExp = XClass(nil, "XUiGridAwarenessTeamInfoExp")

function XUiGridAwarenessTeamInfoExp:Ctor(rootUi, ui, baseStageId, index, teamInfoId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
    self:ResetDataInfo()
    self:UpdateDataInfo(baseStageId, index, teamInfoId)
end

function XUiGridAwarenessTeamInfoExp:InitComponent()
    self.GridCharacter.gameObject:SetActive(false)
end

function XUiGridAwarenessTeamInfoExp:ResetDataInfo()
    self.BaseStage = nil
    self.TeamInfoIndex = nil
    self.TeamInfoId = nil
end

function XUiGridAwarenessTeamInfoExp:UpdateDataInfo(baseStageId, index, teamInfoId)
    self.BaseStage = baseStageId
    self.TeamInfoIndex = index
    self.TeamInfoId = teamInfoId
    self:UpdateTxtExp()
    self:UpdateTxtEchelonIndex()
    self:UpdateFightTeamCharacter()
end

function XUiGridAwarenessTeamInfoExp:UpdateTxtExp()
    local cardExp = XDataCenter.FubenManager.GetCardExp(self.BaseStage)
    self.TxtExp.text = "+" .. cardExp
end

function XUiGridAwarenessTeamInfoExp:UpdateTxtEchelonIndex()
    self.TxtEchelonIndex.text = CS.XTextManager.GetText("AssignTeamTitle", self.TeamInfoIndex)
end

function XUiGridAwarenessTeamInfoExp:UpdateFightTeamCharacter()
    local teamData = XDataCenter.FubenAwarenessManager.GetTeamDataById(self.TeamInfoId)
    if not teamData then
        XLog.Error("XUiGridAwarenessTeamInfoExp UpdateFightTeamCharacter error: do not have teamData.")
        return
    end

    for _, memberData in ipairs(teamData:GetMemberList()) do
        local charId = memberData:GetCharacterId()
        if charId and charId ~= 0 then
            local char = XMVCA.XCharacter:GetCharacter(charId)
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCharacter)
            local grid = XUiGridCharacter.New(ui, self, char)
            grid.Transform:SetParent(self.PanelCharacters, false)
            grid.GameObject:SetActive(true)
        end
    end
end

return XUiGridAwarenessTeamInfoExp