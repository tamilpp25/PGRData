local XUiGridBtnAttributeArea = XClass(nil, "XUiGridBtnAttributeArea")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridBtnAttributeArea:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
end

function XUiGridBtnAttributeArea:SetButtonCallBack()
    self.BtnArea.CallBack = function()
        self:OnBtnAreaClick()
    end
end

function XUiGridBtnAttributeArea:OnBtnAreaClick()
    local storyId = self.Data:GetStartStoryId()
    if storyId and #storyId > 1 then
        local IsCanPlay = XDataCenter.WorldBossManager.CheckIsNewStoryID(storyId)
        if IsCanPlay then
            XDataCenter.MovieManager.PlayMovie(storyId)--一次
            XDataCenter.WorldBossManager.MarkStoryID(storyId)
        end
    end
    XLuaUiManager.Open("UiWorldBossAttributeArea", self.Data:GetId())
end

function XUiGridBtnAttributeArea:UpdateData(data)
    self.Data = data
    if data then
        local IsHaveRed = XDataCenter.WorldBossManager.CheckWorldBossAttributeArearRedPoint(data:GetId())
        
        self.ScheduleText.text = CSTextManagerGetText("WorldBossAttributeAreaSchedule")
        self.NumText.text = string.format("%d/%d", data:GetFinishStageCount(), #data:GetStageIds())
        self.BtnArea:SetRawImage(data:GetAreaImg())
        self.BtnArea:SetName(data:GetEnglishName())
        
        self.NumText.gameObject:SetActiveEx(data:GetFinishStageCount() ~= #data:GetStageIds())
        self.CompleteImg.gameObject:SetActiveEx(data:GetFinishStageCount() == #data:GetStageIds())
        self.ScheduleText.gameObject:SetActiveEx(data:GetFinishStageCount() ~= #data:GetStageIds())
        self.BtnArea:ShowReddot(IsHaveRed)
    end
end

function XUiGridBtnAttributeArea:ShowRedPoint(IsShow)
    self.BtnBoss:ShowReddot(IsShow)
end

return XUiGridBtnAttributeArea