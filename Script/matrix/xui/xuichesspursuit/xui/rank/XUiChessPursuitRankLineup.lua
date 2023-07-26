local XUiChessPursuitRankLineupGrid = require("XUi/XUiChessPursuit/XUi/Rank/XUiChessPursuitRankLineupGrid")

--排行榜某个玩家的详细界面
local XUiChessPursuitRankLineup = XLuaUiManager.Register(XLuaUi, "UiChessPursuitRankLineup")

function XUiChessPursuitRankLineup:OnAwake()
    self.GridBossRankReward.gameObject:SetActiveEx(false)
    self:AutoAddListener()
    self:InitDynamicTable()
end

function XUiChessPursuitRankLineup:OnStart(playerId, chessPursuitRankGridList)
    self.RankPlayerTemplate = XDataCenter.ChessPursuitManager.GetPursuitRankData(playerId)
    self.ChessPursuitRankGridList = chessPursuitRankGridList
end

function XUiChessPursuitRankLineup:OnEnable()
    self:Refresh()
end

function XUiChessPursuitRankLineup:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.List)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiChessPursuitRankLineupGrid, self)
end

function XUiChessPursuitRankLineup:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCopy, self.OnBtnCopy)
end

function XUiChessPursuitRankLineup:Refresh()
    self:RefreshDynamicTable()
    self:RefreshPlayerInfo()
end

function XUiChessPursuitRankLineup:RefreshPlayerInfo()
    if not self.RankPlayerTemplate then
        return
    end
    local headPortraitId = self.RankPlayerTemplate:GetHead()
    local headFrameId = self.RankPlayerTemplate:GetFrame()
    XUiPLayerHead.InitPortrait(headPortraitId, headFrameId, self.Head)

    local name = self.RankPlayerTemplate:GetName()
    self.PlayerId = self.RankPlayerTemplate:GetPlayerId()
    local level = self.RankPlayerTemplate:GetLevel()
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(self.PlayerId, name)
    XUiPlayerLevel.UpdateLevel(level, self.level)
    self.TxtId.text = self.PlayerId
end

function XUiChessPursuitRankLineup:RefreshDynamicTable()
    if not self.ChessPursuitRankGridList then
        return
    end
    self.DynamicTable:SetDataSource(self.ChessPursuitRankGridList)
    self.DynamicTable:ReloadDataSync()
end

function XUiChessPursuitRankLineup:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankGridTemplate = self.ChessPursuitRankGridList[index]
        grid:Refresh(rankGridTemplate, self.PlayerId, index)
    end
end

function XUiChessPursuitRankLineup:OnBtnCopy()
    CS.XAppPlatBridge.CopyStringToClipboard(tostring(self.TxtId.text))
    XUiManager.TipText("Clipboard", XUiManager.UiTipType.Tip)
end