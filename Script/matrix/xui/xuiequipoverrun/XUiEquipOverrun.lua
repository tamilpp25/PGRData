local XUiEquipOverrun = XLuaUiManager.Register(XLuaUi, "UiEquipOverrun")
local XUiEquipOverrunDetail = require("XUi/XUiEquipOverrun/XUiEquipOverrunDetail")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

function XUiEquipOverrun:OnAwake()
    self.CostGridList = {}
    self.GridCostItem.gameObject:SetActiveEx(false)
    self:SetButtonCallBack()
end

function XUiEquipOverrun:OnStart(equipId, parent)
    self.EquipId = equipId
    self.Parent = parent

    self.Equip = XDataCenter.EquipManager.GetEquip(equipId)
    self.OverrunCfgs = XEquipConfig.GetWeaponOverrunCfgsByTemplateId(self.Equip.TemplateId)

    self.UiEquipOverrunDetail = XUiEquipOverrunDetail.New(self, self.panelEquipOverrun)
    self.UiEquipOverrunDetail:SetEquipId(equipId)
end

function XUiEquipOverrun:OnEnable()
    self.UiEquipOverrunDetail:Refresh()
    self:RefreshLvUp()
end

function XUiEquipOverrun:OnDestroy()
    if self.LevelRefreshTimer then
        XScheduleManager.UnSchedule(self.LevelRefreshTimer)
        self.LevelRefreshTimer = nil
    end
end

function XUiEquipOverrun:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnOverrun, self.OnClickBtnOverrun)
end

function XUiEquipOverrun:OnClickBtnOverrun()
    if self.LevelRefreshTimer then
        return
    end

    if not self.CanLevelUp then
        XUiManager.TipText("PokemonUpgradeItemNotEnough")
        return
    end

    XMVCA:GetAgency(ModuleId.XEquip):EquipWeaponOverrunLevelUpRequest(self.EquipId, function()
        self:OnLevelUp()
    end)
end

function XUiEquipOverrun:OnLevelUp()
    -- 播放升级特效
    self.Parent:PlayOverrunLevelUpEffect()
    self.UiEquipOverrunDetail:Refresh()
    self:RefreshLvUp()
    self.Parent:UpdateBtnOverrunRed()

    -- 刷新界面
    local level = self.Equip:GetOverrunLevel()
    local deregulateUICfg = XEquipConfig.GetWeaponDeregulateUICfg(level)
    local waitTime = deregulateUICfg.SceneStartEffectTime or 0
    self.LevelRefreshTimer = XScheduleManager.ScheduleOnce(function()
        self.LevelRefreshTimer = nil
        self.Parent:UpdateOverrunSceneEffect()

        -- 弹窗
        local equipId = self.EquipId
        XLuaUiManager.Open("UiEquipOverrunLevel", equipId, level)
    end , waitTime)
end

-- 刷新升级所需道具
function XUiEquipOverrun:RefreshLvUp()
    local curLv = self.Equip:GetOverrunLevel()
    local isMaxLv = curLv >= #self.OverrunCfgs
    local nextCfg = self.OverrunCfgs[curLv + 1]
    self.CanLevelUp = true
    self.PanelConst.gameObject:SetActiveEx(not isMaxLv)
    if not isMaxLv then
        for _, grid in ipairs(self.CostGridList) do
            grid.GameObject:SetActiveEx(false)
        end
        for i, itemId in ipairs(nextCfg.ConsumeItemIds) do
            local data = {}
            data.TemplateId = itemId
            data.CostCount = nextCfg.ConsumeItemCounts[i]
            data.Count = XDataCenter.ItemManager.GetCount(itemId)
            if data.Count < data.CostCount then
                self.CanLevelUp = false
            end

            local grid = self.CostGridList[i]
            if not grid then
                local go = CSInstantiate(self.GridCostItem, self.GridCostItem.transform.parent)
                grid = XUiGridCommon.New(self, go)
                table.insert(self.CostGridList, grid)
            end
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(data)
        end
    end
end

return XUiEquipOverrun