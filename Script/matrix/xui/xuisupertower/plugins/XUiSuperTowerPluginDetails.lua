--===========================
--超级爬塔芯片详细页面
--===========================
local XUiSuperTowerPluginDetails = XLuaUiManager.Register(XLuaUi, "UiSuperTowerPluginDetails")
local Vector3 = CS.UnityEngine.Vector3
function XUiSuperTowerPluginDetails:OnAwake()
    XTool.InitUiObject(self)
end
--==================
--界面显示时
--@param pluginId: 插件Id
--@param posXOffset: 左右位置偏移(0或不填为屏幕中间，往右移为正数，左移为负数)
--==================
function XUiSuperTowerPluginDetails:OnStart(plugin, posXOffset, closeCallBack, isEquip, equipCallBack)
    self:FixPos(posXOffset or 0)
    self:InitPluginCfg(plugin)
    self:InitGrids()
    self.CloseCallBack = closeCallBack
    if isEquip ~= nil then
        self.IsEquipment = isEquip
        self.BtnEquip.CallBack = function() self:OnClickBtnEquip() end
        self.BtnUnEquip.CallBack = function() self:OnClickBtnUnEquip() end
        self.EquipCallBack = equipCallBack
        self.UnEquipCallBack = equipCallBack
    end
    XUiHelper.RegisterClickEvent(self, self.BtnClose, function() self:OnClose() end)
    self:ShowPanel()
end
--==================
--调整界面X轴(左右)位置
--==================
function XUiSuperTowerPluginDetails:FixPos(posXOffset)
    self.PanelDetail.transform.localPosition = self.PanelDetail.transform.localPosition + Vector3(posXOffset, 0, 0)
end
--==================
--初始化插件配置
--==================
function XUiSuperTowerPluginDetails:InitPluginCfg(plugin)
    self.PluginId = plugin:GetId()
    self.Plugin = plugin
end
--==================
--初始化控件
--==================
function XUiSuperTowerPluginDetails:InitGrids()
    local gridScript = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
    self.PluginGrid = gridScript.New(self.GridPlugin)
    local characterScript = require("XUi/XUiSuperTower/Plugins/XUiSTPluginDetailsRoleHead")
    self.RoleGrid = characterScript.New(self.GridRole)
end
--==================
--显示面板
--==================
function XUiSuperTowerPluginDetails:ShowPanel()
    self:ShowPluginName()
    self:ShowDescription()
    self:ShowPluginGrid()
    self:ShowBtnEquip()
    self:ShowRoleHead()
end
--==================
--显示插件名称
--==================
function XUiSuperTowerPluginDetails:ShowPluginName()
    if self.TxtName then
        self.TxtName.text = self.Plugin:GetName()
    end
    if self.TxtQuality then
        self.TxtQuality.text = XUiHelper.GetText("STPluginDetailsStarStr", self.Plugin:GetQuality()) 
    end
end
--==================
--显示插件效果
--==================
function XUiSuperTowerPluginDetails:ShowDescription()
    if self.TxtDesc then
        self.TxtDesc.text = self.Plugin:GetDesc()
    end
end
--==================
--显示图标
--==================
function XUiSuperTowerPluginDetails:ShowPluginGrid()
    self.PluginGrid:RefreshData(self.Plugin)
end
--==================
--显示装备按钮
--==================
function XUiSuperTowerPluginDetails:ShowBtnEquip()
    self.BtnEquip.gameObject:SetActiveEx(self.IsEquipment ~= nil and self.IsEquipment == true)
    self.BtnUnEquip.gameObject:SetActiveEx(self.IsEquipment ~= nil and self.IsEquipment == false)
end
--==================
--显示头像
--==================
function XUiSuperTowerPluginDetails:ShowRoleHead()
    local characterId = self.Plugin:GetCharacterId()
    local haveCharacter = characterId and characterId > 0
    if haveCharacter then
        if self.PanelChara then self.PanelChara.gameObject:SetActiveEx(true) end
        self.RoleGrid:RefreshData(characterId)
    else
        if self.PanelChara then self.PanelChara.gameObject:SetActiveEx(false) end
    end
end
--==================
--点击装备时
--==================
function XUiSuperTowerPluginDetails:OnClickBtnEquip()
    if self.IsEquipment == nil then return end
    if self.EquipCallBack then
        local cb = self.EquipCallBack
        self.EquipCallBack = nil
        cb(self.PluginId)
        self:OnClose()
    end
end
--==================
--点击卸下时
--==================
function XUiSuperTowerPluginDetails:OnClickBtnUnEquip()
    if self.IsEquipment == nil then return end
    if self.UnEquipCallBack then
        local cb = self.UnEquipCallBack
        self.UnEquipCallBack = nil
        cb(self.PluginId)
        self:OnClose()
    end
end
--==================
--关闭面板时
--==================
function XUiSuperTowerPluginDetails:OnClose()
    self:Close()
    if self.CloseCallBack then
        local cb = self.CloseCallBack
        self.CloseCallBack = nil
        cb()
    end
end