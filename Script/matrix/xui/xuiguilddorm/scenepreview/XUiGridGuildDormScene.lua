---@class XUiGridGuildDormScene
---@field Btn XUiComponent.XUiButton
---@field Select UnityEngine.RectTransform
---@field DressedTip UnityEngine.RectTransform
---@field RImgBg UnityEngine.UI.RawImage
local XUiGridGuildDormScene = XClass(nil, "XUiGridGuildDormScene")

function XUiGridGuildDormScene:Ctor(transform,clickCallBack)
    self.Transform = transform
    self.GameObject = transform.gameObject
    XTool.InitUiObject(self)
    self.CallBack = clickCallBack
    self.Btn.CallBack = function()
        if self.CallBack then
            self.CallBack(self.Id)
        end
    end
end

function XUiGridGuildDormScene:Refresh(id)
    self.Id = id
    local config = XGuildDormConfig.GetThemeCfgById(id)
    self.RImgBg:SetRawImage(config.Image)
    local currThemeId = XDataCenter.GuildDormManager.GetThemeId()
    self.DressedTip.gameObject:SetActiveEx(config.Id == currThemeId)
    -- 试用
    local isTime = XFunctionManager.CheckInTimeByTimeId(config.TimeId)
    self.DressedTrial.gameObject:SetActiveEx(isTime)
end

function XUiGridGuildDormScene:SetSelect(isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)
end

return XUiGridGuildDormScene