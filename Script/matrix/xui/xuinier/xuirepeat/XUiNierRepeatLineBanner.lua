local XUiNierRepeatLineBanner = XClass(nil, "XUiNierRepeatLineBanner")
local XUiPanelNieRRepeatBanner = require("XUi/XUiNieR/XUiRepeat/XUiPanelNieRRepeatBanner")
local XUiNieRRepeatTag = require("XUi/XUiNieR/XUiRepeat/XUiNieRRepeatTag")
function XUiNierRepeatLineBanner:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    
    self.ArrowR.CallBack = function() self:OnBtnArrowRClick() end
    self.ArrowL.CallBack = function() self:OnBtnArrowLClick() end

    self.DynamicTable = XDynamicTableCurve.New(self.ScrollChapterCurve)
    self.DynamicTable:SetProxy(XUiPanelNieRRepeatBanner)
    self.DynamicTable:SetDelegate(self)
    
    self.NieRRepeatTags = {}
    self.SelectedIndex = 0
    self.IsShowTag = true

end

function XUiNierRepeatLineBanner:UpdateData(jumpId)
    self.AnimEnable.gameObject:PlayTimelineAnimation(function()
        
    end)
    self.RepeatList = XDataCenter.NieRManager.GetRepeatDataList()
    
    
    self.RepeatCount = #self.RepeatList
    self.DynamicTable:SetDataSource(self.RepeatList)
    self.DynamicTable:ReloadData(self.RepeatCount > 0 and self.SelectedIndex or -1)

    self:UpdateArrowByIndex(self.SelectedIndex)
    self.TxtTitleBg.text = string.format("/%02d", self.RepeatCount)
    for index = 1, 4 do
        local grid
        if not self.NieRRepeatTags[index] then
            grid = XUiNieRRepeatTag.New(self["Stage"..index])
            self.NieRRepeatTags[index] = grid
        else
            grid = self.NieRRepeatTags[index]
        end
        grid:Init(self.RepeatList[index], (self.SelectedIndex + 1 == index))
    end
    self.LastTagIndex = self.SelectedIndex

    if jumpId then
        local jumpIndex = 0
        for index, data in ipairs(self.RepeatList) do
            if data:GetNieRRepeatStageId() == jumpId then
                jumpIndex = index - 1
                break
            end
        end
        self.DynamicTable:TweenToIndex(jumpIndex)
    else
        local stageId = XDataCenter.NieRManager.GetSelRepeatStageId()
        if stageId == 0 then
            return 
        end 
        local jumpIndex = 0
        for index, data in ipairs(self.RepeatList) do
            if data:GetNieRRepeatStageId() == stageId then
                jumpIndex = index - 1
                break
            end
        end
        self.DynamicTable:TweenToIndex(jumpIndex)
    end
end

function XUiNierRepeatLineBanner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.RepeatList[index + 1])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        local startIndex = self.DynamicTable.Imp.StartIndex
        local selectIndex = startIndex % self.DynamicTable.Imp.TotalCount
        if self.SelectedIndex ~= selectIndex then
            self.SelectedIndex = selectIndex
            grid = self.DynamicTable:GetGridByIndex(selectIndex)
            if grid then
                grid:PlayLoopAnim()
            end 
        end
        self.Retrieval.gameObject:SetActiveEx(true)
        self.IsShowTag = true
        self:UpdateArrowByIndex(self.SelectedIndex)
        self:UpdateTagByIndex(self.SelectedIndex)  
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
       
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then
        if self.IsShowTag then
            self.Retrieval.gameObject:SetActiveEx(false)
            self.IsShowTag = false
        end
    end
end


function XUiNierRepeatLineBanner:UpdateArrowByIndex(index)
    if index == self.LastTagIndex then
        return
    end
    if index == 0 then
        self.ArrowL.gameObject:SetActiveEx(false)
    else
        self.ArrowL.gameObject:SetActiveEx(true)
    end

    if index == self.RepeatCount - 1 then
        self.ArrowR.gameObject:SetActiveEx(false)
    else
        self.ArrowR.gameObject:SetActiveEx(true)
    end
end

function XUiNierRepeatLineBanner:UpdateTagByIndex(index)
    if index == self.LastTagIndex then
        return
    end
    self.TxtTitle.text = string.format("%02d", index + 1)
    self.NieRRepeatTags[index + 1]:ChangeSelState(true)
    if self.LastTagIndex then
        self.NieRRepeatTags[self.LastTagIndex + 1]:ChangeSelState(false)
    end
    self.LastTagIndex = index
end

function XUiNierRepeatLineBanner:OnBtnArrowRClick()
    self.DynamicTable:TweenToIndex(self.SelectedIndex + 1)
end

function XUiNierRepeatLineBanner:OnBtnArrowLClick()
    self.DynamicTable:TweenToIndex(self.SelectedIndex - 1)
end

function XUiNierRepeatLineBanner:GetNieRRepeatTaskSkipId()
    local nieRRepeat = self.RepeatList[self.SelectedIndex + 1]
    if nieRRepeat then
        return nieRRepeat:GetNieRRepeatTaskSkipId()
    end
    return nil
end

return XUiNierRepeatLineBanner