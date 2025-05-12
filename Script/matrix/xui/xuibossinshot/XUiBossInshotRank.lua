local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiBossInshotRank:XLuaUi
---@field private _Control XBossInshotControl
local XUiBossInshotRank = XLuaUiManager.Register(XLuaUi, "UiBossInshotRank")

function XUiBossInshotRank:OnAwake()
    self:RegisterUiEvents()
    self:InitTabButtons()
    self:InitDynamicTable()
    self:InitMyRankPanel()
end

function XUiBossInshotRank:OnStart()

end

function XUiBossInshotRank:OnEnable()
    self.BtnContent:SelectIndex(1)
end

function XUiBossInshotRank:OnDestroy()
    self:ClearGridsTimer()
end

function XUiBossInshotRank:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiBossInshotRank:OnBtnBackClick()
    self:Close()
end

function XUiBossInshotRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBossInshotRank:InitTabButtons()
    self.TabButtons = {}
    self.TabDatas = {}
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local activityId = self._Control:GetActivityId()
    local charIds = self._Control:GetActivityCharacterIds(activityId)
    local bossIds = self._Control:GetActivityBossIds(activityId)
    
    for i, charId in ipairs(charIds) do
        local charGo = CSInstantiate(self.BtnFirst, self.BtnFirst.transform.parent)
        local charBtn = charGo:GetComponent("XUiButton")
        local charName = self._Control:GetCharacterName(charId)
        charBtn:SetNameByGroup(0, charName)
        table.insert(self.TabButtons, charBtn)
        local subGroupIndex = #self.TabButtons
        
        -- 二级页签 总榜
        local bossGo = CSInstantiate(self.BtnSecond, self.BtnFirst.transform.parent)
        local bossBtn = bossGo:GetComponent("XUiButton")
        local bossName = XUiHelper.GetText("SCRankTotalName")
        bossBtn:SetNameByGroup(0, bossName)
        bossBtn.SubGroupIndex = subGroupIndex
        table.insert(self.TabButtons, bossBtn)
        self.TabDatas[#self.TabButtons] = { CharId = charId }
        
        -- 二级页签 Boss
        for _, bossId in ipairs(bossIds) do
            bossGo = CSInstantiate(self.BtnSecond, self.BtnFirst.transform.parent)
            bossBtn = bossGo:GetComponent("XUiButton")
            bossName = self._Control:GetBossName(bossId)
            bossBtn:SetNameByGroup(0, bossName)
            bossBtn.SubGroupIndex = subGroupIndex
            table.insert(self.TabButtons, bossBtn)
            self.TabDatas[#self.TabButtons] = { CharId = charId, BossId = bossId }
        end
    end
    self.BtnContent:Init(self.TabButtons, function(index)
        self:OnSelectTab(index)
    end)
    
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
end

function XUiBossInshotRank:OnSelectTab(index)
    self.SelectIndex = index
    self:Refresh()
end

function XUiBossInshotRank:Refresh()
    local tabData = self.TabDatas[self.SelectIndex]
    local isTotalRank = not XTool.IsNumberValid(tabData.BossId)
    XMVCA.XBossInshot:BossInshotQueryRankRequest(tabData.CharId, tabData.BossId, isTotalRank, function(rankData)
        self:RefreshDynamicTable(rankData)
        self:RefreshMyRank(rankData)
    end)
end

function XUiBossInshotRank:InitMyRankPanel()
    local XUiGridBossInshotRank = require("XUi/XUiBossInshot/XUiGridBossInshotRank")
    self.MyRank = XUiGridBossInshotRank.New(self.PanelMyRank, self)
end

-- 刷新我的排名
function XUiBossInshotRank:RefreshMyRank(rankData)
    local rankInfo = {}
    local percentRank = 100 -- 101名及以上显示百分比
    local rank = rankData.Rank
    if rankData.Rank > percentRank then
        rank = math.max(1, math.floor(rankData.Rank * 100 / rankData.TotalCount)) .. "%" -- 最小显示1%
    elseif rankData.Rank == 0 then
        rank = XUiHelper.GetText("ExpeditionNoRanking")
    end
    rankInfo["Rank"] = rank
    rankInfo["Id"] = XPlayer.Id
    rankInfo["Name"] = XPlayer.Name
    rankInfo["HeadPortraitId"] = XPlayer.CurrHeadPortraitId
    rankInfo["HeadFrameId"] = XPlayer.CurrHeadFrameId
    rankInfo["Score"] = rankData.Score
    rankInfo["CharacterIds"] = rankData.CharacterIds
    self.MyRank:Refresh(rankInfo)
end


---------------------------------------- 动态列表 start ----------------------------------------
function XUiBossInshotRank:InitDynamicTable()
    self.PlayerRank.gameObject:SetActiveEx(false)
    local XUiGridBossInshotRank = require("XUi/XUiBossInshot/XUiGridBossInshotRank")
    self.DynamicTable = XDynamicTableNormal.New(self.PlayerRankList)
    self.DynamicTable:SetProxy(XUiGridBossInshotRank, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiBossInshotRank:RefreshDynamicTable(rankData)
    self.DataList = rankData.RankPlayerInfos
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    self.PanelNoRank.gameObject:SetActiveEx((not next(self.DataList)))
end

function XUiBossInshotRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankInfo = self.DataList[index]
        rankInfo.Rank = index
        grid:Refresh(rankInfo)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        -- 动画完成前禁用拖拽
        local scrollRect = self.PlayerRankList:GetComponent("ScrollRect")
        scrollRect.vertical = false
        
        local grids = self.DynamicTable:GetGrids()
        local gridCnt = #grids
        for _, g in pairs(grids) do
            g.GameObject:SetActive(false)
        end
        self:ClearGridsTimer()
        self.GridIndex = 1
        self.GridsTimer = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item.GameObject:SetActive(true)
            end
            self.GridIndex = self.GridIndex + 1

            -- 恢复拖拽
            if self.GridIndex == gridCnt then
                scrollRect.vertical = true
            end
        end, 100, gridCnt)
    end
end

function XUiBossInshotRank:ClearGridsTimer()
    if self.GridsTimer then
        XScheduleManager.UnSchedule(self.GridsTimer)
        self.GridsTimer = nil
    end
end
---------------------------------------- 动态列表 end ----------------------------------------

return XUiBossInshotRank