--阶段描述
local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("61A27A"),
    [false] = CS.UnityEngine.Color.gray,
}
--金币花费
local LEVEL_UP_CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = XUiHelper.Hexcolor2Color("FC8686"),
}

local COLOR_CONDITION_FUNC = {
    [XDoubleTowersConfigs.ModuleType.Role] = function(level, pluginLevel) 
        return level >= pluginLevel
    end,
    [XDoubleTowersConfigs.ModuleType.Guard] = function(level, pluginLevel) 
        return level == pluginLevel
    end
}

--动作塔防插件弹窗
local XUiDoubleTowersSkillDetails = XLuaUiManager.Register(XLuaUi, "UiDoubleTowersSkillDetails")

function XUiDoubleTowersSkillDetails:OnAwake()
    self.BaseInfo = XDataCenter.DoubleTowersManager.GetBaseInfo()
    self.TeamDb = self.BaseInfo:GetTeamDb()
    self.TxtSkillDesA2.gameObject:SetActiveEx(false)
    self:InitButtons()
end

--pluginId：DoubleTowerPlugin表的Id
--slotChangeCb：装备、卸下、替换导致插槽变化时回调
--slotIndex：插槽下标，可为空
function XUiDoubleTowersSkillDetails:OnStart(pluginId, slotChangeCb, slotIndex)
    self.PluginId = pluginId
    self.SlotChangeCb = slotChangeCb
    self.SlotIndex = slotIndex or -1

    --插件图标
    local icon = XDoubleTowersConfigs.GetPluginIcon(pluginId)
    self.PartnerIcon:SetRawImage(icon)
    --各等级列表
    self:InitTxtSkillDes()
    --消耗的道具图标
    local rewardItemId = XDoubleTowersConfigs.GetActivityRewardItemId()
    local costIcon = XItemConfigs.GetItemIconById(rewardItemId)
    self.IconLevelUp:SetRawImage(costIcon)
end

function XUiDoubleTowersSkillDetails:OnEnable()
    self:Refresh()
end

function XUiDoubleTowersSkillDetails:InitTxtSkillDes()
    self.TxtSkillDesList = {}   --插件详情文本列表
    self.TxtSkillPosList = {}   --插件等级文本列表
    self.TxtSkillDes.gameObject:SetActiveEx(false)
    local pluginLevelIdList = XDoubleTowersConfigs.GetPluginLevelIdList(self.PluginId)
    for i, pluginLevelId in ipairs(pluginLevelIdList) do
        local txtSkillDes = i == 1 and self.TxtSkillDes or XUiHelper.Instantiate(self.TxtSkillDes, self.PanelContent)
        local txtSkillPos = i == 1 and self.TxtSkillPos or txtSkillDes.transform:Find("TxtSkillPos"):GetComponent("Text")
        txtSkillDes.gameObject:SetActiveEx(true)
        txtSkillPos.gameObject:SetActiveEx(true)
        self.TxtSkillDesList[i] = txtSkillDes
        self.TxtSkillPosList[i] = txtSkillPos

        txtSkillDes.text = XDoubleTowersConfigs.GetPluginLevelDesc(pluginLevelId)
        txtSkillPos.text = XUiHelper.GetText("DoubleTowersLevel", XDoubleTowersConfigs.GetPluginLevel(pluginLevelId))
    end
end

function XUiDoubleTowersSkillDetails:InitButtons()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.TxtReset, self.OnResetClick)
    self:RegisterClickEvent(self.BtnStrengthen, self.OnBtnStrengthenClick)
    self:RegisterClickEvent(self.BtnTakeOff, self.OnBtnTakeOffClick)
    self:RegisterClickEvent(self.BtnPutOn, self.OnBtnPutOnClick)
end

