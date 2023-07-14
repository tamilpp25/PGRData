local XUiTwoSideTowerMainLine = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerMainLine")
local XUiPanelTwoSideTowerRoadLine = require("XUi/XUiTwoSideTower/XUiPanelTwoSideTowerRoadLine")
local SWITCH_SOUND_CUE_ID = 1016
function XUiTwoSideTowerMainLine:OnStart(chapterId)
    self.ChapterId = chapterId
    self:Init()
    self:InitTimes()

    -- 战斗后在OnResume赋值
    -- 记录章节正逆向、节点正逆向翻转状态
    if self.IsPositiveDirection == nil then
        local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
        self.IsPositiveDirection = chapter:IsPositive()
    end
    if self.PointPositiveDic == nil then
        local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
        self.PointPositiveDic = chapter:GetPointPositiveDic()
    end
end

function XUiTwoSideTowerMainLine:OnDestroy()
    
end

function XUiTwoSideTowerMainLine:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()

    XDataCenter.TwoSideTowerManager.CheckOpenUiChapterSettle(self.ChapterId)
    XDataCenter.TwoSideTowerManager.CheckOpenUiChapterOverview(self.ChapterId)
end

function XUiTwoSideTowerMainLine:OnReleaseInst()
    local data = {}
    data.IsPositiveDirection = self.IsPositiveDirection
    data.PointPositiveDic = self.PointPositiveDic
    return data
end

function XUiTwoSideTowerMainLine:OnResume(data)
    self.IsPositiveDirection = data.IsPositiveDirection
    self.PointPositiveDic = data.PointPositiveDic
end

function XUiTwoSideTowerMainLine:OnGetEvents()
    return { XEventId.EVENT_TWO_SIDE_TOWER_POINT_SWEEP, XEventId.EVENT_TWO_SIDE_TOWER_FEATURE_FORBID }
end

function XUiTwoSideTowerMainLine:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_TWO_SIDE_TOWER_POINT_SWEEP then
        self:OnEventPointSweep(args[1])
    elseif evt == XEventId.EVENT_TWO_SIDE_TOWER_FEATURE_FORBID then
        self.RoadLinePanel:RefreshBuffList()
        self:RefreshScore()
    end
end

function XUiTwoSideTowerMainLine:Init()
    ---@type XTwoSideTowerChapter
    local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
    self.RoadLineObj = self.PanelChapter:LoadPrefab(chapter:GetFubenPrefab())
    self.RoadLinePanel = XUiPanelTwoSideTowerRoadLine.New(self.RoadLineObj, self.ChapterId, self)
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self:BindHelpBtn(self.BtnHelp, "TwoSideTower")
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.BtnOverview.CallBack = function()
        XLuaUiManager.Open("UiTwoSideTowerOverview", self.ChapterId)
    end

    self.BtnReset.CallBack = function()
        XUiManager.DialogTip(CS.XTextManager.GetText("TwoSideTowerResetTitle"), CS.XTextManager.GetText("TwoSideTowerResetContent"), XUiManager.DialogType.Normal, nil, function()
            XDataCenter.TwoSideTowerManager.ResetChapterRequest(self.ChapterId, function()
                self:OnChapterReset()
            end)
        end)
    end
end

function XUiTwoSideTowerMainLine:Refresh()
    self:RefreshTitle()
    self:RefreshScore()
    self:PlaySwitchAnim()
    -- 播放切换动画
    self.RoadLinePanel:PlaySwitchAnim()
    -- 刷新路线
    self.RoadLinePanel:Update(self.ChapterId)
end

-- 节点扫荡成功
function XUiTwoSideTowerMainLine:OnEventPointSweep(pointId)
    self:Refresh()
end

-- 章节重置完成
function XUiTwoSideTowerMainLine:OnChapterReset()
    self:Refresh()
end

-- 播放切换动画
function XUiTwoSideTowerMainLine:PlaySwitchAnim()
    self.Spine = self.SpineLoader:LoadSpinePrefab(self.SpineLoader.AssetUrl):GetComponent("SkeletonAnimation")
    local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
    if not self.IsPositiveDirection and chapter:IsPositive() then
        XScheduleManager.ScheduleOnce(function()
            XSoundManager.PlaySoundByType(SWITCH_SOUND_CUE_ID, XSoundManager.SoundType.Sound)
        end, 600)
        self.Spine.state:SetAnimation(0, "QieHuan", false)
        self.Spine.state:AddAnimation(0, "Bg01", true, 0)
        self.IsPositiveDirection = true

    elseif self.IsPositiveDirection and not chapter:IsPositive() then
        self:PlayAnimation("PanelTipEnable", function()
            XScheduleManager.ScheduleOnce(function()
                XSoundManager.PlaySoundByType(SWITCH_SOUND_CUE_ID, XSoundManager.SoundType.Sound)
            end, 800)
            self.Spine.state:SetAnimation(0, "QieHuan2", false)
            self.Spine.state:AddAnimation(0, "Bg02", true, 0)
            local cb
            cb = function(track)
                if track.Animation.Name == "Bg02" then
                    self:PlayAnimation("PanelSuccessEnable")
                    self.Spine.AnimationState:Complete('-', cb)
                end
            end
            self.Spine.AnimationState:Complete('+', cb)
            self.IsPositiveDirection = false
        end)
    else
        local animName = self.IsPositiveDirection and "Bg01" or "Bg02"
        self.Spine.state:SetAnimation(0, animName, true)
    end
end

-- 刷新标题
function XUiTwoSideTowerMainLine:RefreshTitle()
    ---@type XTwoSideTowerChapter
    local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
    local isPositive = chapter:IsPositive()
    self.TxtTitle.text = isPositive and CS.XTextManager.GetText("TwoSideTowerPositiveTitle") or CS.XTextManager.GetText("TwoSideTowerNegativeTitle")
end

-- 刷新积分
function XUiTwoSideTowerMainLine:RefreshScore()
    ---@type XTwoSideTowerChapter
    local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
    local maxScoreIcon = chapter:GetMaxChapterScoreIcon()
    local isShowMax = chapter:IsCleared()
    self.TxtHistory.gameObject:SetActiveEx(isShowMax)
    if isShowMax then
        self.RImgHistoryRank:SetRawImage(maxScoreIcon)
    end

    local curScoreIcon = chapter:GetChapterScoreIcon()
    self.RImgCurrentRank:SetRawImage(curScoreIcon)
end

function XUiTwoSideTowerMainLine:GetPointPositive(pointId)
    return self.PointPositiveDic[pointId] == true
end

function XUiTwoSideTowerMainLine:SetPointPositive(pointId, isPositive)
    self.PointPositiveDic[pointId] = isPositive
end

function XUiTwoSideTowerMainLine:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.TwoSideTowerManager.GetEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

return XUiTwoSideTowerMainLine
