local XUiFubenBossSingleRank = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleRank/XUiFubenBossSingleRank")
local XUiButton = require("XUi/XUiCommon/XUiButton")

---@class XUiFubenBossSingleChallengeRank : XUiFubenBossSingleRank
---@field PanelAsset UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field GridTag UnityEngine.RectTransform
---@field PanelTags XUiButtonGroup
---@field TxtIos UnityEngine.UI.Text
---@field TextAndroid UnityEngine.UI.Text
---@field TxtCurTime UnityEngine.UI.Text
---@field BtnRankReward XUiComponent.XUiButton
---@field PanelMyBossRank UnityEngine.RectTransform
---@field PanelNoRank UnityEngine.RectTransform
---@field BossRankList UnityEngine.RectTransform
---@field GridBossRank UnityEngine.RectTransform
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleChallengeRank = XLuaUiManager.Register(XUiFubenBossSingleRank, "UiFubenBossSingleChallengeRank")

-- region 生命周期

---@param rankData XBossSingleRankData
function XUiFubenBossSingleChallengeRank:OnStart(rankData, stageId)
    local challengeData = self._Control:GetBossSingleChallengeData()
    local index = challengeData:GetFeatureIndexByStageId(stageId) + 1

    self._ChallengeData = challengeData
    self._CurrentStageId = stageId
    self._CurrentRankData = rankData

    self:_InitDynamicTable()
    self:_InitPanelTags(index)
    self:_InitUi()
    self.BtnRankReward.gameObject:SetActiveEx(true)
end

-- endregion

-- region 按钮事件

function XUiFubenBossSingleChallengeRank:OnBtnRankRewardClick()
    self._Control:OpenChallengeRankRewardUi()
end

function XUiFubenBossSingleChallengeRank:OnTagGroupClick(index)
    if index == 1 then
        self._CurrentStageId = nil
    else
        self._CurrentStageId = self._ChallengeData:GetStageIdByIndex(index - 1)
    end
    
    XMVCA.XFubenBossSingle:RequestChallengeRankData(function(rankData)
        if not rankData then
            return
        end

        self._CurrentRankData = rankData
        self:_RefreshDynamicTable()
        self:_RefreshResetTime()
        self.PanelMyBossRankUi:Refresh(rankData, self._CurrentStageId, true)
        self:_RefreshTimer()
    end, self._CurrentStageId)
end

---@param grid XUiFubenBossSingleRankGridBossRank
function XUiFubenBossSingleChallengeRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(data, self._CurrentStageId ~= nil, true)
    end
end

-- endregion

-- region 私有方法

function XUiFubenBossSingleChallengeRank:_RegisterButtonClicks()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "BossSingle")
    self:RegisterClickEvent(self.BtnRankReward, self.OnBtnRankRewardClick, true)
end

function XUiFubenBossSingleChallengeRank:_InitPanelTags(selectIndex)
    local groupList = {}
    local tagCount = self._ChallengeData:GetFeatureCount() + 1
    local container = self.PanelTags.transform

    self._TagList = {}
    self:_RemoveAllScrolling()
    for index = 1, tagCount do
        local button = XUiHelper.Instantiate(self.GridBuffTag, container)
        ---@type XUiButtonLua
        local uiButton = XUiButton.New(button)
        local levelIcon = XUiHelper.TryGetComponent(button.transform, "ImgIcon", "RawImage")
        
        self._TagList[index] = uiButton
        if index == 1 then
            local levelType = self._BossSingleData:GetBossSingleChallengeLevelType()
            
            button:SetNameByGroup(0, self._Control:GetChallengeRankLevelNameByType(levelType))
            uiButton:SetActive("PanelTxt/TxtLv", false)
            uiButton:SetActive("RImgBuffBoss", false)
            button:SetRawImage(self._Control:GetChallengeRankLevelIconByType(levelType))
            levelIcon.gameObject:SetActiveEx(true)
            levelIcon:SetRawImage(self._Control:GetChallengeRankLevelIconByType(levelType))
        else
            local feature = self._ChallengeData:GetFeatureByIndex(index - 1)

            button:SetNameByGroup(0, feature:GetName())
            uiButton:SetActive("PanelTxt/TxtLv", false)
            button:SetRawImage(feature:GetIcon())
            levelIcon.gameObject:SetActiveEx(false)
        end

        table.insert(groupList, button)
    end

    self.PanelTags:Init(groupList, Handler(self, self.OnTagGroupClick))
    self.PanelTags:SelectIndex(selectIndex)
    self.GridBuffTag.gameObject:SetActiveEx(false)
    self.GridTag.gameObject:SetActiveEx(false)
end

-- endregion

return XUiFubenBossSingleChallengeRank
