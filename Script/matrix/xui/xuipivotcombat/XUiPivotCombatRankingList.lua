--===========================================================================
 ---@desc 枢纽作战--排行榜
--===========================================================================
local XUiPivotCombatRankingList = XLuaUiManager.Register(XLuaUi, "UiPivotCombatRankingList")
local XUiPivotCombatRankGrid    = require("XUi/XUiPivotCombat/XUiGrid/XUiPivotCombatRankGrid")
local XPivotCombatRankItem      = require("XEntity/XPivotCombat/XPivotCombatRankItem")
local CSGetText = CS.XTextManager.GetText

--难度 -> 页签下标
local Difficult2Index = {
    [XPivotCombatConfigs.DifficultType.Normal] = 1,
    [XPivotCombatConfigs.DifficultType.Hard] = 2,
}

--难度列表
local DifficultyList = { 
    XPivotCombatConfigs.DifficultType.Normal, 
    XPivotCombatConfigs.DifficultType.Hard 
}

function XUiPivotCombatRankingList:OnAwake()
    self:InitUI()
    self:InitCB()
    self:InitDynamicTable()
end 

function XUiPivotCombatRankingList:OnStart()
    self.TxtTitle.text = CSGetText("PicCompositionRankTop", XDataCenter.PivotCombatManager.GetMaxRankMember())
    self.Difficulty    = XDataCenter.PivotCombatManager.GetDifficulty()
    
    --我的排行信息
    self.RankOfMine = XPivotCombatRankItem.New()
    self.Difficulty2RankData = {}


    self.ButtonGroup:SelectIndex(Difficult2Index[self.Difficulty])
end 

function XUiPivotCombatRankingList:OnEnable()
    self:SetScreenAdaptorCache()
end

function XUiPivotCombatRankingList:OnGetEvents()
    return { XEventId.EVENT_ACTIVITY_ON_RESET, XEventId.EVENT_PIVOTCOMBAT_ACTIVITY_END }
end

function XUiPivotCombatRankingList:OnNotify(evt, ...)
    local args = { ... }
    XDataCenter.PivotCombatManager.OnNotify(evt, args)
end

--==============================
 ---@desc 发送协议，请求更新排行榜
--==============================
function XUiPivotCombatRankingList:Refresh()
    local difficult = DifficultyList[self.SelectIndex]
    local func = function(rankList, ranking, totalCount) 
        self:UpdateRankList(rankList, ranking, totalCount)
    end
    XDataCenter.PivotCombatManager.GetRankInfoPivotCombatRequest(difficult, func)
end

--==============================
 ---@desc 刷新玩家自身排行榜数据
--==============================
function XUiPivotCombatRankingList:RefreshMineData()
    self.RankDataOfMine = {
        Id                   = XPlayer.Id,
        Name                 = XPlayer.Name,
        HeadPortraitId       = XPlayer.CurrHeadPortraitId,
        HeadFrameId          = XPlayer.CurrHeadFrameId,
        Score                = 0,
        CharacterInfoList    = {},
        FightTimeScore       = XPivotCombatConfigs.FightTimeScoreInitialValue
    }
    --最高分
    local maxScore      = XDataCenter.PivotCombatManager.GetMaxScore()
    --通关时间积分
    local timeScore     = XDataCenter.PivotCombatManager.GetFightTimeScore()
    --中心区域
    local centerRegion  = XDataCenter.PivotCombatManager.GetCenterRegion()
    --通关角色信息
    local characterInfoList
    if centerRegion then
        local centerStage = centerRegion:GetCenterStage()
        characterInfoList = centerStage:GetCharacterInfoList()
    else
        characterInfoList = {}
    end

    self.RankDataOfMine.Score = maxScore
    self.RankDataOfMine.CharacterInfoList = characterInfoList
    self.RankDataOfMine.FightTimeScore = timeScore
end

--==============================
 ---@desc 更新排行榜
 ---@rankList list {XPivotCombatRankItem,.......} 数据组列表
 ---@ranking number 排名
 ---@totalCount number 总人数
--==============================
function XUiPivotCombatRankingList:UpdateRankList(rankList, ranking, totalCount)
    self.RankList = rankList or self.RankList
    self.Ranking = ranking or self.Ranking
    self.TotalCount = totalCount or self.TotalCount
    
    local isHideRankList = XTool.IsTableEmpty(self.RankList)
    self.PanelNoRank.gameObject:SetActiveEx(isHideRankList)
    self.PanelRankingList.gameObject:SetActiveEx(not isHideRankList)
    self.IsHideRankList = isHideRankList

    self:UpdateDynamicTable()
    self:UpdateRankOfMineInfo()
