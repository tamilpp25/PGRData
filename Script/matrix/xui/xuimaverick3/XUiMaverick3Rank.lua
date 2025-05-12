local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiMaverick3Rank : XLuaUi 孤胆枪手排行榜
---@field _Control XMaverick3Control
local XUiMaverick3Rank = XLuaUiManager.Register(XLuaUi, "UiMaverick3Rank")

function XUiMaverick3Rank:OnAwake()
    self:BindHelpBtn(self.BtnHelp, "Maverick3RankHelp")

    local XUiMaverick3RankGrid = require("XUi/XUiMaverick3/Grid/XUiMaverick3RankGrid")
    ---@type XDynamicTableNormal
    self._DynamicTable = XDynamicTableNormal.New(self.RankList)
    self._DynamicTable:SetProxy(XUiMaverick3RankGrid, self)
    self._DynamicTable:SetDelegate(self)

    ---@type XUiMaverick3RankGrid
    self._MyRank = XUiMaverick3RankGrid.New(self.GridMyRank, self)
end

function XUiMaverick3Rank:OnStart()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)

    local chapter = self._Control:GetInfiniteChapter()
    self._Stages = self._Control:GetStagesByChapterId(chapter.ChapterId)
    self._Datas = {}

    local btns = { self.BtnTong1, self.BtnTong2 }
    self.BtnTong1:SetNameByGroup(0, self._Stages[1].Name)
    self.BtnTong2:SetNameByGroup(0, self._Stages[2].Name)
    self.BtnTabGroup:Init(btns, handler(self, self.OnTabSelect))
    self.GridRank.gameObject:SetActiveEx(false)

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end, nil, 0)
end

function XUiMaverick3Rank:OnEnable()
    self.BtnTabGroup:SelectIndex(1)
end

function XUiMaverick3Rank:OnTabSelect(i)
    if XTool.IsNumberValid(self._CurIndex) then
        self:PlayAnimationWithMask("QieHuan")
    end
    self._CurIndex = i
    self._CurStageId = self._Stages[i].StageId
    self._Datas[i] = self._Control:GetRankData(self._CurStageId)
    self:UpdateView()
end

function XUiMaverick3Rank:UpdateView()
    local rankData = self._Datas[self._CurIndex]
    local rankPlayerInfos = rankData.RankPlayerInfos

    self.PanelNoRank.gameObject:SetActiveEx((not next(rankPlayerInfos)))
    self._DynamicTable:SetDataSource(rankPlayerInfos)
    self._DynamicTable:ReloadDataASync(1)
    self._MyRank:Refresh(self._Control:GetMyRankData(self._CurStageId))
end

---@param grid XUiMaverick3RankGrid
function XUiMaverick3Rank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankInfo = self._DynamicTable:GetData(index)
        rankInfo.Rank = index
        grid:Refresh(rankInfo)
    end
end

return XUiMaverick3Rank