local XUiGridReportMsgItem = XClass(nil, "XUiGridReportMsgItem")
local CSXGameClientConfig = CS.XGame.ClientConfig
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridReportMsgItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridReportMsgItem:Refresh(reportData)
    local playerInfo = reportData.PlayerInfo
    local reportId = reportData.ReportId
    local reportCfg = XWorldBossConfigs.GetReportTemplatesById(reportId)
    local reportType = XDataCenter.WorldBossManager.GetFightReportTypeById(reportId)
    local IsSystemReport = reportType == XWorldBossConfigs.ReportType.System

    self.PanelSystemMsgItem.gameObject:SetActiveEx(IsSystemReport)
    self.PanelPlayerMsgItem.gameObject:SetActiveEx(not IsSystemReport)

    if IsSystemReport then
        local headObj = self.PanelSystemMsgItem:GetObject("Head")
        local nameObj = self.PanelSystemMsgItem:GetObject("TxtName")
        local wordObj = self.PanelSystemMsgItem:GetObject("TxtWord")

        local headId = CSXGameClientConfig:GetInt("WorldBossReportHead")
        local nameText = CSTextManagerGetText("WorldBossReportName")
        local wordText = reportCfg.Message

        XUiPLayerHead.InitPortrait(headId, 0, headObj)
        nameObj.text = nameText
        wordObj.text = wordText
    else
        local headObj = self.PanelPlayerMsgItem:GetObject("Head")
        local nameObj = self.PanelPlayerMsgItem:GetObject("TxtName")
        local wordObj = self.PanelPlayerMsgItem:GetObject("TxtWord")

        local headId = playerInfo.HeadPortraitId
        local headFrameId = playerInfo.HeadFrameId
        local nameText = playerInfo.PlayerName
        local score = playerInfo.Score
        local wordText = string.format(reportCfg.Message,nameText,score)

        XUiPLayerHead.InitPortrait(headId, headFrameId, headObj)
        nameObj.text = nameText
        wordObj.text = wordText
    end
end
return XUiGridReportMsgItem