local XUiPokemonMain = XLuaUiManager.Register(XLuaUi, "UiPokemonMain")
local XUiGridPokemonStagePage = require("XUi/XUiPokemon/XUiGridPokemonStagePage")
local XUiGridPokemonStage = require("XUi/XUiPokemon/XUiGridPokemonStage")

local SWITCH_EFFECT_TIME = 2 * XScheduleManager.SECOND

function XUiPokemonMain:OnStart()
    local helpId = XPokemonConfigs.GetHelpId()
    self.BtnHelp.gameObject:SetActiveEx(helpId > 0)
    self:RegisterButtonEvent()
    self.ImpDynamicTable.GridSize = CS.UnityEngine.Vector2(self.ViewPort.rect.width, self.ViewPort.rect.height)
    self:InitDynamicTable()
    self.InfinityStage = XUiGridPokemonStage.New(self.BtnInfinity, 0, function(stageId)
        self:OnOpenStageDetail(stageId)
    end)
    self.IsInfinity = false
    local stages = XDataCenter.PokemonManager.GetPassedCount() + 1
    local pages = math.ceil(stages / XPokemonConfigs.PerPageCount)
    self.LastIndex = pages - 1
    self.StartTime, self.EndTime = XDataCenter.PokemonManager.GetCurrActivityTime()
    self.TimeHandler = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtProgress) then
            self:StopTimer()
            return
        end
        local currentTime = XTime.GetServerNowTimestamp()
        if currentTime > self.EndTime then
            XDataCenter.PokemonManager.OnActivityEnd()
            return
        end
        self:RefreshTimeSupplyText()
        self:RefreshTimeSupplyProgress()
        --self:RefreshNextRecoverTime()
    end, 1000, 0)
    self:RefreshTimeSupplyText()
    self:RefreshTimeSupplyProgress()
    self:RefreshChapterStageBuff()
    self:RefreshSkipPanel()
    if self.Background then
        self.Background:SetRawImage(XDataCenter.PokemonManager.GetChapterScrollBg())
    end
    --self:RefreshNextRecoverTime()
    XRedPointManager.AddRedPointEvent(self.ImgRedPoint, self.CheckTimeSupplyRedPoint, self, { XRedPointConditions.Types.CONDITION_POKEMON_TIME_SUPPLY_RED })
end

function XUiPokemonMain:OnEnable()
    XRedPointManager.CheckOnce(self.CheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_POKEMON_TASK_RED })
    self:RefreshSkipStageTimes()
    self:SetupDynamicTable()
    --self:SwitchToInfinity()
    --self.InfinityStage:Refresh(XDataCenter.PokemonManager.GetNextStage())
    --self:RefreshRemainingTimes()
    --新怪物弹窗
    XDataCenter.PokemonManager.CheckNewMonsterIds()
end

function XUiPokemonMain:OnDisable()
    self.LastIndex = self.ImpDynamicTable.StartIndex
end

function XUiPokemonMain:OnDestroy()
    self:StopTimer()
end

function XUiPokemonMain:OnGetEvents()
    return {
        XEventId.EVENT_POKEMON_REMAINING_TIMES_CHANGE,
        XEventId.EVENT_POKEMON_PASSED_STAGE_CHANGE,
    }
end

function XUiPokemonMain:OnNotify(event, ...)
    if event == XEventId.EVENT_POKEMON_REMAINING_TIMES_CHANGE then
        --self:RefreshRemainingTimes()
    elseif event == XEventId.EVENT_POKEMON_PASSED_STAGE_CHANGE then
        self:SetupDynamicTable()
        self:RefreshSkipPanel()
        self:RefreshSkipStageTimes()
    end
end

function XUiPokemonMain:InitDynamicTable()
    self.DynamicTable = XDynamicTableCurve.New(self.PaneStageList)
    self.DynamicTable:SetProxy(XUiGridPokemonStagePage)
    self.DynamicTable:SetDelegate(self)
end

function XUiPokemonMain:SetupDynamicTable()
    local stages = XDataCenter.PokemonManager.GetPassedCountByChapterId(XDataCenter.PokemonManager.GetSelectChapter()) + 1
    stages = XMath.Clamp(stages,1,XPokemonConfigs.GetStageCountByChapter(XDataCenter.PokemonManager.GetCurrActivityId(),XDataCenter.PokemonManager.GetSelectChapter()))
    local pages = math.ceil(stages / XPokemonConfigs.GetChapterPerPageStageCount(XDataCenter.PokemonManager.GetSelectChapter()))
    self.DynamicTable:SetTotalCount(pages)
    self.DynamicTable:ReloadData(self.LastIndex)
    self.DynamicTable:TweenToIndex(pages - 1)
end

function XUiPokemonMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        --self:CloseDetailUi()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitStage(function(stageId)
            self:OnOpenStageDetail(stageId)
        end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        --if self.ImpDynamicTable.StartIndex * XPokemonConfigs.PerPageCount >= XDataCenter.PokemonManager.GetStageCountByType(XPokemonConfigs.StageType.Normal) then
        --    self.ImpDynamicTable.enabled = false
        --    self.IsInfinity = true
        --end
    end
end

--function XUiPokemonMain:CloseDetailUi()
--    if XLuaUiManager.IsUiShow("UiPokemonStageDetail") then
--        local childUi = self:FindChildUiObj("UiPokemonStageDetail")
--        self:CloseChildUi("UiPokemonStageDetail")
--    end
--end

function XUiPokemonMain:RegisterButtonEvent()
    self.BtnBack.CallBack = function()
        self:OnClickBackBtn()
    end
    self.BtnMainUi.CallBack = function()
        self:OnClickMainBtn()
    end
    self.BtnTask.CallBack = function()
        self:OnClickTaskBtn()
    end
    self.BtnCulture.CallBack = function()
        self:OnClickTeamTraining()
    end

    self.BtnHelp.CallBack = function()
        self:OnClickHelpBtn()
    end

    self.BtnJumpOff.CallBack = function()
        self:OnClickBtnJump()
    end

    self.InfinityUiWidget:AddPointerClickListener(function(eventData)
        self:CloseDetailUi()
    end)

    CsXUiHelper.RegisterClickEvent(self.BtnTreasure, function()
        self:OnClickTimeSupplyBtn()
    end)
    CsXUiHelper.RegisterClickEvent(self.BtnSkipIconClick, function()
        local itemId = XPokemonConfigs.GetSkipItemId()
        local data = {
            IsTempItemData = true,
            Name = XDataCenter.ItemManager.GetItemName(itemId),
            Count = XDataCenter.PokemonManager.GetStageSkipTimes(),
            Icon = XDataCenter.ItemManager.GetItemIcon(itemId),
            Quality = XDataCenter.ItemManager.GetItemQuality(itemId),
            WorldDesc = XDataCenter.ItemManager.GetItemWorldDesc(itemId),
            Description = XDataCenter.ItemManager.GetItemDescription(itemId)
        }
        XLuaUiManager.Open("UiTip",data,false,self.Name)
    end)
end

function XUiPokemonMain:OnOpenStageDetail(stageId)
    XLuaUiManager.Open("UiPokemonStageDetail",stageId)
end

function XUiPokemonMain:OnClickHelpBtn()
    local helpId = XPokemonConfigs.GetHelpId()
    if helpId > 0 then
        local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
        XUiManager.ShowHelpTip(template.Function)
    end
end

function XUiPokemonMain:OnClickTaskBtn()
    XLuaUiManager.Open("UiPokemonActiveTask")
end

function XUiPokemonMain:OnClickBackBtn()
    XLuaUiManager.Close("UiPokemonMain")
end

function XUiPokemonMain:OnClickMainBtn()
    XLuaUiManager.RunMain()
end

function XUiPokemonMain:OnClickTeamTraining()
    XDataCenter.PokemonManager.OpenMonsterUi()
end

function XUiPokemonMain:OnClickTimeSupplyBtn()
    if XDataCenter.PokemonManager.CheckCanGetTimeSupply() then
        XDataCenter.PokemonManager.PokemonGetTimeSupplyRewardRequest(function(rewardsList)
            self:ShowBoxRewards(rewardsList)
        end)
    else
        XUiManager.TipText("PokemonCannotGetTimeSupply")
    end
end

function XUiPokemonMain:OnClickBtnJump()
    XLuaUiManager.Open("UiPokemonFight")
end

function XUiPokemonMain:RefreshSkipPanel()
    local chapter = XDataCenter.PokemonManager.GetSelectChapterType()
    local skipInfo = XDataCenter.PokemonManager.GetSkipStageInfo()
    if self.PanelIcon and self.BtnJumpOff then
        self.BtnJumpOff.gameObject:SetActiveEx(chapter == XPokemonConfigs.ChapterType.Skip and (#skipInfo ~= 0))
        self.PanelIcon.gameObject:SetActiveEx(chapter == XPokemonConfigs.ChapterType.Skip)
    end
end

function XUiPokemonMain:RefreshStagePanel()
    --屏蔽原有无尽关逻辑
    if false then --XDataCenter.PokemonManager.IsInfinity() then
        self.PanelNightmareStageList.gameObject:SetActiveEx(true)
        self.PanelNormalStageList.gameObject:SetActiveEx(false)
        self.InfinityStage:Refresh(XDataCenter.PokemonManager.GetNextStage())
        self.PanelChallenge.gameObject:SetActiveEx(false)
    else
        self.PanelNightmareStageList.gameObject:SetActiveEx(false)
        self.PanelNormalStageList.gameObject:SetActiveEx(true)
        self.PanelChallenge.gameObject:SetActiveEx(true)
        self:SetupDynamicTable()
    end
end

function XUiPokemonMain:RefreshNextRecoverTime()
    if not self.TxtNextRecoverTime then return end
    local nextRecoverTime = XDataCenter.PokemonManager.GetNextRecoverTime()
    if nextRecoverTime == 0 then
        local timeStr = XUiHelper.GetTime(XPokemonConfigs.GetDefaultStageTimesRecoverInterval(), XUiHelper.TimeFormatType.DEFAULT)
        self.TxtNextRecoverTime.text = timeStr
        return
    end

    local now = XTime.GetServerNowTimestamp()
    local offset = nextRecoverTime - now
    offset = XMath.Clamp(offset, 0, nextRecoverTime)
    local timeStr = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.DEFAULT)
    self.TxtNextRecoverTime.text = timeStr
end

function XUiPokemonMain:RefreshChapterStageBuff()
    local path = XDataCenter.PokemonManager.GetSelectChapterTitleImage()
    if not string.IsNilOrEmpty(path) then
        self:SetUiSprite(self.ImgChapterTitle,path)
    end
    self.TxtBuffTitle.text = XDataCenter.PokemonManager.GetSelectChapterName()
    self.TxtBuff.text = string.gsub(XDataCenter.PokemonManager.GetSelectChapterDesc(), "\\n", "\n")
end

function XUiPokemonMain:RefreshRemainingTimes()
    local times = XDataCenter.PokemonManager.GetRemainingTimes()
    self.TxtNumber.text = times
end

function XUiPokemonMain:RefreshTimeSupplyText()
    local offsetTime = XDataCenter.PokemonManager.GetTimeSupplyOffsetTime()
    self.TxtProgress.text = self:ParseTime(offsetTime)
    XEventManager.DispatchEvent(XEventId.EVENT_POKEMON_RED_POINT_TIME_SUPPLY)
end

function XUiPokemonMain:RefreshTimeSupplyProgress()
    local offsetTime = XDataCenter.PokemonManager.GetTimeSupplyOffsetTime()
    self.ImgProgress.fillAmount = offsetTime / (XPokemonConfigs.GetTimeSupplyMaxCount() * XPokemonConfigs.GetTimeSupplyInterval())
end

function XUiPokemonMain:RefreshActivityTime()
    local _, endTime = XDataCenter.PokemonManager.GetCurrActivityTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
    if offset < 0 then
        offset = 0
    end
    local timeStr = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = timeStr
end
--原有的时间显示修改为跳关券数量展示
function XUiPokemonMain:RefreshSkipStageTimes()
    self.TxtSkipNum.text = XDataCenter.PokemonManager.GetStageSkipTimes()
    self.TxtSkipMaxNum.text = string.format("/%s",tostring(XPokemonConfigs.GetSkipMaxTime()))
    self.RImgSkipIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XPokemonConfigs.GetSkipItemId()))
end

function XUiPokemonMain:ShowBoxRewards(rewardsList)
    XUiManager.OpenUiTipReward(rewardsList)
end

function XUiPokemonMain:CheckTimeSupplyRedPoint(isShow)
    self.ImgRedPoint.gameObject:SetActiveEx(isShow >= 0)

    if self.TxtReward then
        self.TxtReward.gameObject:SetActiveEx(isShow >= 0)
    end

    if self.RImgBgIcon then
        self.RImgBgIcon.gameObject:SetActiveEx(isShow < 0)
    end

    if self.RImgBgIcon2 then
        self.RImgBgIcon2.gameObject:SetActiveEx(isShow >= 0)
    end
end

function XUiPokemonMain:CheckTaskRedPoint(isShow)
    self.BtnTask:ShowReddot(isShow >= 0)
end

function XUiPokemonMain:StopTimer()
    if self.TimeHandler then
        XScheduleManager.UnSchedule(self.TimeHandler)
        self.TimeHandler = nil
    end
end
--原有无尽关逻辑修改屏蔽
--function XUiPokemonMain:SwitchToInfinity()
--    if XDataCenter.PokemonManager.GetIsSwitchToInfinity() then
--        if self.SwitchEffect then
--            self.SwitchEffect.gameObject:SetActiveEx(true)
--            XScheduleManager.ScheduleOnce(function()
--                self:RefreshStagePanel()
--            end, SWITCH_EFFECT_TIME)
--        end
--        XDataCenter.PokemonManager.SetIsSwitchToInfinity(false)
--    else
--        self:RefreshStagePanel()
--        self.SwitchEffect.gameObject:SetActiveEx(false)
--    end
--end

function XUiPokemonMain:ParseTime(time)
    local seconds = math.floor(time % 60)
    local mins = math.floor((time / 60) % 60)
    local hours = math.floor(time / 3600)
    return string.format("%02d:%02d:%02d", hours, mins, seconds)
end

return XUiPokemonMain