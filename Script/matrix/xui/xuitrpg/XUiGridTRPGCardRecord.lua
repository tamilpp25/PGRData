local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridTRPGCardRecord = XClass(nil, "XUiGridTRPGCardRecord")

function XUiGridTRPGCardRecord:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

function XUiGridTRPGCardRecord:Refresh(mazeId, cardRecordGroupId)
    local icon = XTRPGConfigs.GetMazeCardRecordGroupMiniIcon(cardRecordGroupId)
    self.UiRoot:SetUiSprite(self.ImgIconContent, icon)

    local name = XTRPGConfigs.GetMazeCardRecordGroupName(cardRecordGroupId)
    local finishCount, totalCount = XDataCenter.TRPGManager.GetMazeRecordGroupCardCount(mazeId, cardRecordGroupId)
    self.TxtContent.text = CSXTextManagerGetText("TRPGMazeCardRecord", name, finishCount, totalCount)
end

return XUiGridTRPGCardRecord