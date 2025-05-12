local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiScoreTowerChapterDetail : XLuaUi
---@field private _Control XScoreTowerControl
---@field PanelTab XUiButtonGroup
local XUiScoreTowerChapterDetail = XLuaUiManager.Register(XLuaUi, "UiScoreTowerChapterDetail")

function XUiScoreTowerChapterDetail:OnAwake()
    self:RegisterUiEvents()
    ---@type table<number, {BtnTab: XUiComponent.XUiButton, ListStar: UnityEngine.RectTransform, GridStar: UiObject, PanelScore: UnityEngine.RectTransform, TxtScore: UnityEngine.UI.Text}>
    self.TowerTabUiList = {
        [1] = {
            BtnTab = self.BtnTab1,
            ListStar = self.ListStar1,
            GridStar = self.GridStar1,
            PanelScore = self.PanelScore1,
            TxtScore = self.TxtScore1,
        },
        [2] = {
            BtnTab = self.BtnTab2,
            ListStar = self.ListStar2,
            GridStar = self.GridStar2,
            PanelScore = self.PanelScore2,
            TxtScore = self.TxtScore2,
        }
    }
    -- 隐藏Tab
    for _, tabUi in pairs(self.TowerTabUiList) do
        tabUi.BtnTab.gameObject:SetActiveEx(false)
        tabUi.ListStar.gameObject:SetActiveEx(false)
        tabUi.GridStar.gameObject:SetActiveEx(false)
        tabUi.PanelScore.gameObject:SetActiveEx(false)
    end
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridCondition.gameObject:SetActiveEx(false)
    self.GridBuffDetail.gameObject:SetActiveEx(false)
    self.BtnClose.gameObject:SetActiveEx(false)
end

function XUiScoreTowerChapterDetail:OnStart(chapterId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.ScoreTowerCoin)
    self:SetAutoCloseInfo(XMVCA.XScoreTower:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        end
    end)

    self.ChapterId = chapterId
    self.TowerIds = {}
    ---@type XScoreTowerTowerTeam
    self.TowerTeam = nil
    ---@type table<number, UiObject[]>
    self.GridTowerStarList = {}
    ---@type XUiGridScoreTowerCharacter[]
    self.GridTowerCharacterList = {}
    ---@type UiObject[]
    self.GridBuffList = {}
    ---@type UiObject[]
    self.GridConditionList = {}
    ---@type UiObject[]
    self.GridBuffDetailList = {}
    -- 最终Boss关卡Id
    self.FinalBossStageId = 0

    self.CurTabSelectIndex = -1
    self.CurSelectTowerId = 0
    -- 是否需要刷新
    self.IsNeedRefresh = false
    -- 初始化Tab
    self:InitTabGroup()
    -- 记录章节点击
    self._Control:RecordChapterClick(self.ChapterId)
end

function XUiScoreTowerChapterDetail:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshTabInfo()
    self.PanelTab:SelectIndex(self:GetTabDefaultIndex())
    self:RefreshTalentBtn()
    self:RefreshRedPoint()
    self.IsNeedRefresh = false
end

function XUiScoreTowerChapterDetail:OnDisable()
    self.Super.OnDisable(self)
    self.IsNeedRefresh = true
end

function XUiScoreTowerChapterDetail:OnDestroy()
    self.TowerTeam = nil
end

function XUiScoreTowerChapterDetail:GetChapterId()
    return self.ChapterId
end

function XUiScoreTowerChapterDetail:InitTabGroup()
    self.TowerIds = self._Control:GetChapterTowerIds(self.ChapterId)
    if XTool.IsTableEmpty(self.TowerIds) then
        self.PanelTab.gameObject:SetActiveEx(false)
        return
    end
    local btnGroup = {}
    for index, towerId in ipairs(self.TowerIds) do
        local btn = self.TowerTabUiList[index].BtnTab
        if btn then
            btn.gameObject:SetActiveEx(true)
            btn:SetNameByGroup(0, self._Control:GetTowerName(towerId))
            btnGroup[index] = btn
        end
    end
    self.PanelTab:Init(btnGroup, function(index) self:SwitchTowerTab(index) end)
end

function XUiScoreTowerChapterDetail:SwitchTowerTab(index)
    if self.CurTabSelectIndex == index and not self.IsNeedRefresh then
        return
    end
    local towerId = self.TowerIds[index]
    -- 判断是否解锁
    local isUnlock, desc = self._Control:IsTowerUnlock(self.ChapterId, towerId)
    if not isUnlock then
        XUiManager.TipMsg(desc)
        return
    end
    self.CurTabSelectIndex = index
    self.CurSelectTowerId = towerId
    self:RefreshTower()
    -- 播放切换动画
    self:PlayAnimation("Refresh")
