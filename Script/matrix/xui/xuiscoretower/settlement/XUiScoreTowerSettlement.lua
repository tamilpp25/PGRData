---@class XScoreTowerSettleResult
---@field StageCfgId number
---@field ChapterId number
---@field TowerId number
---@field FloorId number
---@field Score number
---@field IsNew boolean
---@field StarIndex number[]
---@field CardIds number[]
---@field RobotIds number[]
---@field StarScore number[] 通关所需分数
---@field PassFightTime number 通关最长时间

local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridScoreTowerStagePlugin = require("XUi/XUiScoreTower/Popup/XUiGridScoreTowerStagePlugin")
local XUiGridScoreTowerCharacter = require("XUi/XUiScoreTower/Common/XUiGridScoreTowerCharacter")

---@class XUiScoreTowerSettlement : XLuaUi
---@field private _Control XScoreTowerControl
local XUiScoreTowerSettlement = XLuaUiManager.Register(XLuaUi, "UiScoreTowerSettlement")

function XUiScoreTowerSettlement:OnAwake()
    self:RegisterUiEvents()
    self.GridStageStar.gameObject:SetActiveEx(false)
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.GridPlugin.gameObject:SetActiveEx(false)
    self.PanelInformation.gameObject:SetActiveEx(false)
end

function XUiScoreTowerSettlement:OnStart(winData)
    self:SetAutoCloseInfo(XMVCA.XScoreTower:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        end
    end)

    self.WinData = winData
    ---@type XScoreTowerSettleResult
    self.ScoreTowerSettleResult = winData.SettleData.ScoreTowerSettleResult
    ---@type UiObject[]
    self.GridStageStarList = {}
    ---@type XUiGridScoreTowerCharacter[]
    self.GridStageCharacterList = {}
    self:InitDynamicTable()
    -- 动画间隔
    self.AnimInterval = self._Control:GetClientConfig("GridSettleStarAnimInterval", 1, true)
end

function XUiScoreTowerSettlement:OnEnable()
    self.Super.OnEnable(self)
    if not self.ScoreTowerSettleResult then
        XLog.Error("error: ScoreTowerSettleResult is nil")
        return
    end
    self.StageId = self.WinData.StageId
    self.ChapterId = self.ScoreTowerSettleResult.ChapterId or 0
    self.TowerId = self.ScoreTowerSettleResult.TowerId or 0
    self.FloorId = self.ScoreTowerSettleResult.FloorId or 0
    self.StageCfgId = self.ScoreTowerSettleResult.StageCfgId or 0
    if not XTool.IsNumberValid(self.ChapterId) or not XTool.IsNumberValid(self.TowerId) or not XTool.IsNumberValid(self.FloorId) or not XTool.IsNumberValid(self.StageCfgId) then
        XLog.Error("error: ChapterId or TowerId or FloorId or StageCfgId is invalid")
        return
    end
    self:RefreshCommonInfo()
    self:RefreshStageTarget()
    self:RefreshCharacterList()
    self:SetupDynamicTable()
    self:RefreshButton()
end

function XUiScoreTowerSettlement:OnGetLuaEvents()
    return {
        XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE,
        XEventId.EVENT_FIGHT_LOADINGFINISHED,
    }
end

function XUiScoreTowerSettlement:OnNotify(event, ...)
    if event == XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE or event == XEventId.EVENT_FIGHT_LOADINGFINISHED then
        self:OnBeginBattleAutoRemove()
    end
end

function XUiScoreTowerSettlement:OnDestroy()
    self.WinData = nil
    self.ScoreTowerSettleResult = nil
    self:StopGridAnimTime()
end

-- 刷新通用信息
function XUiScoreTowerSettlement:RefreshCommonInfo()
    -- 关卡名称
    self.TxtStoreyName.text = XMVCA.XFuben:GetStageName(self.StageId)
    -- boss立绘
    local bossIcon = self._Control:GetStageBossIcon(self.StageCfgId)
    local isIconEmpty = string.IsNilOrEmpty(bossIcon)
    self.RImgRole.gameObject:SetActiveEx(not isIconEmpty)
    if not isIconEmpty then
        self.RImgRole:SetRawImage(bossIcon)
    end
    -- 分数
    self.TxtScore.text = self.ScoreTowerSettleResult.Score or 0
    -- 是否新纪录
    self.TagNew.gameObject:SetActiveEx(self.ScoreTowerSettleResult.IsNew)
end

-- 获取boss目标或者星级描述
function XUiScoreTowerSettlement:GetBossTargetOrStarDesc(curScore, baseScore, curFightTime, baseFightTime, key)
    local timeColor = self._Control:GetStageBossTargetOrStarColor(curFightTime, baseFightTime, "StageSettlementDescColor")
    local scoreColor = self._Control:GetStageBossTargetOrStarColor(curScore, baseScore, "StageSettlementDescColor")
    return self._Control:GetStageBossTargetOrStarDesc(timeColor, curFightTime, scoreColor, curScore, key)
end

