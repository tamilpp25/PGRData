local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiFubenBossSingleRankMyBossRank = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleRank/XUiFubenBossSingleRankMyBossRank")
local XUiFubenBossSingleRankGridBossRank = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleRank/XUiFubenBossSingleRankGridBossRank")
local XUiButton = require("XUi/XUiCommon/XUiButton")

---@class XUiFubenBossSingleRank : XLuaUi
---@field PanelAsset UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field GridTag XUiComponent.XUiButton
---@field GridBuffTag XUiComponent.XUiButton
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
local XUiFubenBossSingleRank = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleRank")

-- region 生命周期
function XUiFubenBossSingleRank:OnAwake()
    local bossSingleData = self._Control:GetBossSingleData()

    self._CurrentRankData = nil
    self._Timer = nil
    self._CurrentBossId = nil
    self._BossSingleData = bossSingleData
    ---@type XUiButtonLua[]
    self._TagList = {}
    self._TextScrollingList = {}
    ---@type XUiFubenBossSingleRankMyBossRank
    self.PanelMyBossRankUi = XUiFubenBossSingleRankMyBossRank.New(self.PanelMyBossRank, self)
    self:_RegisterButtonClicks()
end

---@param rankData XBossSingleRankData
function XUiFubenBossSingleRank:OnStart(rankData, bossId)
    local index = bossId and self._BossSingleData:GetBossIndexByBossId(bossId) + 1 or 1

    self._CurrentBossId = bossId
    self._CurrentRankData = rankData

    self:_InitDynamicTable()
    self:_InitPanelTags(index)
    self:_InitUi()
    self.BtnRankReward.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleRank:OnEnable()
    self:_RefreshDynamicTable()
    self:_RefreshTimeDesc()
    self:_RefreshResetTime()
    self:_RefreshTimer()
    self:_RegisterEventListeners()
end

function XUiFubenBossSingleRank:OnDisable()
    self:_RemoveTimer()
    self:_RemoveEventListeners()
    self:_RemoveAllScrolling()
end

-- endregion

-- region 按钮事件

function XUiFubenBossSingleRank:OnTagGroupClick(index)
    local levelType = self._BossSingleData:GetBossSingleLevelType()

    if index == 1 then
        self._CurrentBossId = nil
        XMVCA.XFubenBossSingle:RequestRankData(function(rankData)
            if not rankData then
                return
            end

            self._CurrentRankData = rankData
            self:_RefreshDynamicTable()
            self:_RefreshResetTime()
            self.PanelMyBossRankUi:Refresh(rankData)
            self:_RefreshTimer()
        end, levelType)
    else
        local bossId = self._BossSingleData:GetBossSingleBossIdByIndex(index - 1)

        self._CurrentBossId = bossId
        XMVCA.XFubenBossSingle:RequestBossRankData(function(rankData)
            if not rankData then
                return
            end

            self._CurrentRankData = rankData
            self:_RefreshDynamicTable()
            self:_RefreshResetTime()
            self.PanelMyBossRankUi:Refresh(rankData, bossId, false)
            self:_RefreshTimer()
        end, levelType, bossId)
    end
end

---@param grid XUiFubenBossSingleRankGridBossRank
function XUiFubenBossSingleRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:Refresh(data, self._CurrentBossId ~= nil, false)
    end
end

function XUiFubenBossSingleRank:OnActivityEnd()
    self._Control:OnActivityEnd()
end

-- endregion

-- region 私有方法

function XUiFubenBossSingleRank:_RegisterButtonClicks()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "BossSingle")
end

