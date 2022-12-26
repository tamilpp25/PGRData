local CsXTextManagerGetText = CsXTextManagerGetText

local XUiGridStrongholdBanner = XClass(nil, "XUiGridStrongholdBanner")

function XUiGridStrongholdBanner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridStrongholdBanner:Refresh(chapterId)
    local icon = XStrongholdConfigs.GetChapterBg(chapterId)
    self.RImgDz:SetRawImage(icon)

    local name = XStrongholdConfigs.GetChapterName(chapterId)
    self.TxtName.text = name

    local finishCount, totalCount = XDataCenter.StrongholdManager.GetChapterGroupProgress(chapterId)
    self.TxtProgress.text = CsXTextManagerGetText("StrongholdChapterProgress", finishCount, totalCount)

    local isUnlock, conditionDes = XDataCenter.StrongholdManager.CheckChapterUnlock(chapterId)
    if isUnlock then
        self.Imglock.gameObject:SetActiveEx(false)
    else
        self.TxtUnlockCondition.text = conditionDes
        self.Imglock.gameObject:SetActiveEx(true)
    end
end

return XUiGridStrongholdBanner