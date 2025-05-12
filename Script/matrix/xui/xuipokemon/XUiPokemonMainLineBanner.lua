local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPokemonMainLineBanner = XLuaUiManager.Register(XLuaUi, "UiPokemonMainLineBanner")
local XUiGridPokemonChapter = require("XUi/XUiPokemon/XUiGridPokemonChapter")

function XUiPokemonMainLineBanner:OnStart()
    self:RegisterButtonEvent()
    self:InitDynamicTable()
    self:SetupDynamicTable()
    local helpId = XPokemonConfigs.GetHelpId()
    self.BtnHelp.gameObject:SetActiveEx(helpId > 0)
    XRedPointManager.AddRedPointEvent(self.ImgRedPoint, self.CheckTimeSupplyRedPoint, self, { XRedPointConditions.Types.CONDITION_POKEMON_TIME_SUPPLY_RED })
end

function XUiPokemonMainLineBanner:OnEnable()
    self:RefreshTimeSupplyText()
    self:RefreshTimeSupplyProgress()
    self:RefreshActivityTime()
    self:StartTimer()
    XRedPointManager.CheckOnce(self.CheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_POKEMON_TASK_RED })
end

function XUiPokemonMainLineBanner:OnDisable()
    self:StopTimer()
end

function XUiPokemonMainLineBanner:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.SViewChapterDz)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridPokemonChapter,self)
end

function XUiPokemonMainLineBanner:SetupDynamicTable()
    local chapters = XDataCenter.PokemonManager.GetChapters()
    self.DynamicTable:SetTotalCount(#chapters)
    self.DynamicTable:ReloadDataASync()
end

function XUiPokemonMainLineBanner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClickGrid(index)
    end
end

function XUiPokemonMainLineBanner:StartTimer()
    if self.TimeHandler then self:StopTimer() end
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
        self:RefreshActivityTime()
    end, 1000, 0)
end

function XUiPokemonMainLineBanner:StopTimer()
    if self.TimeHandler then
        XScheduleManager.UnSchedule(self.TimeHandler)
        self.TimeHandler = nil
    end
end

function XUiPokemonMainLineBanner:RegisterButtonEvent()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnTask.CallBack = function()
        XLuaUiManager.Open("UiPokemonActiveTask")
    end
    self.BtnCulture.CallBack = function()
        XDataCenter.PokemonManager.OpenMonsterUi()
    end

    self.BtnHelp.CallBack = function()
        self:OnClickHelpBtn()
    end

    self:RegisterClickEvent(self.BtnTreasure,function() self:OnClickTimeSupplyBtn() end)
end

function XUiPokemonMainLineBanner:OnClickHelpBtn()
    local helpId = XPokemonConfigs.GetHelpId()
    if helpId > 0 then
        local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
        XUiManager.ShowHelpTip(template.Function)
    end
end

function XUiPokemonMainLineBanner:OnClickTimeSupplyBtn()
    if XDataCenter.PokemonManager.CheckCanGetTimeSupply() then
        XDataCenter.PokemonManager.PokemonGetTimeSupplyRewardRequest(function(rewardsList)
            XUiManager.OpenUiTipReward(rewardsList)
        end)
    else
        XUiManager.TipText("PokemonCannotGetTimeSupply")
    end
end

function XUiPokemonMainLineBanner:RefreshTimeSupplyText()
    local offsetTime = XDataCenter.PokemonManager.GetTimeSupplyOffsetTime()
    self.TxtProgress.text = self:ParseTime(offsetTime)
    XEventManager.DispatchEvent(XEventId.EVENT_POKEMON_RED_POINT_TIME_SUPPLY)
end

function XUiPokemonMainLineBanner:RefreshActivityTime()
    local _, endTime = XDataCenter.PokemonManager.GetCurrActivityTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
    if offset < 0 then
        offset = 0
    end
    local timeStr = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtEndurance.text = timeStr
end

function XUiPokemonMainLineBanner:CheckTimeSupplyRedPoint(isShow)
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

function XUiPokemonMainLineBanner:CheckTaskRedPoint(isShow)
    self.BtnTask:ShowReddot(isShow >= 0)
end

function XUiPokemonMainLineBanner:RefreshTimeSupplyProgress()
    local offsetTime = XDataCenter.PokemonManager.GetTimeSupplyOffsetTime()
    self.ImgProgress.fillAmount = offsetTime / (XPokemonConfigs.GetTimeSupplyMaxCount() * XPokemonConfigs.GetTimeSupplyInterval())
end

function XUiPokemonMainLineBanner:ParseTime(time)
    local seconds = math.floor(time % 60)
    local mins = math.floor((time / 60) % 60)
    local hours = math.floor(time / 3600)
    return string.format("%02d:%02d:%02d", hours, mins, seconds)
end

return XUiPokemonMainLineBanner