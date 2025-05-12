---@class XUiGridScoreTowerStagePlugin : XUiNode
---@field private _Control XScoreTowerControl
---@field BtnSelect XUiComponent.XUiButton
local XUiGridScoreTowerStagePlugin = XClass(XUiNode, "XUiGridScoreTowerStagePlugin")

function XUiGridScoreTowerStagePlugin:OnStart(OnSelectCallback, OnPlayCallback)
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnPlay, self.OnBtnPlayClick, nil, true)
    self.OnSelectCallback = OnSelectCallback
    self.OnPlayCallback = OnPlayCallback
end

---@param pluginId number 插件ID
function XUiGridScoreTowerStagePlugin:Refresh(pluginId)
    self.PluginId = pluginId
    self:RefreshInfo()
end

function XUiGridScoreTowerStagePlugin:RefreshInfo()
    -- 插件图标
    local plugIcon = self._Control:GetPlugIcon(self.PluginId)
    if not string.IsNilOrEmpty(plugIcon) then
        self.RImgPlugin:SetRawImage(plugIcon)
    end
    -- 插件描述
    self.TxtDetail.text = self._Control:GetPlugDesc(self.PluginId)
    -- 插件点数图标
    local plugPointIcon = self._Control:GetClientConfig("PlugPointIcon")
    if not string.IsNilOrEmpty(plugPointIcon) then
        self.ImgIcon:SetSprite(plugPointIcon)
    end
    -- 插件点数
    self.TxtNum.text = self._Control:GetPlugNeedPoint(self.PluginId)
    -- 是否显示选中按钮
    self.BtnSelect.gameObject:SetActiveEx(self.OnSelectCallback ~= nil)
    -- 是否显示播放按钮
    local plugVideo = self._Control:GetPlugVideo(self.PluginId)
    self.BtnPlay.gameObject:SetActiveEx(not string.IsNilOrEmpty(plugVideo) and self.OnPlayCallback ~= nil)
end

-- 设置选择状态
---@param isSelected boolean 是否选中
function XUiGridScoreTowerStagePlugin:SetSelected(isSelected)
    if self.BtnSelect then
        self.BtnSelect:SetButtonState(isSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
end

function XUiGridScoreTowerStagePlugin:OnBtnSelectClick()
    if self.OnSelectCallback then
        self.OnSelectCallback(self.PluginId, self)
    end
end

function XUiGridScoreTowerStagePlugin:OnBtnPlayClick()
    if self.OnPlayCallback then
        self.OnPlayCallback(self.PluginId)
    end
end

return XUiGridScoreTowerStagePlugin
