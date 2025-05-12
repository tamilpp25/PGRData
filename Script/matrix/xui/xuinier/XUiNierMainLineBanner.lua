local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiNierMainLineBanner = XClass(nil, "UiNierMainLineBanner")
local XUiGridNierChapter = require("XUi/XUiNieR/XUiGridNierChapter")
function XUiNierMainLineBanner:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageList = {}
    self.GridStageList = {}
    self.LineList = {}

    XTool.InitUiObject(self)
    
    self.DynamicTable = XDynamicTableNormal.New(self.PanelChapterEX)
    self.DynamicTable:SetProxy(XUiGridNierChapter)
    self.DynamicTable:SetDelegate(self)
end

function XUiNierMainLineBanner:UpdateData(hideChapter, needShowDelData)
    self:SetTimer()
    self.TextName.text = XDataCenter.NieRManager.GetActivityName()
    self.PanelChapterEX.gameObject:SetActiveEx(not hideChapter)
    self.NeedShowDelData = needShowDelData
    if needShowDelData then
        self.FubenTitleName.gameObject:SetActiveEx(false)
    else
        self.FubenTitleName.gameObject:SetActiveEx(true)
    end
    if not hideChapter then
        self:SetupDynamicTable()
    end
end

--设置动态列表
function XUiNierMainLineBanner:SetupDynamicTable()
    self.PageDatas = XDataCenter.NieRManager.GetChapterDataList()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

--动态列表事件
function XUiNierMainLineBanner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateChapterGrid(self.PageDatas[index], self.NeedShowDelData)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if not self.NeedShowDelData then
            self:ClickChapterGrid(self.PageDatas[index])
        end
    end
end

function XUiNierMainLineBanner:ClickChapterGrid(chapterData)
    local isUnLock, desc = chapterData:CheckNieRChapterUnLock()
    if isUnLock then
        XLuaUiManager.Open("UiFubenNierLineChapter", chapterData:GetChapterId())
    else
        XUiManager.TipMsg(desc)
    end
        
end

--设置活动结束倒计时
function XUiNierMainLineBanner:SetTimer()
    local endTimeSecond = XDataCenter.NieRManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if now <= endTimeSecond then
        local activeOverStr = CS.XTextManager.GetText("NieREnd")
        self:StopTimer()
        if now <= endTimeSecond then
            self.TextTitle.text = CS.XTextManager.GetText("NieRActivityLeftTime", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.CHATEMOJITIMER))
            self.TxtDayNum.text = XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.NieRShow)
        else
            self.TxtDayNum.text = activeOverStr
        end

        self.Timer = XScheduleManager.ScheduleForever(function()
                now = XTime.GetServerNowTimestamp()
                if now <= endTimeSecond then
                    self.TextTitle.text = CS.XTextManager.GetText("NieRActivityLeftTime", XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.CHATEMOJITIMER))
                    self.TxtDayNum.text = XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.NieRShow)
                else
                    self.TextTitle.text = activeOverStr
                    self.TxtDayNum.text = activeOverStr
                end
                if now > endTimeSecond then
                    self:StopTimer()
                    return
                end
            end, XScheduleManager.SECOND, 0)
    end
end

function XUiNierMainLineBanner:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiNierMainLineBanner