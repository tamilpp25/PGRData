local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
--===========================================================================
 ---@desc 中心枢纽界面，暂时不用
--===========================================================================
local XUiPivotCombatCenter = XLuaUiManager.Register(XLuaUi, "UiPivotCombatCenter")

function XUiPivotCombatCenter:OnAwake()
    self:InitUI()
    self:InitCB()
end 

function XUiPivotCombatCenter:OnStart()
    --初始化资产
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiPivotCombatCenter:OnEnable()
    
    self.Region = XDataCenter.PivotCombatManager.GetCenterRegion()
    --检查区域是否开放
    local isOpen, desc = self.Region:IsOpen()
    if not isOpen then
        self:Close()
        XUiManager.TipMsg(desc)
        return
    end
    --中心区域名称
    self.TxtTitle.text = self.Region:GetRegionName()
    --更新时间显示
    self.TxtTitleDate.text = self.Region:GetRegionLeftTime()
    --更新最高纪录显示
    self.TxtNum.text = XDataCenter.PivotCombatManager.GetMaxScore()
    --更新次级区域供能显示
    local secondaryRegions = XDataCenter.PivotCombatManager.GetSecondaryRegions()
    for idx, region in ipairs(secondaryRegions) do
        self["Btn0"..idx]:SetRawImage(region:GetIcon())
        self["EnergyProgressRegion"..idx].fillAmount = region:GetPercentEnergy()
    end
    
    --中心枢纽，关卡数据
    self.Stage = self.Region:GetCenterStage()
end


function XUiPivotCombatCenter:InitUI()
    self.BtnHelp.gameObject:SetActiveEx(false)
end 

function XUiPivotCombatCenter:InitCB()
    self.BtnBack.CallBack = function() 
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnEffect.CallBack = function() 
        XLuaUiManager.Open("UiPivotCombatEffectArea")
    end
    self.BtnCenter.CallBack = function()
        self:OpenChildUi("UiPivotCombatNormalDetail", self.Stage)
    end
end 