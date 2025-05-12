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
    -- 区别nzwjV3更新前后两种日志，安稳度日志和触发次数日志
    if data.TotalEffectCount and data.TotalEffectCount > 0 then   -- 是触发次数日志
        if data.CurEffectCount > 0 and data.CurEffectCount <= data.TotalEffectCount then
            self.DescText.text = self.DescText.text .. "\n" .. string.format(self.GetText("GuildBossLogLine3"), data.CurEffectCount) --nzwjV3 安稳度改为触发次数
        end

    else  -- 是安稳度日志
        if data.EffectValue > 0 then
            self.DescText.text = self.DescText.text .. "\n" .. string.format(self.GetText("GuildBossLogLine6"), data.EffectValue)
        end
        
        if data.EffectValue >= 100 then
            self.DescText.text = self.DescText.text .. string.format(self.GetText("GuildBossLogLine4"))
            self.DescText.text = self.DescText.text .. "\n" .. string.format(self.GetText("GuildBossLogLine5"), data.EffectHp)
        end
    end
    
    self.LayoutNode:SetDirty()
end

return XUiGuildBossLog