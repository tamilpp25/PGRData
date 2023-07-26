local XUiGridFashionStoryTrialStage=XClass(nil,"XUiGridFashionStoryTrialStage")

local XUiButtonState={
    Normal=0,
    Disable=3
}

function XUiGridFashionStoryTrialStage:Ctor(root,ui)
    self.Root=root
    XTool.InitUiObjectByUi(self,ui)
    self.GridFitting.CallBack=function() self:OnClickEvent() end
end


function XUiGridFashionStoryTrialStage:RefreshData(id)
    self.Id=id
    --判断是否解锁
    local isOpen,unOpenReason=XDataCenter.FashionStoryManager.CheckFashionStoryStageIsOpen(self.Id)
    self.IsOpen=isOpen
    if self.IsOpen then
        self.GridFitting:SetButtonState(XUiButtonState.Normal)
    else
        self.GridFitting:SetButtonState(XUiButtonState.Disable)
        if unOpenReason==XFashionStoryConfigs.TrialStageUnOpenReason.PreStageUnPass then
            self.TxtLock.text=XUiHelper.GetText('FashionStoryTrialPreStagePassTip',XDataCenter.FubenManager.GetStageName(XFashionStoryConfigs.GetPreStageId(self.Id)))
        elseif unOpenReason==XFashionStoryConfigs.TrialStageUnOpenReason.OutOfTime then
            self.TxtLock.text=XUiHelper.GetText('FashionStoryTrialOutTime',XUiHelper.GetTimeYearMonthDay(XFashionStoryConfigs.GetStageTimeId(self.Id)))
        end
    end
    --设置基本信息
    self.GridFitting:SetNameByGroup(0,XDataCenter.FubenManager.GetStageName(self.Id))
    self.GridFitting:SetRawImage(XFashionStoryConfigs.GetTrialFace(self.Id))
    self.RImgIconMask:SetRawImage(XFashionStoryConfigs.GetTrialLockIcon(self.Id))
end

function XUiGridFashionStoryTrialStage:OnClickEvent()
    if self.Id then
        if self.IsOpen then
            self.Root:OpenOneChildUi('UiFashionStoryStageTrialDetailNew', self.Id,handler(self.Root, self.Root.Close))
        else
            XUiManager.TipMsg(self.TxtLock.text)
        end
    end
end

return XUiGridFashionStoryTrialStage