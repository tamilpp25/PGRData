--工会boss日志组件
local XUiGuildBossLog = XClass(nil, "XUiGuildBossLog")

function XUiGuildBossLog:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GetText = CS.XTextManager.GetText
end

function XUiGuildBossLog:Init(data)
    self.NameText.text = data.PlayerName
    self.DescText.text = string.format(self.GetText("GuildBossLogLine1"), 
    XTime.TimestampToGameDateTimeString(data.Time, "MM-dd HH:mm"),
    XGuildBossConfig.GetBossStageInfo(data.StageId).Name) .. "\n"
    self.DescText.text = self.DescText.text .. string.format(self.GetText("GuildBossLogLine2"), data.SubHp) 
    if data.EffectValue > 0 then
        self.DescText.text = self.DescText.text .. "\n" .. string.format(self.GetText("GuildBossLogLine3"), data.EffectValue)
    end

    if data.EffectValue == 100 then
        self.DescText.text = self.DescText.text .. string.format(self.GetText("GuildBossLogLine4"))
        self.DescText.text = self.DescText.text .. "\n" .. string.format(self.GetText("GuildBossLogLine5"), data.EffectHp)
    end
    
    self.LayoutNode:SetDirty()
end

return XUiGuildBossLog