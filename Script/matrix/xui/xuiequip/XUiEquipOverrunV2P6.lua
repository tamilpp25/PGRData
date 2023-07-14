local XUiEquipOverrunV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipOverrunV2P6")
local XUiEquipOverrunDetailV2P6 = require("XUi/XUiEquip/XUiEquipOverrunDetailV2P6")
local CSInstantiate = CS.UnityEngine.Object.Instantiate

function XUiEquipOverrunV2P6:OnAwake()
    self.CostGridList = {}
    self.GridCostItem.gameObject:SetActiveEx(false)
    self:SetButtonCallBack()
end

function XUiEquipOverrunV2P6:OnStart(parent)
    self.Parent = parent

    if not self.UiEquipOverrunDetail then
        self.UiEquipOverrunDetail = XUiEquipOverrunDetailV2P6.New(self.panelEquipOverrun, self)
    end
end

function XUiEquipOverrunV2P6:OnEnable()
    self.EquipId = self.Parent.EquipId
    self.Equip = XDataCenter.EquipManager.GetEquip(self.EquipId)
    self.OverrunCfgs = self._Control:GetWeaponOverrunCfgsByTemplateId(self.Equip.TemplateId)
    self.UiEquipOverrunDetail:SetEquipId(self.EquipId)
    self.UiEquipOverrunDetail:Refresh()
    self:RefreshLvUp()
end

function XUiEquipOverrunV2P6:OnDisable()
    self:ReleaseTimer()
end

function XUiEquipOverrunV2P6:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnOverrun, self.OnClickBtnOverrun)
end

function XUiEquipOverrunV2P6:OnClickBtnOverrun()
    if not self.CanLevelUp then
        XUiManager.TipText("PokemonUpgradeItemNotEnough")
        return
    end

    -- 二次确认
    local equipName = XMVCA:GetAgency(ModuleId.XEquip):GetEquipName(self.Equip.TemplateId)
    local content = XUiHelper.GetText("EquipOverrunLevelUpTips", equipName)
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, function()
        XMVCA:GetAgency(ModuleId.XEquip):EquipWeaponOverrunLevelUpRequest(self.EquipId, function()
            self:OnLevelUp()
        end)
    end)
end

function XUiEquipOverrunV2P6:OnLevelUp()
    -- 播放升级特效
    self.Parent:PlayOverrunLevelUpEffect()
    self.UiEquipOverrunDetail:Refresh()
    self:RefreshLvUp()
    self.Parent:UpdateBtnOverrunRed()

    -- 刷新界面
    local level = self.Equip:GetOverrunLevel()
    local equipId = self.EquipId
    local waitTime = self._Control:GetWeaponDeregulateUISceneStartEffectTime(level) or 0
    self:ReleaseTimer()
    self.LevelRefreshTimer = XScheduleManager.ScheduleOnce(function()
        self.LevelRefreshTimer = nil
        self.Parent:UpdateOverrunSceneEffect()

        -- 弹窗
        XLuaUiManager.Open("UiEquipOverrunLevel", equipId, level)
    end , waitTime)
end

-- 刷新升级所需道具
function XUiEquipOverrunV2P6:RefreshLvUp()
    local curLv = self.Equip:GetOverrunLevel()
    local isMaxLv = curLv >= #self.OverrunCfgs
    local nextCfg = self.OverrunCfgs[curLv + 1]
    self.CanLevelUp = true
    self.PanelConst.gameObject:SetActiveEx(not isMaxLv)
    self.BtnOverrun.gameObject:SetActiveEx(not isMaxLv)
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

function XUiEquipOverrunV2P6:ReleaseTimer()
    if self.LevelRefreshTimer then
        XScheduleManager.UnSchedule(self.LevelRefreshTimer)
        self.LevelRefreshTimer = nil
    end
end

return XUiEquipOverrunV2P6