function XUiDoubleTowersSkillDetails:Refresh()
    local baseInfo = self.BaseInfo
    local pluginId = self.PluginId
    local pluginDb = baseInfo:GetPluginDb(pluginId)
    local level
    local isLock
    --可能是点击解锁
    if XTool.IsTableEmpty(pluginDb) then
        isLock = true
        level = 0
    else
        isLock = false
        level = pluginDb:GetLevel()
    end
    local nextLevelId = baseInfo:GetPluginNextLevelId(pluginId) --插件下一等级Id
    local pluginLevelId = XDoubleTowersConfigs.GetPluginLevelId(pluginId, level) --插件当前等级Id
    local defaultPluginLevelId = baseInfo:GetPluginLevelDefaultId(pluginId) --如果当前等级Id无效，则用默认id来获取数据
    local rewardItemId = XDoubleTowersConfigs.GetActivityRewardItemId() --升级消耗的道具Id
    local hasCostCount = XDataCenter.ItemManager.GetCount(rewardItemId) --升级消耗的道具持有量
    --升级的消耗或者激活的消耗
    local costCount = XTool.IsNumberValid(nextLevelId) and XDoubleTowersConfigs.GetPluginLevelUpgradeSpend(nextLevelId)
            or XDoubleTowersConfigs.GetPluginLevelUpgradeSpend(defaultPluginLevelId)

    --插件名
    self.TxtName.text = XDoubleTowersConfigs.GetPluginLevelName(pluginLevelId)
    --等级
    self.TxtSubSkillLevel.text = level
    --各等级列表
    self:UpdateTxtSkillDes(level)
    --升级相关
    local isLevelUp = hasCostCount >= costCount
    self.TextCost.text = costCount
    self.TextCost.color = LEVEL_UP_CONDITION_COLOR[isLevelUp]
    local maxLevel = XDoubleTowersConfigs.GetPluginMaxLevel(pluginId)
    local isLevelMax = level >= maxLevel
    --local isUnlock = XTool.IsNumberValid(level)
    self.TextCost.gameObject:SetActiveEx(not isLevelMax)
    self.IconLevelUp.gameObject:SetActiveEx(not isLevelMax)
    self.BtnStrengthen:SetDisable(not isLevelUp)
    self.BtnStrengthen.gameObject:SetActiveEx(not isLevelMax)
    local strengthenName = isLock and XUiHelper.GetText("Active") or XUiHelper.GetText("Upgrade")
    self.BtnStrengthen:SetName(strengthenName)
    --装备和卸下按钮
    local isEquip, equipSlotIndex = self.TeamDb:IsEquipPlugin(pluginId)
    local putOnName = equipSlotIndex == self.SlotIndex and XUiHelper.GetText("Replace") or XUiHelper.GetText("PutOn")
    self.BtnPutOn:SetName(putOnName)
    self.BtnPutOn.gameObject:SetActiveEx(not isEquip and not isLock)
    self.BtnTakeOff.gameObject:SetActiveEx(isEquip and not isLock)
    --重置按钮
    local defaultPluginId = XDoubleTowersConfigs.GetRoleDefaultPluginId()
    local isShowTxtRest = true
    --如果是默认插件，并且等级等于1则不显示重置按钮
    if defaultPluginId == pluginId and level == 1 then
        isShowTxtRest = false
    end
    self.TxtReset.gameObject:SetActiveEx(not isLock and isShowTxtRest)
    end

function XUiDoubleTowersSkillDetails:UpdateTxtSkillDes(level)
    local pluginLevel
    local color
    local pluginLevelIdList = XDoubleTowersConfigs.GetPluginLevelIdList(self.PluginId)
    local moduleType = XDataCenter.DoubleTowersManager.GetSelectModuleType()
    local func = COLOR_CONDITION_FUNC[moduleType]
    for i, pluginLevelId in ipairs(pluginLevelIdList) do
        pluginLevel = XDoubleTowersConfigs.GetPluginLevel(pluginLevelId)
        local condition = func and func(level, pluginLevel) or false
        color = CONDITION_COLOR[condition]
        self.TxtSkillDesList[i].color = color
        self.TxtSkillPosList[i].color = color
    end
end