-- 刷新关卡目标
function XUiScoreTowerSettlement:RefreshStageTarget()
    -- 是否最终boss
    local isFinalBoss = self._Control:IsStageFinalBoss(self.StageCfgId)
    self.TxtTarget.gameObject:SetActiveEx(not isFinalBoss)
    self.RImageTarget.gameObject:SetActiveEx(not isFinalBoss)
    self.StageContent.gameObject:SetActiveEx(isFinalBoss)

    local curStarScores = self.ScoreTowerSettleResult.StarScore or {}
    local curFightTime = self.ScoreTowerSettleResult.PassFightTime or 0
    local baseFightTime = self._Control:GetStageBossFightTime(self.StageCfgId)
    if isFinalBoss then
        self:RefreshStar(curStarScores, curFightTime, baseFightTime)
        return
    end
    local bossScores = self._Control:GetStageBossFightScore(self.StageCfgId)
    local baseScore = bossScores[1] or 0
    local curScore = curStarScores[1] or 0
    self.TxtTarget.text = self:GetBossTargetOrStarDesc(curScore, baseScore, curFightTime, baseFightTime, "StageBossTargetDesc")
end

-- 刷新星级
function XUiScoreTowerSettlement:RefreshStar(curStarScores, curFightTime, baseFightTime)
    local starIndex = self.ScoreTowerSettleResult.StarIndex or {}
    local bossFightScore = self._Control:GetStageBossFightScore(self.StageCfgId)
    if XTool.IsTableEmpty(bossFightScore) then
        self.PanelTarget.gameObject:SetActiveEx(false)
        return
    end
    for index, score in pairs(bossFightScore) do
        local star = self.GridStageStarList[index]
        if not star then
            star = XUiHelper.Instantiate(self.GridStageStar, self.StageContent)
            self.GridStageStarList[index] = star
        end
        star.gameObject:SetActiveEx(true)
        local curScore = curStarScores[index] or 0
        local desc = self:GetBossTargetOrStarDesc(curScore, score, curFightTime, baseFightTime, "StageBossStarDesc")
        star:GetObject("TxtUnActive").text = desc
        star:GetObject("TxtActive").text = desc
        local isActivate = table.contains(starIndex, index)
        star:GetObject("PanelUnActive").gameObject:SetActiveEx(not isActivate)
        star:GetObject("PanelActive").gameObject:SetActiveEx(isActivate)
    end
    for i = #bossFightScore + 1, #self.GridStageStarList do
        self.GridStageStarList[i].gameObject:SetActiveEx(false)
    end
    -- 播放星级动画
    self:PlayStarEnableAnim(table.nums(bossFightScore))
end

function XUiScoreTowerSettlement:PlayStarEnableAnim(count)
    self:StopGridAnimTime()
    self:SetGridStageStarAlpha(0)
    local index = 1
    XLuaUiManager.SetMask(true)
    self._GridAnimTimeId = XScheduleManager.Schedule(function()
        local star = self.GridStageStarList[index]
        if star then
            local enableAnim = star:GetObject("GridStageStarEnable")
            if enableAnim then
                enableAnim:PlayTimelineAnimation()
            end
        end
        index = index + 1
    end, self.AnimInterval, count)
    -- 动画结束 动画间隔 * 星级数量 + 200ms(最后一个星级动画播放时间)
    XScheduleManager.ScheduleOnce(function()
        self:StopGridAnimTime()
        self:SetGridStageStarAlpha(1)
        XLuaUiManager.SetMask(false)
    end, self.AnimInterval * count + 200)
end

function XUiScoreTowerSettlement:StopGridAnimTime()
    if self._GridAnimTimeId then
        XScheduleManager.UnSchedule(self._GridAnimTimeId)
        self._GridAnimTimeId = nil
    end
end

function XUiScoreTowerSettlement:SetGridStageStarAlpha(alpha)
    for _, star in pairs(self.GridStageStarList) do
        local canvasGroup = star:GetObject("CanvasGroup")
        if canvasGroup then
            canvasGroup.alpha = alpha
        end
    end
end

-- 获取实体Id列表
function XUiScoreTowerSettlement:GetEntityIdList()
    local cardIds = self.ScoreTowerSettleResult.CardIds or {}
    local robotIds = self.ScoreTowerSettleResult.RobotIds or {}
    local entityIdList = { 0, 0, 0 }
    for i = 1, 3 do
        local id = 0
        if XTool.IsNumberValid(cardIds[i]) then
            id = cardIds[i]
        elseif XTool.IsNumberValid(robotIds[i]) then
            -- 如果机器人表没有配置角色Id，则不显示
            local characterId = XRobotManager.GetCharacterId(robotIds[i])
            if XTool.IsNumberValid(characterId) then
                id = robotIds[i]
            end
        end
        entityIdList[i] = id
    end
    return entityIdList
end