end

-- 获取默认选中Tab
function XUiScoreTowerChapterDetail:GetTabDefaultIndex()
    if self.CurTabSelectIndex > 0 then
        return self.CurTabSelectIndex
    end
    local lastUnlockedIndex = 1
    for index, towerId in ipairs(self.TowerIds) do
        local isUnlock, _ = self._Control:IsTowerUnlock(self.ChapterId, towerId)
        if isUnlock then
            lastUnlockedIndex = index
        end
    end
    return lastUnlockedIndex
end

-- 刷新Tab信息
function XUiScoreTowerChapterDetail:RefreshTabInfo()
    if XTool.IsTableEmpty(self.TowerIds) then
        return
    end
    local lastTowerId = self._Control:GetChapterLastTowerId(self.ChapterId)
    for index, towerId in ipairs(self.TowerIds) do
        local isLastTower = towerId == lastTowerId
        self:RefreshTowerStar(index, towerId, isLastTower)
        self:RefreshTowerState(index, towerId, isLastTower)
    end
end

-- 刷新塔星级
function XUiScoreTowerChapterDetail:RefreshTowerStar(index, towerId, isLastTower)
    local tabUi = self.TowerTabUiList[index]
    if not tabUi then
        return
    end
    local listStar, gridStar = tabUi.ListStar, tabUi.GridStar
    if not listStar or not gridStar then
        return
    end
    listStar.gameObject:SetActiveEx(isLastTower)
    if not isLastTower then
        return
    end

    local curStar = self._Control:GetTowerCurStar(self.ChapterId, towerId)
    local totalStar = self._Control:GetTowerTotalStar(towerId)
    self.GridTowerStarList[index] = self.GridTowerStarList[index] or {}
    for i = 1, totalStar do
        local star = self.GridTowerStarList[index][i]
        if not star then
            star = XUiHelper.Instantiate(gridStar, listStar)
            self.GridTowerStarList[index][i] = star
        end
        star.gameObject:SetActiveEx(true)
        star:GetObject("ImgStarOff").gameObject:SetActiveEx(i > curStar)
        star:GetObject("ImgStarOn").gameObject:SetActiveEx(i <= curStar)
    end
    for i = totalStar + 1, #self.GridTowerStarList[index] do
        self.GridTowerStarList[index][i].gameObject:SetActiveEx(false)
    end
end

-- 刷新塔状态
function XUiScoreTowerChapterDetail:RefreshTowerState(index, towerId, isLastTower)
    local tabUi = self.TowerTabUiList[index]
    if not tabUi then
        return
    end
    -- 判断是否解锁
    local btn = tabUi.BtnTab
    local isUnlock, _ = self._Control:IsTowerUnlock(self.ChapterId, towerId)
    btn:SetDisable(not isUnlock)
    -- 显示分数
    local panelScore = tabUi.PanelScore
    if panelScore then
        local isShowScore = isLastTower and isUnlock
        panelScore.gameObject:SetActiveEx(isShowScore)
        if isShowScore and tabUi.TxtScore then
            tabUi.TxtScore.text = self._Control:GetTowerCurPoint(self.ChapterId, towerId)
        end
    end
end

-- 刷新塔
function XUiScoreTowerChapterDetail:RefreshTower()
    self.TowerTeam = self._Control:GetTowerTeam(self.ChapterId, self.CurSelectTowerId)
    self:RefreshTowerCharacters()
    self:RefreshBossPreview()
    self:RefreshStartBtn()
end

-- 刷新塔队伍
function XUiScoreTowerChapterDetail:RefreshTowerCharacters()
    local limitCount = self._Control:GetTowerCharacterNum(self.CurSelectTowerId)
    for index = 1, limitCount do
        local grid = self.GridTowerCharacterList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCharacter, self.ListCharacter)
            grid = require("XUi/XUiScoreTower/Common/XUiGridScoreTowerCharacter").New(go, self, handler(self, self.OnGridCharacterClick))
            self.GridTowerCharacterList[index] = grid
        end
        grid:Open()
        local entityId = self.TowerTeam:GetEntityIdByTeamPos(index) or 0
        grid:Refresh(entityId, index)
        grid:SetIsRecommend(self._Control:IsTowerSuggestTag(self.CurSelectTowerId, entityId))
    end
    for index = limitCount + 1, #self.GridTowerCharacterList do
        self.GridTowerCharacterList[index]:Close()
    end
end

