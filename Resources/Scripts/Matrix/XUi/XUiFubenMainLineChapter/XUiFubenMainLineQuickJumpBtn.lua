XUiFubenMainLineQuickJumpBtn = XClass(nil, "XUiFubenMainLineQuickJumpBtn")
function XUiFubenMainLineQuickJumpBtn:Ctor(ui, index, chapter, cb, stageType)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Index = index
    self.Cb = cb
    self.StageType = stageType or XDataCenter.FubenManager.StageType.Mainline
    XTool.InitUiObject(self)
    self.BtnNormalDot.CallBack = function() self:OnBtnNodeClick() end
    self:UpdateNode(self.Index, chapter)
end

function XUiFubenMainLineQuickJumpBtn:OnBtnNodeClick()
    self.Cb(self.Index,self.StageId)
end

function XUiFubenMainLineQuickJumpBtn:UpdateNode(index, chapter)
    self.StageId = chapter.StageId[index]
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    self.Index = index
    local title
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ExtraChapter then
        title = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(stageInfo.ChapterId)
        title = string.gsub(title, "EX", "")
    else
        title = chapter.OrderId
    end
    title = title or ""
    self.TxtName.text = string.format("%s-%d", tostring(title), stageCfg.OrderId)
end