-- 刷新角色信息
function XUiScoreTowerSettlement:RefreshCharacterList()
    local entityIdList = self:GetEntityIdList()
    for index, entityId in ipairs(entityIdList) do
        local grid = self.GridStageCharacterList[index]
        if entityId > 0 then
            if not grid then
                local go = XUiHelper.Instantiate(self.GridCharacter, self.ListCharacter)
                grid = XUiGridScoreTowerCharacter.New(go, self)
                self.GridStageCharacterList[index] = grid
            end
            grid:Open()
            grid:SetHideTry(true)
            grid:Refresh(entityId)
        elseif grid then
            grid:Close()
        end
    end
end

function XUiScoreTowerSettlement:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ListPlugin)
    self.DynamicTable:SetProxy(XUiGridScoreTowerStagePlugin, self)
    self.DynamicTable:SetDelegate(self)
end

-- 刷新插件信息
function XUiScoreTowerSettlement:SetupDynamicTable()
    self.PluginIdList = self._Control:GetStageSelectedPlugIds(self.ChapterId, self.TowerId, self.StageCfgId)
    local isEmpty = XTool.IsTableEmpty(self.PluginIdList)
    self.PanelNone.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        return
    end
    self.DynamicTable:SetDataSource(self.PluginIdList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridScoreTowerStagePlugin
function XUiScoreTowerSettlement:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PluginIdList[index])
    end
end

-- 刷新按钮
function XUiScoreTowerSettlement:RefreshButton()
    local isFinalBoss = self._Control:IsStageFinalBoss(self.StageCfgId)
    local curStarScores = self.ScoreTowerSettleResult.StarScore or {}
    local currentScore = self.ScoreTowerSettleResult.Score or 0
    local targetScore = curStarScores[1] or 0
    local isPass = currentScore >= targetScore

    self.BtnAgain.gameObject:SetActiveEx(not isPass)
    self.BtnAdjust.gameObject:SetActiveEx(true)
    self.BtnNext.gameObject:SetActiveEx(not isFinalBoss and isPass)
    self.BtnSettlement.gameObject:SetActiveEx(isFinalBoss and isPass)

    local effectUrl = self._Control:GetClientConfig("StageSettlementTitleEffect", isPass and 1 or 2)
    if not string.IsNilOrEmpty(effectUrl) and self.RImageTitle then
        self.RImageTitle.gameObject:LoadPrefabEx(effectUrl)
    end
    if self.TxtTip then
        self.TxtTip.gameObject:SetActiveEx(not isPass)
    end
    if isPass then
        self:RefreshReward()
    end
end

-- 刷新奖励信息
function XUiScoreTowerSettlement:RefreshReward()
    local rewardId = self._Control:GetFloorPassRewardId(self.FloorId)
    if not XTool.IsNumberValid(rewardId) then
        self.PanelInformation.gameObject:SetActiveEx(false)
        return
    end

    local rewardList = XRewardManager.GetRewardList(rewardId)
    if XTool.IsTableEmpty(rewardList) then
        self.PanelInformation.gameObject:SetActiveEx(false)
        return
    end

    self.PanelInformation.gameObject:SetActiveEx(true)

    local reward = rewardList[1]
    local templateId = (reward.TemplateId and reward.TemplateId > 0) and reward.TemplateId or reward.Id
    local templateData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)

    self.TxtNum.text = reward.Count or 0
    local icon = templateData and templateData.Icon or ""
    self.RImgSerum.gameObject:SetActiveEx(not string.IsNilOrEmpty(icon))
    if not string.IsNilOrEmpty(icon) then
        self.RImgSerum:SetRawImage(icon)
    end
end

function XUiScoreTowerSettlement:OnBeginBattleAutoRemove()
    self:Remove()
end

function XUiScoreTowerSettlement:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnAgain, self.OnBtnAgainClick)
    self:RegisterClickEvent(self.BtnAdjust, self.OnBtnAdjustClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextClick)
    self:RegisterClickEvent(self.BtnSettlement, self.OnBtnSettlementClick)
end

-- 重新挑战
function XUiScoreTowerSettlement:OnBtnAgainClick()
    local beginData = XMVCA.XFuben:GetFightBeginData()
    local stageTeam = self._Control:GetStageTeam(self.ChapterId, self.TowerId, self.FloorId, self.StageCfgId)
    XMVCA.XScoreTower:EnterFight(self.StageId, stageTeam, beginData.IsHasAssist, beginData.ChallengeCount)
end

-- 调整阵容
function XUiScoreTowerSettlement:OnBtnAdjustClick()
    self:Close()
end

-- 下一层
function XUiScoreTowerSettlement:OnBtnNextClick()
    self._Control:BossStageSettleRequest(function()
        self:Close()
    end)
end

-- 结算
function XUiScoreTowerSettlement:OnBtnSettlementClick()
    self._Control:BossStageSettleRequest(function()
        local lastTowerId = self._Control:GetChapterLastTowerId(self.ChapterId)
        XLuaUiManager.Remove("UiScoreTowerStoreyDetail")
        if lastTowerId ~= self.TowerId then
            XLuaUiManager.PopThenOpen("UiScoreTowerChapterDetail", self.ChapterId)
        else
            self:Close()
        end
    end)
end

return XUiScoreTowerSettlement
