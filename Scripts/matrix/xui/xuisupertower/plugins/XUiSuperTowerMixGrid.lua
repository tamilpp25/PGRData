--=================
--混合型插件\增益类控件
--=================
local XUiSuperTowerMixGrid = XClass(nil, "XUiSuperTowerMixGrid")

function XUiSuperTowerMixGrid:Ctor(uiGameObject, onClickCallBack)
    self:Init(uiGameObject, onClickCallBack)
end

function XUiSuperTowerMixGrid:Init(uiGameObject, onClickCallBack)
    XTool.InitUiObjectByUi(self, uiGameObject)
    if onClickCallBack then
        self.OnClickCb = onClickCallBack
    end
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function()
            self:OnClick()
        end)
end

--===================
--使用配置更新UI
--@param itemType道具类型:XSuperTowerManager.ItemType
--===================
function XUiSuperTowerMixGrid:RefreshCfg(cfg, itemType)
    local ITEM_TYPE = XDataCenter.SuperTowerManager.ItemType
    self.ItemType = itemType
    self.ItemCfg = cfg
    if self.ItemType == ITEM_TYPE.Enhance then
        self.EnhanceId = self.ItemCfg.Id
        self.EnhanceCfg = self.ItemCfg
    elseif self.ItemType == ITEM_TYPE.Plugin then
        local pluginScript = require("XEntity/XSuperTower/Plugin/XSuperTowerPlugin")
        self.Plugin = pluginScript.New(self.ItemCfg.Id)
    end
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(self.ItemCfg.Icon)
    end
    if self.TxtName then
        self.TxtName.text = self.ItemCfg.Name
    end
    if self.ImgQuality then
        self.ImgQuality:SetSprite(XSuperTowerConfigs.GetStarIconByQuality(self.ItemCfg.Quality))
    end
    if self.ImgQualityBg then
        self.ImgQualityBg:SetSprite(XSuperTowerConfigs.GetStarBgByQuality(self.ItemCfg.Quality))
    end
end

function XUiSuperTowerMixGrid:OnClick()
    if self.OnClickCb then
        self.OnClickCb(self)
    end
end

function XUiSuperTowerMixGrid:SetIndex(index)
    self.Index = index
end

function XUiSuperTowerMixGrid:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiSuperTowerMixGrid:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiSuperTowerMixGrid:SetNormalLock(value)
    self.ImgNormalLock.gameObject:SetActiveEx(value)
end

function XUiSuperTowerMixGrid:SetFloorLock(value, text)
    self.ImgFloorLock.gameObject:SetActiveEx(value)
end

function XUiSuperTowerMixGrid:SetActiveStatus(value)
    self.ImgActive.gameObject:SetActiveEx(value)
end

function XUiSuperTowerMixGrid:SetSelectStatus(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiSuperTowerMixGrid:SetLockText(text)
    if self.TxtLock then self.TxtLock.text = text end
end

function XUiSuperTowerMixGrid:SetClickCallBack(callback)
    self.OnClickCb = callback
end

return XUiSuperTowerMixGrid