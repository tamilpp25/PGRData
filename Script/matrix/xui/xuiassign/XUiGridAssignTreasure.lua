local XUiGridAssignTreasure = XClass(nil, "XUiGridAssignTreasure")

function XUiGridAssignTreasure:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GridRewardList = {}

    XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnBtnReceiveClick)
end

function XUiGridAssignTreasure:Refresh(chapterId)
    local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
    self.ChapterId = chapterId
    self.TxtGrade.text = CS.XTextManager.GetText("AssignName")
    self.TxtTaskDescribe.text = CS.XTextManager.GetText("AssignChapterPass", chapterData:GetDesc())
    self.TxtTaskNumQian.text = CS.XTextManager.GetText("GradeStarNum", chapterData:GetPassNum(), #chapterData:GetGroupId())
    self.ImgProgress.fillAmount = chapterData:GetPassNum() / #chapterData:GetGroupId()

    for k, grid in pairs(self.GridRewardList) do
        grid.GameObject:SetActiveEx(false)
    end

    local rewardId = chapterData:GetRewardId()[1]
    if rewardId > 0 then
        local rewards = XRewardManager.GetRewardList(rewardId)
        for i, item in ipairs(rewards) do
            local grid = self.GridRewardList[i]
            if not grid then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.GridCommon.parent)
                grid = XUiGridCommon.New(self.RootUi, ui)
                self.GridRewardList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end
    self.GridCommon.gameObject:SetActive(false)

    self.ImgAlreadyReceived.gameObject:SetActiveEx(chapterData:IsRewarded())
    self.BtnReceive.gameObject:SetActiveEx(not chapterData:IsRewarded())
    self.BtnReceive:SetDisable(not chapterData:CanReward())
end

function XUiGridAssignTreasure:OnBtnReceiveClick()
    XDataCenter.FubenAssignManager.AssignGetRewardRequest(self.ChapterId, function ()
        self.RootUi:RefreshGirdState()
        self.RootUi.RootUi:Refresh()
    end)
end

return XUiGridAssignTreasure