-- 点击角色
---@param entityId number 角色Id
---@param index number 角色位置
function XUiScoreTowerChapterDetail:OnGridCharacterClick(entityId, index)
    -- 验证编队数据
    if entityId > 0 then
        local isTeam, pos = self.TowerTeam:GetEntityIdIsInTeam(entityId)
        if not isTeam or pos ~= index then
            XLog.Error(string.format("编队数据异常, 请检查，角色Id:%s ，位置: %s", entityId, index))
        end
    end
    -- 打开角色详情
    XLuaUiManager.Open("UiBattleRoomRoleDetail",
        nil,
        self.TowerTeam,
        index,
        require("XUi/XUiScoreTower/BattleRoom/XUiScoreTowerTowerBattleRoomRoleDetail"))
end

-- 刷新Boss预览
function XUiScoreTowerChapterDetail:RefreshBossPreview()
    self.FinalBossStageId = self._Control:GetFinalBossStageIdByTowerId(self.CurSelectTowerId)
    if not XTool.IsNumberValid(self.FinalBossStageId) then
        XLog.Error(string.format("获取最终Boss关卡Id失败, 塔Id: %s", self.CurSelectTowerId))
        return
    end
    self:RefreshBossIcon()
    self:RefreshBuff()
    self:RefreshTowerRecommend()
end

-- 刷新Boss图标
function XUiScoreTowerChapterDetail:RefreshBossIcon()
    local bossIcon = self._Control:GetStageBossIcon(self.FinalBossStageId)
    local isIconEmpty = string.IsNilOrEmpty(bossIcon)
    self.RImgBoss.gameObject:SetActiveEx(not isIconEmpty)
    if not isIconEmpty then
        self.RImgBoss:SetRawImage(bossIcon)
    end
end

-- 刷新关卡词缀
function XUiScoreTowerChapterDetail:RefreshBuff()
    local bossAffixList = self._Control:GetStageBossAffixEvent(self.FinalBossStageId)
    if XTool.IsTableEmpty(bossAffixList) then
        self.ListBuff.gameObject:SetActiveEx(false)
        return
    end
    self.ListBuff.gameObject:SetActiveEx(true)
    for index, affixId in pairs(bossAffixList) do
        local grid = self.GridBuffList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridBuff, self.ListBuff)
            self.GridBuffList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local affixIcon = self._Control:GetFightEventIcon(affixId)
        if not string.IsNilOrEmpty(affixIcon) then
            grid:GetObject("RImgBuff"):SetRawImage(affixIcon)
        end
        grid:GetObject("BtnBuff").CallBack = function() self:OnBuffClick() end
    end
    for index = #bossAffixList + 1, #self.GridBuffList do
        self.GridBuffList[index].gameObject:SetActiveEx(false)
    end
end

-- 点击词缀
function XUiScoreTowerChapterDetail:OnBuffClick()
    self.BubbleBuffDetail.gameObject:SetActiveEx(true)
    self:RefreshBuffDetail()
    self.BtnClose.gameObject:SetActiveEx(true)
end

-- 刷新词缀详情
function XUiScoreTowerChapterDetail:RefreshBuffDetail()
    local bossAffixList = self._Control:GetStageBossAffixEvent(self.FinalBossStageId)
    if XTool.IsTableEmpty(bossAffixList) then
        return
    end
    for index, affixId in pairs(bossAffixList) do
        local grid = self.GridBuffDetailList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridBuffDetail, self.BubbleBuffDetail)
            self.GridBuffDetailList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local icon = self._Control:GetFightEventIcon(affixId)
        if not string.IsNilOrEmpty(icon) then
            grid:GetObject("RImgBuff"):SetRawImage(icon)
        end
        grid:GetObject("TxtTitle").text = self._Control:GetFightEventName(affixId)
        grid:GetObject("TxtDetail").text = self._Control:GetFightEventDesc(affixId)
    end
    for index = #bossAffixList + 1, #self.GridBuffDetailList do
        self.GridBuffDetailList[index].gameObject:SetActiveEx(false)
    end
end

-- 刷新塔层推荐
function XUiScoreTowerChapterDetail:RefreshTowerRecommend()
    local suggestTagTypes = self._Control:GetTowerSuggestTagType(self.CurSelectTowerId)
    local suggestTagCounts = self._Control:GetTowerSuggestTagCount(self.CurSelectTowerId)
    if XTool.IsTableEmpty(suggestTagTypes) then
        self.ListCondition.gameObject:SetActiveEx(false)
        return
    end
    self.ListCondition.gameObject:SetActiveEx(true)
    for index, tagId in pairs(suggestTagTypes) do
        local grid = self.GridConditionList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridCondition, self.ListCondition)
            self.GridConditionList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local tagIcon = self._Control:GetTagIcon(tagId)
        if not string.IsNilOrEmpty(tagIcon) then
            grid:GetObject("ImgIcon"):SetSprite(tagIcon)
        end
        grid:GetObject("TxtDetail").text = self._Control:GetTagDesc(tagId)
        local count = suggestTagCounts[index] or 0
        grid:GetObject("TxtNum").text = string.format("x%s", count)
        grid:GetObject("PanelComplete").gameObject:SetActiveEx(self:CheckRecommendCountMeet(tagId, count))
    end
    for index = #suggestTagTypes + 1, #self.GridConditionList do
        self.GridConditionList[index].gameObject:SetActiveEx(false)
    end
