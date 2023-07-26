local XUiEscapeBattleRoomExpand = XClass(nil, "XUiEscapeBattleRoomExpand")

function XUiEscapeBattleRoomExpand:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ExplainTexts = {}
    self.EscapeData = XDataCenter.EscapeManager.GetEscapeData()
end

-- team : XTeam
function XUiEscapeBattleRoomExpand:SetData(team, stageId)
    local chapterId = XDataCenter.EscapeManager.GetCurSelectChapterId()
    local descs = XEscapeConfigs.GetChapterEnvironmentDesc(chapterId)
    for i, desc in ipairs(descs) do
        local explainText = self.ExplainTexts[i]
        if not explainText then
            explainText = i == 1 and self.TxtExplain or XUiHelper.Instantiate(self.TxtExplain, self.Content)
            self.ExplainTexts[i] = explainText
        end
        explainText.text = desc
        explainText.gameObject:SetActiveEx(true)
    end

    for i = #descs + 1, #self.ExplainTexts do
        self.ExplainTexts[i].gameObject:SetActiveEx(false)
    end
end

return XUiEscapeBattleRoomExpand