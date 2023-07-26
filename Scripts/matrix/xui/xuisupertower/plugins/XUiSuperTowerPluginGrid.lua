--===========================
--超级爬塔芯片控件
--===========================
local XUiSuperTowerPluginGrid = XClass(nil, "XUiSuperTowerPluginGrid")

function XUiSuperTowerPluginGrid:Ctor(uiGameObject, onClickCallBack)
    self.IsClickShowDetail = false
    self:Init(uiGameObject, onClickCallBack)
end

function XUiSuperTowerPluginGrid:Init(uiGameObject, onClickCallBack)
    XTool.InitUiObjectByUi(self, uiGameObject)
    if onClickCallBack then
        self.OnClickCb = onClickCallBack
    end
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function()
            self:OnClick()
        end)
end
--===================
--设置点击是否展示详情
--===================
function XUiSuperTowerPluginGrid:SetClickIsShowDetail(value)
    self.IsClickShowDetail = value
end
--===================
--使用插件配置更新UI
--===================
function XUiSuperTowerPluginGrid:RefreshCfg(pluginCfg)
    self.PluginCfg = pluginCfg
    local pluginScript = require("XEntity/XSuperTower/Plugin/XSuperTowerPlugin")
    self.Plugin = pluginScript.New(pluginCfg.Id)
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(pluginCfg.Icon)
    end
    if self.TxtName then
        self.TxtName.text = pluginCfg.Name
    end
    if self.ImgQuality then
        self.ImgQuality:SetSprite(XSuperTowerConfigs.GetStarIconByQuality(pluginCfg.Quality))
    end
    if self.ImgQualityBg then
        self.ImgQualityBg:SetSprite(XSuperTowerConfigs.GetStarBgByQuality(pluginCfg.Quality))
    end
    self:RefreshOtherCfg(pluginCfg)
end

--===================
--使用插件对象更新UI
--===================
function XUiSuperTowerPluginGrid:RefreshData(plugin, index)
    self.Plugin = plugin
    self.Index = index
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(plugin:GetIcon())
    end
    if self.TxtName then
        self.TxtName.text = plugin:GetName()
    end
    if self.ImgQualityBg then
        self.ImgQuality:SetSprite(self.Plugin:GetQualityIcon())
    end
    if self.ImgQualityBg then
        self.ImgQualityBg:SetSprite(self.Plugin:GetQualityBg())
    end
    self:RefreshOtherData(plugin)
end
--===================
--供子类使用的更新方法，如需执行一次父类时就复写这个方法，不需要则复写RefreshData
--===================
function XUiSuperTowerPluginGrid:RefreshOtherData(plugin)

end
--===================
--供子类使用的更新方法，如需执行一次父类时就复写这个方法，不需要则复写RefreshData
--===================
function XUiSuperTowerPluginGrid:RefreshOtherCfg(pluginCfg)

end

function XUiSuperTowerPluginGrid:OnClick()
    if self.IsClickShowDetail then
        XLuaUiManager.Open("UiSuperTowerPluginDetails", self.Plugin)
    end
    if self.OnClickCb then
        self.OnClickCb(self)
    end
end

function XUiSuperTowerPluginGrid:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiSuperTowerPluginGrid:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiSuperTowerPluginGrid:SetNormalLock(value)
    self.IsLock = value
    self.ImgNormalLock.gameObject:SetActiveEx(value)
end

function XUiSuperTowerPluginGrid:SetFloorLock(value, text)
    self.IsLock = value
    self.ImgFloorLock.gameObject:SetActiveEx(value)
    self:SetLockText(text)
end

function XUiSuperTowerPluginGrid:SetActiveStatus(value)
    self.IsActive = value
    self.ImgActive.gameObject:SetActiveEx(value)
end

function XUiSuperTowerPluginGrid:SetSelectStatus(value)
    self.IsSelect = value
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiSuperTowerPluginGrid:GetPlugin()
    return self.Plugin
end

function XUiSuperTowerPluginGrid:SetLockText(text)
    if self.TxtLock then self.TxtLock.text = text end
end

function XUiSuperTowerPluginGrid:SetClickCallBack(callback)
    self.OnClickCb = callback
end

return XUiSuperTowerPluginGrid