local XUiGridTwoSideTowerChapter = XClass(nil, "XUiGridTwoSideTowerChapter")

---@param transform UnityEngine.RectTransform
function XUiGridTwoSideTowerChapter:Ctor(transform, chapterId)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.ChapterId = chapterId
    XTool.InitUiObject(self)
    self.BtnClick.CallBack = function()
        local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
        local desc, isUnlock = chapter:GetProcess()
        if not isUnlock then
            XUiManager.TipMsg(desc)
            return
        end
        XLuaUiManager.Open("UiTwoSideTowerMainLine", self.ChapterId)
    end
end

function XUiGridTwoSideTowerChapter:Update(chapterId)
    self.ChapterId = chapterId or self.ChapterId
    ---@type XTwoSideTowerChapter
    local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
    self.TxtName.text = chapter:GetChapterName()
    self.TxtNamNum.text = chapter:GetSecondName()
    local desc, isUnlock = chapter:GetProcess()
    self.TxtUnlockCondition.text = desc
    self.Imglock.gameObject:SetActiveEx(not isUnlock)
    self.RImgDz:SetRawImage(chapter:GetIcon())
    self.Imglock:SetRawImage(chapter:GetIcon())

    -- 积分等级
    local isClear = chapter:IsCleared()
    local scoreIconList = {self.RImgRankA, self.RImgRankS, self.RImgRankSS, self.RImgRankSSS}
    local scoreLv = chapter:GetMaxChapterScoreLevel()
    for i, scoreIcon in ipairs(scoreIconList) do
        local isShow = i == scoreLv and isClear
        scoreIcon.gameObject:SetActiveEx(isShow)
    end
end

return XUiGridTwoSideTowerChapter