end

--==============================
 ---@desc 更新列表
--==============================
function XUiPivotCombatRankingList:UpdateDynamicTable()
    if self.IsHideRankList then return end
    self.DynamicTable:SetDataSource(self.RankList)
    self.DynamicTable:ReloadDataASync()
end

--==============================
 ---@desc 更新我的信息，不是当前难度则不更新
--==============================
function XUiPivotCombatRankingList:UpdateRankOfMineInfo()
    local active = Difficult2Index[self.Difficulty] == self.SelectIndex
    self.PanelRankOfMine.GameObject:SetActiveEx(active)
    if not active then
        return
    end
    self:RefreshMineData()
    self.RankOfMine:Refresh(self.RankDataOfMine, self.Ranking, self.TotalCount)
    --分数
    self.PanelRankOfMine.TxtRankScore.text = CSGetText("PivotCombatRankScore", self.RankOfMine:GetScore())
    --通关时间
    self.PanelRankOfMine.TxtRankTime.text = CSGetText("PivotCombatRankTime", self.RankOfMine:GetFightTime())
    --排名
    local isTop = self.RankOfMine:IsTopOnTheList()
    self.PanelRankOfMine.ImgRankSpecial.gameObject:SetActiveEx(isTop)
    self.PanelRankOfMine.TxtRankNormal.gameObject:SetActiveEx(not isTop)
    if isTop then
        self.PanelRankOfMine.ImgRankSpecial:SetSprite(XPivotCombatConfigs.GetRankingIcon(self.RankOfMine:GetRanking()))
    else
        --是否上榜
        local isOnTheList = self.RankOfMine:GetIsOnTheList()
        if isOnTheList then
            self.PanelRankOfMine.TxtRankNormal.text = self.RankOfMine:GetRanking()
        else
            self.PanelRankOfMine.TxtRankNormal.text = self.RankOfMine:GetRankingPercentage()
        end
    end
    --昵称
    self.PanelRankOfMine.TxtPlayerName.text = self.RankOfMine:GetName()
    --头像
    XUiPLayerHead.InitPortrait(self.RankOfMine:GetHeadPortraitId(), self.RankOfMine:GetHeadFrameId(), self.PanelRankOfMine.Head)
    --通关头像
    self.RankOfMine:RefreshHeadList(self.UiHeadListOfMine)
end

function XUiPivotCombatRankingList:InitUI()
    self.PanelRankOfMine = {}
    self.PanelSpecialTool.gameObject:SetActiveEx(false)
    self.GridRank.gameObject:SetActiveEx(false)
    self.BtnTab01.gameObject:SetActiveEx(false)
    XTool.InitUiObjectByUi(self.PanelRankOfMine, self.PanelMyRank)
    --玩家自己头像列表
    self.UiHeadListOfMine = { 
        self.PanelRankOfMine.RImgTeam1, 
        self.PanelRankOfMine.RImgTeam2, 
        self.PanelRankOfMine.RImgTeam3,
    }
    --页签
    self.ButtonGroup = self.PanelTag:GetComponent("XUiButtonGroup")
    local btnGroup = {}
    for idx, type in ipairs(DifficultyList) do
        local btn = CS.UnityEngine.Object.Instantiate(self.BtnTab01, self.PanelTag, false):GetComponent("XUiButton")
        btn.gameObject:SetActiveEx(true)
        btn:SetName(XPivotCombatConfigs.GetDifficultName(type))
        btnGroup[idx] = btn
    end

    self.ButtonGroup:Init(btnGroup, function(index) self:SwitchDifficult(index) end)

end 

function XUiPivotCombatRankingList:InitCB()
    self.BtnBack.CallBack = function() 
        self:Close()
    end
    self.BtnMainUi.CallBack = function() 
        XLuaUiManager.RunMain()
    end
end 

function XUiPivotCombatRankingList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRankingList)
    self.DynamicTable:SetProxy(XUiPivotCombatRankGrid)
    self.DynamicTable:SetDelegate(self)
end 

function XUiPivotCombatRankingList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RankList[index])
    end
end 

function XUiPivotCombatRankingList:SwitchDifficult(index)
    if self.SelectIndex == index then return end
    
    self.SelectIndex = index
    
    self:Refresh()
end

--异形屏适配
function XUiPivotCombatRankingList:SetScreenAdaptorCache()
    if not XTool.UObjIsNil(self.SafeAreaContentPane) then
        self.SafeAreaContentPane:UpdateSpecialScreenOff()
    end
end 