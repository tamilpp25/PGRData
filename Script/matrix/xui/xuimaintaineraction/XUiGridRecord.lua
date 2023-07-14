local XUiGridRecord = XClass(nil, "XUiGridRecord")
local DefaultIndex = 1

function XUiGridRecord:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridRecord:UpdateGrid(data)
    self.Data = data
    if data then
        self.TextTime.text = XTime.TimestampToGameDateTimeString(data.Time, "MM-dd HH:mm")
        local eventInfo = XMaintainerActionConfigs.GetMaintainerActionEventTemplateById(data.EventId)
        
        if XMaintainerActionConfigs.IsFightEvent(data.EventId) then
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(data.EventValues[DefaultIndex])
            local tmpStr = string.format(eventInfo.RecordText,stageCfg.Name)
            self.TextRecording.text = string.format("%s%s", XPlayer.Name, tmpStr)
        else
            local tmpStr = string.format(eventInfo.RecordText,table.unpack(data.EventValues))
            self.TextRecording.text = string.format("%s%s", XPlayer.Name, tmpStr)
        end
    end
end

return XUiGridRecord