--重置
function XUiDoubleTowersSkillDetails:OnResetClick()
    if not XTool.IsNumberValid(self.PluginId) then
        return
    end

    XDataCenter.DoubleTowersManager.RequestDoubleTowerResetPlugin({ self.PluginId }, function()
        --如果在装备槽上，需要先卸载下来
        local isEquip, equipSlotIndex = self.TeamDb:IsEquipPlugin(self.PluginId)
        if  isEquip or XTool.IsNumberValid(equipSlotIndex) then
            local defaultPluginId = XDoubleTowersConfigs.GetRoleDefaultPluginId()
            local moduleType = XDataCenter.DoubleTowersManager.GetSelectModuleType()
            --如果是角色的默认插件，则不卸载
            if moduleType ~= XDoubleTowersConfigs.ModuleType.Role or defaultPluginId ~= self.PluginId then
                self.TeamDb:UnloadPlugin(moduleType, equipSlotIndex)
            end
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_PLUGIN_CHANGE, self.PluginId)
        if self.SlotChangeCb then
            self.SlotChangeCb(self.PluginId)
        end
        self:Close()

        XDataCenter.DoubleTowersManager.RequestDoubleTowerSetTeam()
    end)
end

--升级
function XUiDoubleTowersSkillDetails:OnBtnStrengthenClick()
    local maxLv = XDoubleTowersConfigs.GetPluginMaxLevel(self.PluginId)
    local pluginDb = self.BaseInfo:GetPluginDb(self.PluginId)
    local isActive = XTool.IsTableEmpty(pluginDb)
    if not isActive then
        local curLv = pluginDb:GetLevel()
        if curLv >= maxLv then
            XUiManager.TipText("DoubleTowersMaxPluginTips")
            return
        end
    end

    XDataCenter.DoubleTowersManager.RequestDoubleTowerUpgradePlugin(self.PluginId, function(pluginId)
        if self.SlotChangeCb then
            self.SlotChangeCb(pluginId)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_PLUGIN_CHANGE, self.PluginId)
        self:Refresh()
    end)
end

--装备
function XUiDoubleTowersSkillDetails:OnBtnPutOnClick()
    if self.SlotIndex <= 0 then
        XUiManager.TipText("DoubleTowersNoChooseSlotTips")
        return
    end
    local moduleType = XDataCenter.DoubleTowersManager.GetSelectModuleType()
    self.TeamDb:EquipPlugin(moduleType, self.SlotIndex, self.PluginId)

    local func = XDataCenter.DoubleTowersManager.ShowEquipTips
    if func then
        func(XUiHelper.GetText("DoubleTowersPluginEquip"))
    end

    if self.SlotChangeCb then
        self.SlotChangeCb(self.PluginId)
    end
    self:Close()
    XDataCenter.DoubleTowersManager.RequestDoubleTowerSetTeam()
end

--卸下
function XUiDoubleTowersSkillDetails:OnBtnTakeOffClick()
    local isEquip, equipSlotIndex = self.TeamDb:IsEquipPlugin(self.PluginId)
    if not isEquip or equipSlotIndex <= 0 then return end
    local moduleType = XDataCenter.DoubleTowersManager.GetSelectModuleType()

    if moduleType == XDoubleTowersConfigs.ModuleType.Role then
        local list = self.TeamDb:GetPluginList(moduleType)
        local count = 0
        for _, id in pairs(list) do
            if XTool.IsNumberValid(id) then
                count = count + 1
            end
        end
        if count == 1 then
            XUiManager.TipText("DoubleTowersMustLeftOne")
            return
        end
    end
    --可能卸载失败
    local state = self.TeamDb:UnloadPlugin(moduleType, equipSlotIndex)
    if state then
        local func = XDataCenter.DoubleTowersManager.ShowEquipTips
        if func then
            func(XUiHelper.GetText("DoubleTowersPluginTakeOff"))
        end

        if self.SlotChangeCb then
            self.SlotChangeCb(self.PluginId)
        end
        self:Close()
    end
    XDataCenter.DoubleTowersManager.RequestDoubleTowerSetTeam()
end