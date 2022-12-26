--===========================
--超级爬塔增益详细页面
--===========================
local XUiSuperTowerEnhanceDetails = XLuaUiManager.Register(XLuaUi, "UiSuperTowerEnhanceDetails")
local Vector3 = CS.UnityEngine.Vector3
function XUiSuperTowerEnhanceDetails:OnAwake()
    XTool.InitUiObject(self)
    self.BtnEquip.gameObject:SetActiveEx(false)
    self.BtnUnEquip.gameObject:SetActiveEx(false)
end
--==================
--界面显示时
--@param pluginId: 插件Id
--@param posXOffset: 左右位置偏移(0或不填为屏幕中间，往右移为正数，左移为负数)
--==================
function XUiSuperTowerEnhanceDetails:OnStart(enhanceId, posXOffset, closeCallBack)
    self:FixPos(posXOffset or 0)
    self:InitEnhanceCfg(enhanceId)
    self:InitGrids()
    self.CloseCallBack = closeCallBack
    XUiHelper.RegisterClickEvent(self, self.BtnClose, function() self:OnClose() end)
    self:ShowPanel()
end
--==================
--调整界面X轴(左右)位置
--==================
function XUiSuperTowerEnhanceDetails:FixPos(posXOffset)
    self.Transform.localPosition = self.Transform.localPosition + Vector3(posXOffset, 0, 0)
end
--==================
--初始化插件配置
--==================
function XUiSuperTowerEnhanceDetails:InitEnhanceCfg(enhanceId)
    self.EnhanceId = enhanceId
    self.EnhanceCfg = XSuperTowerConfigs.GetEnhanceCfgById(enhanceId)
end
--==================
--初始化控件
--==================
function XUiSuperTowerEnhanceDetails:InitGrids()
    local gridScript = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerEnhanceGrid")
    self.EnhanceGrid = gridScript.New(self.GridPlugin)
    local characterScript = require("XUi/XUiSuperTower/Plugins/XUiSTPluginDetailsRoleHead")
    self.RoleGrid = characterScript.New(self.GridRole)
end
--==================
--显示面板
--==================
function XUiSuperTowerEnhanceDetails:ShowPanel()
    self:ShowName()
    self:ShowDescription()
    self:ShowGrid()
    self:ShowRoleHead()
end
--==================
--显示插件名称
--==================
function XUiSuperTowerEnhanceDetails:ShowName()
    if self.TxtName then
        self.TxtName.text = self.EnhanceCfg.Name
    end
end
--==================
--显示插件效果
--==================
function XUiSuperTowerEnhanceDetails:ShowDescription()
    if self.TxtDesc then
        self.TxtDesc.text = self.EnhanceCfg.Description
    end
end
--==================
--显示图标
--==================
function XUiSuperTowerEnhanceDetails:ShowGrid()
    self.EnhanceGrid:RefreshData(self.EnhanceId)
end
--==================
--显示头像
--==================
function XUiSuperTowerEnhanceDetails:ShowRoleHead()
    local characterId = self.EnhanceCfg.CharacterId
    local haveCharacter = characterId and characterId > 0
    if haveCharacter then
        self.RoleGrid:Show()
        self.RoleGrid:RefreshData(characterId)
    else
        self.RoleGrid:Hide()
    end
end
--==================
--关闭面板时
--==================
function XUiSuperTowerEnhanceDetails:OnClose()
    self:Close()
    if self.CloseCallBack then
        local cb = self.CloseCallBack
        self.CloseCallBack = nil
        cb()
    end
end