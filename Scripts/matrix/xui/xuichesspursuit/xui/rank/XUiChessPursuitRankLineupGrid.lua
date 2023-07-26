local XUiChessPursuitRankLineupCardGrid = require("XUi/XUiChessPursuit/XUi/Rank/XUiChessPursuitRankLineupCardGrid")
local XUiChessPursuitRankLineupRoleGrid = require("XUi/XUiChessPursuit/XUi/Rank/XUiChessPursuitRankLineupRoleGrid")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiChessPursuitRankLineupGrid = XClass(nil, "XUiChessPursuitRankLineupGrid")

function XUiChessPursuitRankLineupGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.RoleGridList = {}
    self.CardGridList = {}
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiChessPursuitRankLineupGrid:Refresh(rankGridTemplate, playerId, index)
    if not rankGridTemplate then return end
    self.PlayerId = playerId
    self.RankGridTemplate = rankGridTemplate

    self.TxtCheck.text = CS.XTextManager.GetText("ChessPursuitMapGridNumText", index)

    local bossHp = XDataCenter.ChessPursuitManager.GetChessPursuitRankDetailBossHp()
    local hurt = rankGridTemplate:GetHurt()
    if hurt < 0 then
        self.TxtRecord.text = CS.XTextManager.GetText("ChessPursuitRankNotRecord")
    elseif bossHp and bossHp > 0 then
        local percent = string.format("%.2f%%", hurt / bossHp * 100)
        self.TxtRecord.text = CS.XTextManager.GetText("ChessPursuitMaxDamageHistory", percent)
    else
        self.TxtRecord.text = CS.XTextManager.GetText("ChessPursuitMaxDamageHistory", hurt)
    end

    self:RefreshRoleGrid()
    self:RefreshCardGrid()
end

function XUiChessPursuitRankLineupGrid:RefreshRoleGrid()
    for _, roleGrid in ipairs(self.RoleGridList) do
        roleGrid.gameObject:SetActiveEx(false)
    end

    local characterIdList = self.RankGridTemplate:GetCharacterIdList(self.Index, self.PlayerId)
    for i, characterId in ipairs(characterIdList) do
        if not self.RoleGridList[i] then
            if i == 1 then
                self.RoleGridList[i] = XUiChessPursuitRankLineupRoleGrid.New(self.GridRole)
            else
                local grid = CSUnityEngineObjectInstantiate(self.GridRole, self.PanelRole.transform)
                self.RoleGridList[i] = XUiChessPursuitRankLineupRoleGrid.New(grid)
            end
        end
        self.RoleGridList[i]:Refresh(characterId, i)
    end
end

function XUiChessPursuitRankLineupGrid:RefreshCardGrid()
    for _, cardGrid in ipairs(self.CardGridList) do
        cardGrid.gameObject:SetActiveEx(false)
    end

    local usedCardIds = self.RankGridTemplate:GetUsedCardIds()
    for i, usedCardId in ipairs(usedCardIds) do
        if not self.CardGridList[i] then
            if i == 1 then
                self.CardGridList[i] = XUiChessPursuitRankLineupCardGrid.New(self.GridBuff, self.RootUi)
            else
                local grid = CSUnityEngineObjectInstantiate(self.GridBuff, self.Content.transform)
                self.CardGridList[i] = XUiChessPursuitRankLineupCardGrid.New(grid, self.RootUi)
            end
        end
        self.CardGridList[i]:Refresh(usedCardId)
        self.CardGridList[i].GameObject:SetActiveEx(true)
    end
end

return XUiChessPursuitRankLineupGrid