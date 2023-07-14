local XUiFubenMaverickBuffSummary = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickBuffSummary")
local XUiFubenMaverickTalentDescGrid = require("XUi/XUiFubenMaverick/XUiGrid/XUiFubenMaverickTalentDescGrid")
local Instantiate = CS.UnityEngine.Object.Instantiate

function XUiFubenMaverickBuffSummary:OnAwake()
    self.TalentGrids = { }
    
    self:InitButtons()
end

function XUiFubenMaverickBuffSummary:InitButtons()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

function XUiFubenMaverickBuffSummary:OnStart(memberId)
    --获取这个角色的所有天赋
    local talentIds = XDataCenter.MaverickManager.GetMemberActiveTalentIds(memberId)

    if talentIds then
        for i, item in ipairs(talentIds) do
            local grid
            if self.TalentGrids[i] then
                grid = self.TalentGrids[i]
            else
                local ui = Instantiate(self.GridBuff, self.GridBuff.parent)
                grid = XUiFubenMaverickTalentDescGrid.New(ui)
                self.TalentGrids[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local talentIdCount = 0
    if talentIds then
        talentIdCount = #talentIds
    end

    for j = 1, #self.TalentGrids do
        if j > talentIdCount then
            self.TalentGrids[j].GameObject:SetActiveEx(false)
        end
    end

    self.GridBuff.gameObject:SetActiveEx(false)
    
    self.PanelAllTheSliding.gameObject:SetActiveEx(talentIdCount > 0)
    self.PanelNone.gameObject:SetActiveEx(talentIdCount == 0)
    
    self.GameObject:SetActiveEx(true)
end