function XUiFubenBossSingleRank:_RegisterEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingleRank:_RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingleRank:_InitPanelTags(selectIndex)
    local bossList = self._BossSingleData:GetBossSingleBossList()
    local groupList = {}
    local tagCount = #bossList + 1
    local container = self.PanelTags.transform

    self._TagList = {}
    self:_RemoveAllScrolling()
    for index = 1, tagCount do
        local button = XUiHelper.Instantiate(self.GridTag, container)
        local scrollingGroup = button.transform:GetComponent(typeof(CS.XUiComponent.XUiTextScrollingGroup))
        ---@type XUiButtonLua
        local uiButton = XUiButton.New(button)

        self._TagList[index] = uiButton
        self._TextScrollingList[index] = scrollingGroup
        if index == 1 then
            local levelType = self._BossSingleData:GetBossSingleLevelType()
            local levelIcon = XUiHelper.TryGetComponent(button.transform, "RImgIcon", "RawImage")
            local bossIcon = XUiHelper.TryGetComponent(button.transform, "RImgBossRole", "RawImage")

            button:SetNameByGroup(1, self._Control:GetRankLevelRangeDescByType(levelType))
            scrollingGroup:Init(self._Control:GetRankLevelNameByType(levelType))
            levelIcon:SetRawImage(self._Control:GetRankLevelIconByType(levelType))
            bossIcon.gameObject:SetActiveEx(false)
        else
            local bossId = bossList[index - 1]
            local levelIcon = XUiHelper.TryGetComponent(button.transform, "RImgIcon", "RawImage")
            local bossIcon = XUiHelper.TryGetComponent(button.transform, "RImgBossRole", "RawImage")

            scrollingGroup:Init(self._Control:GetBossName(bossId))
            uiButton:SetActive("PanelTxt/TxtLv", false)
            levelIcon.gameObject:SetActiveEx(false)
            bossIcon:SetRawImage(self._Control:GetBossRankIcon(bossId))
        end

        scrollingGroup:PlayAll()
        table.insert(groupList, button)
    end

    self.PanelTags:Init(groupList, Handler(self, self.OnTagGroupClick))
    self.PanelTags:SelectIndex(selectIndex)
    self.GridBuffTag.gameObject:SetActiveEx(false)
    self.GridTag.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleRank:_InitUi()
    local root = self.UiModelGo.transform
    local imgEffect = root:FindTransform("ImgEffectHuanren")
    local imgEffectHide = root:FindTransform("ImgEffectHuanren1")

    if imgEffect then
        imgEffect.gameObject:SetActiveEx(false)
    end
    if imgEffectHide then
        imgEffectHide.gameObject:SetActiveEx(false)
    end
    self.BtnRankReward.gameObject:SetActiveEx(false)
    self.GridBossRank.gameObject:SetActiveEx(false)

    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenBossSingleRank:_InitDynamicTable()
    local levelType = self._BossSingleData:GetBossSingleLevelType()
    
    self._DynamicTable = XDynamicTableNormal.New(self.BossRankList)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiFubenBossSingleRankGridBossRank, self, levelType)
end

function XUiFubenBossSingleRank:_RefreshTimer()
    self:_RemoveTimer()

    self._Timer = XScheduleManager.ScheduleForever(Handler(self, self._RefreshResetTime), XScheduleManager.SECOND)
end

function XUiFubenBossSingleRank:_RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiFubenBossSingleRank:_RefreshDynamicTable()
    if self._CurrentRankData:GetIsRankEmpty() then
        self.BossRankList.gameObject:SetActiveEx(false)
        self.PanelNoRank.gameObject:SetActiveEx(true)
        self.PanelMyBossRankUi:Close()
    else
        self.BossRankList.gameObject:SetActiveEx(true)
        self.PanelNoRank.gameObject:SetActiveEx(false)
        self.PanelMyBossRankUi:Open()
        self._DynamicTable:SetDataSource(self._CurrentRankData:GetRankList())
        self._DynamicTable:ReloadDataASync(1)
    end
end

function XUiFubenBossSingleRank:_RefreshResetTime()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local leftTime = self._CurrentRankData:GetLeftTime()

    leftTime = leftTime - 1
    if leftTime <= 0 then
        local dataTime = XUiHelper.GetTime(0)

        self.TxtCurTime.text = XUiHelper.GetText("BossSingleLeftTime", dataTime)
        self:_RemoveTimer()
    else
        local dataTime = XUiHelper.GetTime(leftTime)

        self.TxtCurTime.text = XUiHelper.GetText("BossSingleLeftTime", dataTime)
    end
end

function XUiFubenBossSingleRank:_RefreshTimeDesc()
    local textKey = "BossSingleLeftTimeIos"
    local platform = self._BossSingleData:GetBossSingleRankPlatform()

    if platform == XEnumConst.BossSingle.Platform.Win then
        textKey = "BossSingleLeftTimeWin"
    elseif platform == XEnumConst.BossSingle.Platform.Android then
        textKey = "BossSingleLeftTimeAndroid"
    elseif platform == XEnumConst.BossSingle.Platform.IOS then
        textKey = "BossSingleLeftTimeIos"
    elseif platform == XEnumConst.BossSingle.Platform.All then
        textKey = "BossSingleLeftTimeAll"
    end

    self.TxtIos.text = XUiHelper.GetText(textKey)
end

function XUiFubenBossSingleRank:_RemoveAllScrolling()
    for _, scrolling in pairs(self._TextScrollingList) do
        scrolling:StopAll()
    end
    self._TextScrollingList = {}
end

-- endregion

return XUiFubenBossSingleRank