end

-- 检查推荐Tag数量是否满足
function XUiScoreTowerChapterDetail:CheckRecommendCountMeet(tagId, targetCount)
    local allCharacterIds = self.TowerTeam:GetAllCharacterIds()
    if XTool.IsTableEmpty(allCharacterIds) then
        return false
    end
    local count = 0
    for _, characterId in pairs(allCharacterIds) do
        local tagIds = self._Control:GetCharacterTagList(characterId)
        if table.contains(tagIds, tagId) then
            count = count + 1
            if count >= targetCount then
                return true
            end
        end
    end
    return false
end

-- 刷新开启按钮
function XUiScoreTowerChapterDetail:RefreshStartBtn()
    local isFull = self.TowerTeam:GetIsFullMember()
    self.BtnStart:SetDisable(not isFull)
end

-- 刷新天赋按钮
function XUiScoreTowerChapterDetail:RefreshTalentBtn()
    local isUnlock, _ = self._Control:IsStrengthenUnlock()
    self.BtnTalent:SetDisable(not isUnlock)
end

-- 刷新红点
function XUiScoreTowerChapterDetail:RefreshRedPoint()
    -- 天赋按钮红点
    local isShowTalentRedPoint = self._Control:IsShowStrengthenRedPoint()
    self.BtnTalent:ShowReddot(isShowTalentRedPoint)
end

function XUiScoreTowerChapterDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnFormation, self.OnBtnFormationClick)
    self:RegisterClickEvent(self.BtnQuicklySelect, self.OnBtnQuicklySelectClick)
    self:RegisterClickEvent(self.BtnTalent, self.OnBtnTalentClick)
    self:RegisterClickEvent(self.BtnStart, self.OnBtnStartClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiScoreTowerChapterDetail:OnBtnBackClick()
    self:Close()
end

function XUiScoreTowerChapterDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 快速编队按钮
function XUiScoreTowerChapterDetail:OnBtnFormationClick()
    XLuaUiManager.Open("UiScoreTowerPopupQuicklySelect", self.ChapterId, self.CurSelectTowerId, self.TowerTeam, function()
        self:RefreshTowerCharacters()
        self:RefreshTowerRecommend()
        self:RefreshStartBtn()
    end)
end

-- 一键上阵按钮
function XUiScoreTowerChapterDetail:OnBtnQuicklySelectClick()
    local suggestEntityIds = self._Control:GetTowerSuggestEntityIdIds(self.ChapterId, self.CurSelectTowerId)
    if XTool.IsTableEmpty(suggestEntityIds) then
        XUiManager.TipMsg(self._Control:GetClientConfig("TowerSuggestCharacterEmpty"))
        return
    end
    self.TowerTeam:OneKeyAddTowerEntityIds(suggestEntityIds)
    self:RefreshTowerCharacters()
    self:RefreshTowerRecommend()
    self:RefreshStartBtn()
end

-- 天赋按钮
function XUiScoreTowerChapterDetail:OnBtnTalentClick()
    local isUnlock, unlockTips = self._Control:IsStrengthenUnlock()
    if not isUnlock then
        XUiManager.TipMsg(unlockTips)
        return
    end
    XLuaUiManager.Open("UiScoreTowerTalent")
end

-- 开启按钮
function XUiScoreTowerChapterDetail:OnBtnStartClick()
    if not XTool.IsNumberValid(self.ChapterId) or not XTool.IsNumberValid(self.CurSelectTowerId) then
        return
    end
    if not self.TowerTeam:GetIsFullMember() then
        XUiManager.TipMsg(self._Control:GetClientConfig("TowerTeamMemberNotEnough"))
        return
    end
    self._Control:OpenTowerRequest(self.CurSelectTowerId, self.TowerTeam:GetCharacterInfos(), function()
        XLuaUiManager.PopThenOpen("UiScoreTowerStoreyDetail", self.ChapterId, self.CurSelectTowerId)
    end)
end

-- 关闭按钮
function XUiScoreTowerChapterDetail:OnBtnCloseClick()
    self.BtnClose.gameObject:SetActiveEx(false)
    self.BubbleBuffDetail.gameObject:SetActiveEx(false)
end

return XUiScoreTowerChapterDetail
