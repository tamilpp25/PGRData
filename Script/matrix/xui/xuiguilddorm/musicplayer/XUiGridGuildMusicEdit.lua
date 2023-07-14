---@class XUiGridGuildMusicEdit
local XUiGridGuildMusicEdit = XClass(nil, "XUiGridGuildEdit")

function XUiGridGuildMusicEdit:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnTop.CallBack = function()
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_TOPPING_BGM, self.Index, self.BgmId)
    end
    self.BtnDelete.CallBack = function()
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DELETE_BGM, self.Index)
    end
    self.ImgBlack = self.GameObject:FindTransform("ImgBlack")
end

function XUiGridGuildMusicEdit:Refresh(index, bgmId, isExperience)
    self.Index = index
    self.BgmId = bgmId
    local bgmCfg = XGuildDormConfig.GetBgmCfgById(bgmId)
    self.TxtListMusicName.text = bgmCfg.Name
    self.TxtListMusicDesc.text = bgmCfg.Desc
    self.TxtSerial.text = index
    self.ImgBlack.gameObject:SetActiveEx(index%2 ~= 0)
    
    -- 体验中
    self.ImgAudition.gameObject:SetActiveEx(isExperience)
end

return XUiGridGuildMusicEdit
