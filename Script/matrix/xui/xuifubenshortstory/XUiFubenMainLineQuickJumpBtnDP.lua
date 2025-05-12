local XUiFubenMainLineQuickJumpBtn = require("XUi/XUiFubenMainLineChapter/XUiFubenMainLineQuickJumpBtn")
local XUiFubenMainLineQuickJumpBtnDP = XClass(nil, "XUiFubenMainLineQuickJumpBtnDP")
function XUiFubenMainLineQuickJumpBtnDP:Ctor(ui, index, chapterId, cb, stageType)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Index = index
    self.Cb = cb
    self.StageType = stageType or XEnumConst.FuBen.StageType.Mainline
    XTool.InitUiObject(self)
    self.BtnNormalDot.CallBack = function() self:OnBtnNodeClick() end
    self:UpdateNode(self.Index, chapterId)
end

function XUiFubenMainLineQuickJumpBtnDP:OnBtnNodeClick()
    self.Cb(self.Index, self.StageId)
end

function XUiFubenMainLineQuickJumpBtnDP:UpdateNode(index, chapterId)
    local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
    self.StageId = stageIds[index]
    local stageCfg = XMVCA.XFuben:GetStageCfg(self.StageId)
    self.Index = index
    local title
    if stageCfg.Type == XEnumConst.FuBen.StageType.ShortStory then
        title = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(chapterId)
        title = string.gsub(title, "SS", "")
    else
        title = XFubenShortStoryChapterConfigs.GetChapterOrderIdByChapterId(chapterId)
    end
    title = title or ""
    self.TxtName.text = string.format("%s-%d", tostring(title), stageCfg.OrderId)
end

return XUiFubenMainLineQuickJumpBtnDP