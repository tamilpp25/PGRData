local XUiGridFashionStoryGroup=XClass(nil,"XUiGridFashionStoryGroup")

local XUiButtonState={
    Normal=0,
    Disable=3
}

function XUiGridFashionStoryGroup:Ctor(root,ui)
    self.Parent=root;
    XTool.InitUiObjectByUi(self,ui)

    --注册点击事件打开关卡组界面
    self.PanelSummer.CallBack=function() self:OnClickEvent() end
end

function XUiGridFashionStoryGroup:Refresh(groupId)
    self.GroupId=groupId
    --读取配置表显示信息
    self.PanelSummer:SetNameByGroup(0,XFashionStoryConfigs.GetSingleLineName(self.GroupId))
    self.PanelSummer:SetRawImage(XFashionStoryConfigs.GetSingleLineAsGroupStoryIcon(self.GroupId))
    --判断是否解锁
    self.IsOpen,self.LockReason=XDataCenter.FashionStoryManager.CheckGroupIsCanOpen(self.GroupId)
    if self.IsOpen then
        self.PanelSummer:SetButtonState(XUiButtonState.Normal)
        --读取当进度数据显示信息
        local stagesCount=XFashionStoryConfigs.GetSingleLineStagesCount(self.GroupId)
        local passedCount=XDataCenter.FashionStoryManager.GetGroupStagesPassCount(XFashionStoryConfigs.GetSingleLineStages(self.GroupId))

        self.PanelSummer:SetNameByGroup(1,tostring(passedCount)..'/'..tostring(stagesCount))
        local isFinish=passedCount>=stagesCount
        self.ImgFinish1.gameObject:SetActiveEx(isFinish)
        self.ImgFinish2.gameObject:SetActiveEx(isFinish)
    else
        self.PanelSummer:SetButtonState(XUiButtonState.Disable)
    end
    --红点
    XRedPointManager.CheckOnceByButton(self.PanelSummer,{XRedPointConditions.Types.CONDITION_FASHION_STORY_NEWCHAPTER_UNLOCK},self.GroupId)
end

function XUiGridFashionStoryGroup:OnClickEvent()
    XDataCenter.FashionStoryManager.EnterPaintingGroupPanel(self.GroupId,self.IsOpen,self.LockReason)
end

return XUiGridFashionStoryGroup