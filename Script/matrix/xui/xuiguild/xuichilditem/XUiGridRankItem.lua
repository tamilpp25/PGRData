local XUiPlayerLevel = require("XUi/XUiCommon/XUiPlayerLevel")
local XUiGridRankItem = XClass(nil, "XUiGridRankItem")

function XUiGridRankItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridRankItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

-- 更新数据
function XUiGridRankItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end
    self.TxtPosition.text = self.UiRoot:GetRankName(itemdata.RankLevel)
    if itemdata.OnlineFlag == 1 then
        self.TxtLastLanding.text = CS.XTextManager.GetText("GuildMemberOnline")
    else
        self.TxtLastLanding.text = XUiHelper.CalcLatelyLoginTimeWithDefault(itemdata.LastLoginTime, XGuildConfig.GuildDefaultDay)
    end
    
    XUiPlayerLevel.UpdateLevel(itemdata.Level, self.TxtLevel, CS.XTextManager.GetText("GuildMemberLevel", itemdata.Level))

    self.TxtPlayerName.text = itemdata.Name
    self.TxtSevenDay.text = itemdata.ContributeIn7Days
    
    XUiPlayerHead.InitPortrait(itemdata.HeadPortraitId, itemdata.HeadFrameId, self.Head)
    
end

return XUiGridRankItem