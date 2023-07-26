--战斗详情界面 推荐插件格子
local XUIBrilliantWalkStageDetailPluginGrid = XClass(nil, "XUIBrilliantWalkStageDetailPluginGrid")

function XUIBrilliantWalkStageDetailPluginGrid:Ctor(perfabObject, rootUi)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.BtnGo.CallBack = function()
        self:OnBtnGoClick()
    end
end

function XUIBrilliantWalkStageDetailPluginGrid:Refresh(pluginId)
    self.PluginId = pluginId
    local config = XBrilliantWalkConfigs.GetBuildPluginConfig(pluginId)
    self.TxtName.text = config.Name
    if not (config.Icon == 0) then
        self.RImgIcon:SetRawImage(config.Icon)
    end
end

function XUIBrilliantWalkStageDetailPluginGrid:SetEquiped(equiped)
    self.BtnGo.gameObject:SetActiveEx((not equiped))
end


function XUIBrilliantWalkStageDetailPluginGrid:OnBtnGoClick()
    self.RootUi:OnPluginSkipClick(self.PluginId)
end


return XUIBrilliantWalkStageDetailPluginGrid