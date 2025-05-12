local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
local XUiGridCharacterTowerChapter = require("XUi/XUiCharacterTower/XUiGridCharacterTowerChapter")
---@class XUiCharacterTowerMain : XLuaUi
local XUiCharacterTowerMain = XLuaUiManager.Register(XLuaUi, "UiCharacterTowerMain")

function XUiCharacterTowerMain:OnAwake()
    self:RegisterUiEvents()
    
    self.GridCollegeBanner.gameObject:SetActiveEx(false)
end

function XUiCharacterTowerMain:OnStart(characterTowerId, chapterIdsInfo)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.CharacterTowerId = characterTowerId
    self.ChapterIdsInfo = chapterIdsInfo
    self.ChapterType = self.ChapterType or XFubenCharacterTowerConfigs.CharacterTowerChapterType.Story -- 默认剧情关
   
    self:SetTxtTitle()
    self:InitDynamicTable()
end

function XUiCharacterTowerMain:OnEnable()
    self:UpdateChapterTypeUi()
end

function XUiCharacterTowerMain:SetTxtTitle()
    local characterName = XFubenCharacterTowerConfigs.GetCharacterNameById(self.CharacterTowerId)
    self.TxtTitleStory.text = characterName
    self.TxtTitleFight.text = characterName
end

function XUiCharacterTowerMain:UpdateChapterTypeUi()
    local isStoryType = self.ChapterType == XFubenCharacterTowerConfigs.CharacterTowerChapterType.Story
    self.CharacterStoryBg.gameObject:SetActiveEx(isStoryType)
    self.TxtTitleStory.gameObject:SetActiveEx(isStoryType)
    self.BtnStory.gameObject:SetActiveEx(not isStoryType)

    local isChallengeType = self.ChapterType == XFubenCharacterTowerConfigs.CharacterTowerChapterType.Challenge
    self.CharacterFightBg.gameObject:SetActiveEx(isChallengeType)
    self.TxtTitleFight.gameObject:SetActiveEx(isChallengeType)
    self.BtnFight.gameObject:SetActiveEx(not isChallengeType)

    -- 红点
    if isStoryType then
        local hasRedPoint = self:CheckShowReddot(self.ChapterIdsInfo[XFubenCharacterTowerConfigs.CharacterTowerChapterType.Challenge])
        self.BtnFight:ShowReddot(hasRedPoint)
    end
    if isChallengeType then
        local hasRedPoint = self:CheckShowReddot(self.ChapterIdsInfo[XFubenCharacterTowerConfigs.CharacterTowerChapterType.Story])
        self.BtnStory:ShowReddot(hasRedPoint)
    end

    self:SetupDynamicTable()
end

function XUiCharacterTowerMain:CheckShowReddot(chapterIds)
    for _, chapterId in pairs(chapterIds) do
        local hasRedPoint = XDataCenter.CharacterTowerManager.CheckRedPointByChapterId(chapterId)
        if hasRedPoint then
            return true
        end
    end
    return false
end

function XUiCharacterTowerMain:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterList)
    self.DynamicTable:SetProxy(XUiGridCharacterTowerChapter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiCharacterTowerMain:SetupDynamicTable()
    self.DataList = self:GetChapterDataList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridCharacterTowerChapter
function XUiCharacterTowerMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnClose()
    end
end

---@return XCharacterTowerChapter
function XUiCharacterTowerMain:GetChapterViewModel(chapterId)
    return XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
end

function XUiCharacterTowerMain:CheckChapterInActivity(chapterId)
    local chapterViewModel = self:GetChapterViewModel(chapterId)
    return chapterViewModel:CheckChapterInActivity()
end

function XUiCharacterTowerMain:GetChapterDataList()
    local chapterIds = self.ChapterIdsInfo[self.ChapterType]
    if #chapterIds <= 1 then
        return chapterIds
    end

    table.sort(chapterIds, function(a, b)
        local inActivityA = self:CheckChapterInActivity(a)
        local inActivityB = self:CheckChapterInActivity(b)
        if inActivityA ~= inActivityB then
            return inActivityA
        end
        return a < b
    end)

    return chapterIds
end

function XUiCharacterTowerMain:OpenChapterUi(chapterId)
    XDataCenter.CharacterTowerManager.OpenChapterUi(chapterId, false)
end

function XUiCharacterTowerMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStory, self.OnBtnStoryClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
end

function XUiCharacterTowerMain:OnBtnBackClick()
    self:Close()
end

function XUiCharacterTowerMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiCharacterTowerMain:OnBtnStoryClick()
    self.ChapterType = XFubenCharacterTowerConfigs.CharacterTowerChapterType.Story
    self:UpdateChapterTypeUi()
    self:PlayAnimation("QieHuan")
end

function XUiCharacterTowerMain:OnBtnFightClick()
    self.ChapterType = XFubenCharacterTowerConfigs.CharacterTowerChapterType.Challenge
    self:UpdateChapterTypeUi()
    self:PlayAnimation("QieHuan")
end

return XUiCharacterTowerMain