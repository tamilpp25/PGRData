local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridPokerGuessingStory = XClass(nil, "XUiGridPokerGuessingStory")

function XUiGridPokerGuessingStory:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.AnimEnable = self.Transform:Find("Animation/AnimEnable")
    self.CanvasGroup = self.Transform:GetComponent("CanvasGroup")
    self.IsPlay = false
    self:AddListener()
end

function XUiGridPokerGuessingStory:AddListener()
    self.BtnGiveGifts.CallBack = function() self:OnBtnGiveGiftsClick() end
    self.Btnplay.CallBack = function() self:OnBtnPlayClick() end
end

function XUiGridPokerGuessingStory:Refresh(data, index)
    self.GameObject:SetActiveEx(self.IsPlay)
    self.Data = data
    self.ArchiveNpcName.text = XMVCA.XCharacter:GetCharacterName(data.Cfg.CharacterId)
    self.NPCImg:SetRawImage(data.Cfg.Icon)
    local isUnlock = self.Data.IsUnlock
    --local btnName = isUnlock and XUiHelper.GetText("PokerGuessingPlayStory") 
    --        or XUiHelper.GetText("PokerGuessingUnlockStory")
    --self.BtnGiveGifts:SetNameByGroup(0, btnName)
    self.Btnplay.gameObject:SetActiveEx(isUnlock)
    self.BtnGiveGifts.gameObject:SetActiveEx(not isUnlock)
    self:PlayEnableAnimation(index)
end

function XUiGridPokerGuessingStory:PlayEnableAnimation(index)
    self.GameObject:SetActiveEx(true)
    if self.GameObject.activeInHierarchy and self.AnimEnable and not self.IsPlay then
        self.CanvasGroup.alpha = 0
        XScheduleManager.ScheduleOnce(function()
            self.AnimEnable:PlayTimelineAnimation(function()
                self.CanvasGroup.alpha = 1
                self.IsPlay = true
            end)
        end, (index - 1) * 90)
    end
end

function XUiGridPokerGuessingStory:OnBtnGiveGiftsClick()
    local stageId = self.Data.Cfg.StageId
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(stageId)
    XDataCenter.PokerGuessingManager.UnlockCharacterStoryRequest(self.Data.Cfg.CharacterId, function()
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        XDataCenter.MovieManager.PlayMovie(beginStoryId)
    end)
end

function XUiGridPokerGuessingStory:OnBtnPlayClick()
    local stageId = self.Data.Cfg.StageId
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(stageId)
    XDataCenter.MovieManager.PlayMovie(beginStoryId)
end


local XUiFubenPokerGuessingStory = XLuaUiManager.Register(XLuaUi, "UiFubenPokerGuessingStory")

function XUiFubenPokerGuessingStory:OnAwake()
    self:InitCb()
    self:InitDynamicTable()
end 

function XUiFubenPokerGuessingStory:InitCb()
    self:BindExitBtns()

    self.ToggleFilter.onValueChanged:AddListener(handler(self, self.OnToggleFilterValueChanged))
end

function XUiFubenPokerGuessingStory:OnStart()
    self.PokerGuessing = XDataCenter.PokerGuessingManager.GetPokerGuessingData()
    self.UnLockCharacters = self.PokerGuessing:GetProperty("_UnLockCharacters")
    self.IsSelectFilter = self.PokerGuessing:IsSelectFilter()
    self.ToggleFilter.isOn = self.IsSelectFilter
    self:InitView()
    
    XUiHelper.NewPanelActivityAssetSafe( { XDataCenter.ItemManager.ItemId.PokerGuessingItemId }, self.PanelAsset, self)
end

function XUiFubenPokerGuessingStory:OnGetEvents()
    
    return {
        XEventId.EVENT_POKER_GUESSING_ACTIVITY_END,
    }
end

function XUiFubenPokerGuessingStory:OnNotify(evt, ...)
    if evt == XEventId.EVENT_POKER_GUESSING_ACTIVITY_END then
        XUiManager.TipText("PokerGuessingActivityEnd")
        XLuaUiManager.RunMain()
    end
end

function XUiFubenPokerGuessingStory:InitView()
    local pokerGuessing = self.PokerGuessing
    XDataCenter.PokerGuessingManager.MarkUnlockStory()
    self:BindViewModelPropertyToObj(pokerGuessing, function(unlockList)
        self.UnLockCharacters = unlockList
        self:SetupDynamicTable()
    end, "_UnLockCharacters")

    local endTime = XDataCenter.PokerGuessingManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.PokerGuessingManager.OnActivityEnd()
            return
        end
    end)
end

function XUiFubenPokerGuessingStory:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelArchiveList)
    self.DynamicTable:SetProxy(XUiGridPokerGuessingStory)
    self.DynamicTable:SetDelegate(self)
    self.GridArchiveNpc.gameObject:SetActiveEx(false)
end

function XUiFubenPokerGuessingStory:SetupDynamicTable() 
    local configs = XPokerGuessingConfig.PokerStoryConfig:GetConfigs()
    local unlockDict = {}
    for _, characterId in ipairs(self.UnLockCharacters) do
        unlockDict[characterId] = true
    end
    local infoList = {}
    for _, cfg in ipairs(configs) do
        local unlock = unlockDict[cfg.CharacterId] and true or false
        local item = { Cfg = cfg, IsUnlock = unlock}
        table.insert(infoList, item)
    end
    
    table.sort(infoList, function(a, b)
        if self.IsSelectFilter then
            local unlockA = a.IsUnlock
            local unlockB = b.IsUnlock
            if unlockA ~= unlockB then
                return unlockB
            end
        end
        return a.Cfg.Id < b.Cfg.Id
    end)
    
    self.StoryList = infoList
    self.DynamicTable:SetDataSource(infoList)
    self.DynamicTable:ReloadDataASync()
end 

function XUiFubenPokerGuessingStory:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.StoryList[index], index)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayGridAnimation()
    end
end 

function XUiFubenPokerGuessingStory:PlayGridAnimation()
    local grids = self.DynamicTable:GetGrids()
    for i, grid in ipairs(grids) do
        grid:PlayEnableAnimation(i)
    end
end

function XUiFubenPokerGuessingStory:OnToggleFilterValueChanged(select)
    self.IsSelectFilter = select
    self.PokerGuessing:MarkSelectFilter(select)
    self:SetupDynamicTable()
end 