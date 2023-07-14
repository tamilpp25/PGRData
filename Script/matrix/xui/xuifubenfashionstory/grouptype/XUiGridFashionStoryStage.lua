local XUiGridFashionStoryStage=XClass(nil,'XUiGridFashionStoryStage')
local XUiButtonState={
    Normal=0,
    Disable=3
}

function XUiGridFashionStoryStage:Ctor(root,ui)
    self.Root=root
    XTool.InitUiObjectByUi(self,ui)
    self.Button.CallBack=function() self:OnClickEvent() end
end

function XUiGridFashionStoryStage:RefreshData(stageId)
    self.Id=stageId
    self.Button:SetRawImage(XFashionStoryConfigs.GetStoryStageFace(self.Id))

    self.IsOpen,self.UnLockReason=XDataCenter.FashionStoryManager.CheckFashionStoryStageIsOpen(self.Id)
    if self.IsOpen then
        self.Button:SetButtonState(XUiButtonState.Normal)
        local isFinish=XDataCenter.FubenManager.CheckStageIsPass(self.Id)
        self.ImgFinish1.gameObject:SetActiveEx(isFinish)
        self.ImgFinish2.gameObject:SetActiveEx(isFinish)
    else
        self.Button:SetButtonState(XUiButtonState.Disable)
    end
    
end

function XUiGridFashionStoryStage:OnClickEvent()
    if self.Id then
        if self.IsOpen then
            XLuaUiManager.Open('UiFashionStoryDialog',self.Id)
        else
            local content
            if self.UnLockReason==XFashionStoryConfigs.TrialStageUnOpenReason.PreStageUnPass then
                content=XUiHelper.GetText('FashionStoryTrialPreStagePassTip',XDataCenter.FubenManager.GetStageName(XFashionStoryConfigs.GetPreStageId(self.Id)))
            elseif self.UnLockReason==XFashionStoryConfigs.TrialStageUnOpenReason.OutOfTime then
                content=XUiHelper.GetText('FashionStoryTrialOutTime',XUiHelper.GetTimeYearMonthDay(XFashionStoryConfigs.GetStageTimeId(self.Id)))
            end
            XUiManager.TipMsg(content)
        end
    end
end

return XUiGridFashionStoryStage