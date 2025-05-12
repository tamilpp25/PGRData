local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiBagOrganizeMain: XLuaUi
---@field _Control XBagOrganizeActivityControl
local XUiBagOrganizeMain = XLuaUiManager.Register(XLuaUi, 'UiBagOrganizeMain')

local XUiGridBagOrganizeChapter = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeMain/XUiGridBagOrganizeChapter')

function XUiBagOrganizeMain:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    self:BindHelpBtn(self.BtnHelp, "BagOrganize")
    self.BtnTask.CallBack = handler(self, self.OnTaskClickEvent)
    self.BtnRank.CallBack = handler(self, self.OnRankClickEvent)
end

function XUiBagOrganizeMain:OnStart()
    self:InitChapterUI()
    self._TaskReddotId = self:AddRedPointEvent(self.BtnTask, self.OnTaskBtnReddot, self, {XRedPointConditions.Types.CONDITION_BAGORGANIZE_TASK})
    self:InitShowRewards()
end

function XUiBagOrganizeMain:OnEnable()
    self:StartLeftTimer()
    self:RefreshChapterUI()
    XRedPointManager.Check(self._TaskReddotId)
end

function XUiBagOrganizeMain:OnDisable()
    self:StopLeftTimer()
end

--region 活动剩余时间显示
function XUiBagOrganizeMain:StartLeftTimer()
    self:StopLeftTimer()
    self:UpdateLeftTimer()
    self._LeftTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateLeftTimer), XScheduleManager.SECOND)
end

function XUiBagOrganizeMain:StopLeftTimer()
    if self._LeftTimerId then
        XScheduleManager.UnSchedule(self._LeftTimerId)
        self._LeftTimerId = nil
    end
end

function XUiBagOrganizeMain:UpdateLeftTimer()
    local timeId = self._Control:GetCurActivityTimeId()

    if XTool.IsNumberValid(timeId) then
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local now = XTime.GetServerNowTimestamp()
        
        local leftTime = endTime - now

        if leftTime < 0 then
            leftTime = 0
        end
        
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        return
    end

    self.TxtTime.text = XUiHelper.GetTime(0, XUiHelper.TimeFormatType.ACTIVITY)
end
--endregion

--region 章节入口
function XUiBagOrganizeMain:InitChapterUI()
    local chapterIds = self._Control:GetCurChapterIds()
    
    
    
    if not XTool.IsTableEmpty(chapterIds) then
        self._ChapterGrids = {}

        for index, id in ipairs(chapterIds) do

            local obj = self['GridChapter'..tostring(index)]
            if obj then
                local grid = XUiGridBagOrganizeChapter.New(obj, self, id, index)
                grid:Open()

                table.insert(self._ChapterGrids, grid)
            end
        end
    end
end

function XUiBagOrganizeMain:RefreshChapterUI()
    if not XTool.IsTableEmpty(self._ChapterGrids) then
        for index, grid in ipairs(self._ChapterGrids) do
            grid:Refresh()
        end
    end
end
--endregion

--region 任务入口
function XUiBagOrganizeMain:OnTaskClickEvent()
    XLuaUiManager.Open('UiBagOrganizeTask')
end


function XUiBagOrganizeMain:InitShowRewards()
    self.Grid256New.gameObject:SetActiveEx(false)
    self._GoodsPreview = {}
    --通用处理
    local showItems = nil
    local rewardId = self._Control:GetClientConfigNum('ShowRewardId')
    if XTool.IsNumberValid(rewardId) then
        showItems = XRewardManager.GetRewardListNotCount(rewardId)
    end
    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, showItems and #showItems or 0, function(index, obj)
        local gridCommont = XUiGridCommon.New(self, obj)
        gridCommont:Refresh(showItems[index])
        table.insert(self._GoodsPreview, gridCommont)
    end)


end

function XUiBagOrganizeMain:OnTaskBtnReddot(count)
    self.BtnTask:ShowReddot(count >= 0)
end
--endregion

--region 排行榜入口
function XUiBagOrganizeMain:OnRankClickEvent()
    XMVCA.XBagOrganizeActivity:RequestBagOrganizeRank(function(res)
        XLuaUiManager.Open('UiBagOrganizeRank', res)
    end)
end
--endregion

return XUiBagOrganizeMain