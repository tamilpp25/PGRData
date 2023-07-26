---@class XUiGridGuildMusicLibrary
---@field TxtName UnityEngine.UI.Text
---@field BtnReportSubType XUiComponent.XUiButton
---@filed RImgCdFace UnityEngine.UI.RawImage
local XUiGridGuildMusicLibrary = XClass(nil, "UiGridGuildMusicLibrary")

function XUiGridGuildMusicLibrary:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnReportSubType.CallBack = function()
        if self.IsNewAdd then
            self:RemoveDormBgmIdAndSave()
            self.PanelNew.gameObject:SetActiveEx(false)
            self.IsNewAdd = false
        end
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_SELECT_BGM, self.BgmId, self)
    end
end

function XUiGridGuildMusicLibrary:Refresh(data, isSelect)
    self.BgmId = data.Id
    local bgmCfg = XGuildDormConfig.GetBgmCfgById(self.BgmId)
    self.RImgCdFace:SetRawImage(bgmCfg.Image)
    self.TxtName.text = bgmCfg.Name
    self.BtnReportSubType:SetButtonState(isSelect and XUiButtonState.Select or XUiButtonState.Normal)
    
    -- 体验中
    self.IsExperience = data.IsExperience or false
    self.ImgAudition.gameObject:SetActiveEx(self.IsExperience)
    -- 新增
    if bgmCfg.NeedBuy ~= 0 then
        local newAddBgmList = XDataCenter.GuildManager.GetNewAddDormBgmList()
        self.IsNewAdd = table.contains(newAddBgmList, self.BgmId)
    else
        self.IsNewAdd = false
    end
    self.PanelNew.gameObject:SetActiveEx(self.IsNewAdd)
end

function XUiGridGuildMusicLibrary:SetGridState(isSelect)
    self.BtnReportSubType:SetButtonState(isSelect and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiGridGuildMusicLibrary:RemoveDormBgmIdAndSave()
    local newAddBgmList =  XDataCenter.GuildManager.GetNewAddDormBgmList()
    XTool.TableRemove(newAddBgmList, self.BgmId)
    XDataCenter.GuildManager.SaveNewAddDormBgmList(newAddBgmList)
end

return XUiGridGuildMusicLibrary
