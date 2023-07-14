--===========================
--超级爬塔背包页面
--===========================
local XUiSuperTowerBag = XLuaUiManager.Register(XLuaUi, "UiSuperTowerCall")
--子面板序号
local CHILD_PANEL_INDEX = {
        Toggle = 1, --页签
        Capacity = 2, --容量显示
        Plugins = 3, --背包芯片列表
        ShopBtn = 4, --商店按钮
        DecomposionBtn = 5, --分解按钮
        LineGraph = 6, --容量条形示意图
        IllustratedBook = 7, --图鉴
        Decomposion = 8, --分解
    }
--子面板路径
local CHILD_PANEL_SCRIPT_PATH = "XUi/XUiSuperTower/Bag/XUiSTBag"
--页签类型
local TOGGLE_TYPE_INDEX = {
    Bag = 1, --背包
    IllustratedBook = 2, --图鉴
}
--页面类型
local PAGE_TYPE = {
    Bag = 1, -- 背包
    IllustratedBook = 2, -- 图鉴
    Decomposion = 3, -- 分解
    }
--显示资源键值
local ASSETS_KEY = "BagAssetsPanelItem"

function XUiSuperTowerBag:OnAwake()
    XTool.InitUiObject(self)
    self.FirstIn = true
end

function XUiSuperTowerBag:OnStart()
    self:InitBagData()
    self:InitTopBtns()
    self:InitPanelAssets()
    self:InitChildPanelControl()
    self:ShowPanels()
    self:SetActivityTimeLimit()
end

function XUiSuperTowerBag:InitBagData()
    self.BagManager = XDataCenter.SuperTowerManager.GetBagManager()
end

function XUiSuperTowerBag:InitChildPanelControl()
    local script = require("XUi/XUiSuperTower/Common/XUiSTMainPage")
    self.ChildPanelControl = script.New(self)
    self.ChildPanelControl:RegisterChildPanels(CHILD_PANEL_INDEX, CHILD_PANEL_SCRIPT_PATH)
end

function XUiSuperTowerBag:InitTopBtns()
    self.BtnBack.CallBack = function() self:OnClickBackBtn() end
    self.BtnMainUi.CallBack = function() self:OnClickMainUiBtn() end
    self:BindHelpBtn(self.BtnHelp, "SuperTowerBagHelp")
end

function XUiSuperTowerBag:InitPanelAssets()
    local itemIds = {}
    for i = 1, 3 do
        local itemId = XSuperTowerConfigs.GetClientBaseConfigByKey(XDataCenter.SuperTowerManager.BaseCfgKey[ASSETS_KEY .. i], true)
        if itemId and itemId ~= 0 then
            table.insert(itemIds, itemId)
        end
    end
    local asset = XUiPanelAsset.New(self, self.PanelAssets, itemIds[1], itemIds[2], itemIds[3])
    asset:RegisterJumpCallList({
            [1] = function()
                XLuaUiManager.Open("UiTip", itemIds[1])
            end,
            [2] = function()
                XLuaUiManager.Open("UiTip", itemIds[2])
            end,
            [3] = function()
                XLuaUiManager.Open("UiTip", itemIds[3])
            end
            })
end

function XUiSuperTowerBag:OnClickBackBtn()
    if self.PageType == PAGE_TYPE.Decomposion then
        self:ShowPageBag()
    else
        self:Close()
    end
end

function XUiSuperTowerBag:OnClickMainUiBtn()
    XLuaUiManager.RunMain()
end

function XUiSuperTowerBag:ShowPageBag()
    self.PageType = PAGE_TYPE.Bag
    local showIndexGroup = {
            [CHILD_PANEL_INDEX.Toggle] = true,
            [CHILD_PANEL_INDEX.Capacity] = true,
            [CHILD_PANEL_INDEX.Plugins] = true,
            [CHILD_PANEL_INDEX.LineGraph] = true,
            [CHILD_PANEL_INDEX.ShopBtn] = true,
            [CHILD_PANEL_INDEX.DecomposionBtn] = true,
        }
    self.ChildPanelControl:ShowChildPanel(showIndexGroup)
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.Plugins, "RefreshBag")
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.LineGraph, "Refresh")
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.Capacity, "Refresh")
    if self.FirstIn then
        self.FirstIn = false
    else
        self:PlayAnimation("QieHuan")
    end
end

function XUiSuperTowerBag:ShowPageIllustratedBook()
    self.PageType = PAGE_TYPE.IllustratedBook
    local showIndexGroup = {
        [CHILD_PANEL_INDEX.Toggle] = true,
        [CHILD_PANEL_INDEX.IllustratedBook] = true,
    }
    self.ChildPanelControl:ShowChildPanel(showIndexGroup)
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.IllustratedBook, "Refresh")
    if self.FirstIn then
        self.FirstIn = false
    else
        self:PlayAnimation("QieHuan")
    end
end

function XUiSuperTowerBag:ShowDecomposion()
    self.PageType = PAGE_TYPE.Decomposion
    local showIndexGroup = {
        [CHILD_PANEL_INDEX.Capacity] = true,
        [CHILD_PANEL_INDEX.Plugins] = true,
        [CHILD_PANEL_INDEX.LineGraph] = true,
        [CHILD_PANEL_INDEX.Decomposion] = true,
    }
    self.ChildPanelControl:ShowChildPanel(showIndexGroup)
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.Plugins, "RefreshDecomposion")
    self:PlayAnimation("PanelDecomposionEanble")
end

function XUiSuperTowerBag:ShowPanels()
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.Toggle, "SelectToggle", TOGGLE_TYPE_INDEX.Bag)
end
--=============
--背包插件列表选中对应星数
--=============
function XUiSuperTowerBag:PluginsSelectStar(star)
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.Plugins, "SelectStar", star)
end
--=============
--背包插件列表反选对应星数
--=============
function XUiSuperTowerBag:PluginsUnSelectStar(star)
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.Plugins, "UnSelectStar", star)
end

function XUiSuperTowerBag:OnDecomposeListRefresh(decomposionList)
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.Decomposion, "OnDecomposeListRefresh", decomposionList)
end

function XUiSuperTowerBag:ResetDecomposion()
    self.ChildPanelControl:DoFunction(CHILD_PANEL_INDEX.Plugins, "ResetDecomposion")
end

function XUiSuperTowerBag:OnEnable()
    XUiSuperTowerBag.Super.OnEnable(self)
    self.ChildPanelControl:OnEnable()
    self:AddEventListener()
end

function XUiSuperTowerBag:OnDisable()
    XUiSuperTowerBag.Super.OnDisable(self)
    self.ChildPanelControl:OnDisable()
    self:RemoveEventListener()
end

function XUiSuperTowerBag:OnDestroy()
    self.ChildPanelControl:OnDestroy()
    self:RemoveEventListener()
end

function XUiSuperTowerBag:AddEventListener()
    if self.EventAdded then return end
    
end

function XUiSuperTowerBag:RemoveEventListener()
    if not self.EventAdded then return end
end

function XUiSuperTowerBag:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperTowerManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperTowerManager.HandleActivityEndTime()
            end
        end)
end