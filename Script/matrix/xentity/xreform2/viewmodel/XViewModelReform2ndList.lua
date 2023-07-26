---@class XViewModelReform2ndList
local XViewModelReform2ndList = XClass(nil, "XViewModelReform2ndList")

function XViewModelReform2ndList:Ctor()
    self.Data = {
        Pressure = false,
        TxtPressure = false,
        IsPlayPressureEffect = false,
        StageName = false,
        Pressure2NextStar = false,
        StarAmount = 0,
        StarAmountMax = 0,
        IsMatchExtraStar = false,
        TextExtraStar = false,
        ---@type XUiReformTabButtonData[]
        BtnGroup = false,
        ---@type UiReformMobData[]
        MobData = false,
        IsEnableBtnEnter = false,
        IsDisableFightChapter5 = false,
    }
    self.DataMob = {
        ---@type XUiReformPanelMobData[]
        MobList = false,
        ---@type XReformAffixData[]
        AffixList = false,
        IsDirty = false,
        MobIndexPlayEffect = false,
        Update4Affix = false,
        PlayingAnimation = false
    }
    self.DataStage = {
        Name = false,
        Number = false,
        Desc = false,
        DescTarget = false,
        IconList = false
    }

    ---@type XReform2ndStage
    self._Stage = false
    self._CurrentIndex = 1
    ---@type {MobGroup:XReform2ndMobGroup,Index:number}
    self._SelectedMob = {
        MobGroup = false,
        Index = 0,
    }
    self.MobIndex = 0
end

function XViewModelReform2ndList:OnEnable()
    self:Update()
end

function XViewModelReform2ndList:OnDisable()

end

---@param stage XReform2ndStage
function XViewModelReform2ndList:SetStage(stage)
    self._Stage = stage
    self.Data.TextExtraStar = XUiHelper.GetText("ReformExtraStar", stage:GetGoalDesc())
end

function XViewModelReform2ndList:Update()
    local data = self.Data
    local stage = self._Stage

    --region pressure
    local pressure = stage:GetPressure()
    if data.Pressure and pressure ~= data.Pressure then
        data.IsPlayPressureEffect = true
    else
        data.IsPlayPressureEffect = false
    end
    local pressureMax = stage:GetPressureMax()
    data.TxtPressure = string.format("<color=#ff8340>%d</color> / %d", pressure, pressureMax)
    data.Pressure = pressure

    local star = stage:GetStar()
    local starMax = stage:GetStarMax()
    data.StarAmount = star
    data.StarAmountMax = starMax

    local pressure2NextStar = 0
    local nextStar = star + 1
    if nextStar <= starMax then
        local pressureNextStar = stage:GetPressureByStar(nextStar)
        pressure2NextStar = pressureNextStar - pressure
    end
    if pressure2NextStar > 0 then
        data.Pressure2NextStar = XUiHelper.GetText("ReformNextStar", pressure2NextStar)
    else
        data.Pressure2NextStar = XUiHelper.GetText("ReformFullStar")
    end

    data.IsMatchExtraStar = stage:IsExtraStar()
    --endregion

    --region mob
    data.StageName = stage:GetName()
    self:UpdateMobData()
    --endregion
end

function XViewModelReform2ndList:UpdateMobData()
    local data = self.Data
    local groupArray = self._Stage:GetMonsterGroup()

    --region button group
    data.BtnGroup = {}
    for i = 1, #groupArray do
        local group = groupArray[i]
        local indexCHN = XTool.ConvertNumberString(i)
        local mobAmount = group:GetMobAmount()
        local mobAmountMax = group:GetMobAmountMax()
        local isShow = group:IsShow()
        if isShow then
            ---@class XUiReformTabButtonData
            local btnData = {
                Index = i,
                IsAdd = false,
                Text1 = XUiHelper.GetText("ReformMob", indexCHN),
                Text2 = XUiHelper.GetText("ReformMobAmount", mobAmount, mobAmountMax)
            }
            data.BtnGroup[i] = btnData
        else
            data.BtnGroup[i] = {
                Index = i,
                IsAdd = true,
            }
            break
        end
    end
    --endregion

    --region mob data
    local mobDataOld = data.MobData
    data.MobData = {}
    local groupSelected = groupArray[self._CurrentIndex]
    if not groupSelected then
        XLog.Error("[XViewModelReform2ndList] group may be wrong? " .. self._CurrentIndex)
        return
    end
    local amountMax = groupSelected:GetMobAmountMax()
    local amount = groupSelected:GetMobAmount()

    -- 第一格总是显示添加额外敌人
    for i = 1, amountMax do
        local mob = groupSelected:GetMob(i)
        if mob then
            local isPlayEffect = false
            if self.DataMob.MobIndexPlayEffect and self.DataMob.MobIndexPlayEffect == i then
                isPlayEffect = true
                self.DataMob.MobIndexPlayEffect = false
            end

            local affixIconList = self:GetAffixIconList(mob)
            ---@class UiReformMobData
            local mobData = {
                IsAdd = false,
                Name = mob:GetName(),
                Icon = mob:GetIcon(),
                Text = false,
                TextLevel = XUiHelper.GetText("ReformMobLevel", mob:GetLevel()),
                IconBuff = affixIconList,
                Pressure = mob:GetPressure(),
                MobGroup = groupSelected,
                Index = i,
                IsSelected = i == self._SelectedMob.Index,
                IsPlayMobUpdateEffect = isPlayEffect,
            }
            data.MobData[#data.MobData + 1] = mobData
        end
    end

    local amountCanSelect = amountMax - amount
    if (amountCanSelect > 0 and not self._Stage:IsFullPressure()) or amount == 0 then
        local addData = {
            IsAdd = true,
            Text = XUiHelper.GetText("ReformMobAmountCanSelect", amountCanSelect),
            MobGroup = groupSelected,
            Index = amount + 1,
        }
        table.insert(data.MobData, 1, addData)
    end

    local isEnableBtnEnter = false
    for i = 1, #groupArray do
        local group = groupArray[i]
        if group:GetMobAmount() > 0 then
            isEnableBtnEnter = true
            break
        end
    end
    data.IsEnableBtnEnter = isEnableBtnEnter
    --endregion
    
    --region 特殊需求 第五章 一二波 怪物数量不为1
    data.IsDisableFightChapter5 = false
    if self._Stage:GetChapterIndex() == 5 then
        for i = 1, #groupArray do
            local group = groupArray[i]
            local amountSelected = group:GetMobAmount()
            if amountSelected == 1 then
                data.IsDisableFightChapter5 = true
                break
            end
        end
    end
    --endregion
end

function XViewModelReform2ndList:SetButtonGroupIndex(index)
    self._CurrentIndex = index
end

function XViewModelReform2ndList:GetButtonGroupIndex()
    return self._CurrentIndex
end

function XViewModelReform2ndList:OnClickTabButton(index)
    local buttonData = self.Data.BtnGroup[index]
    if not buttonData then
        return
    end
    if buttonData.IsAdd then
        local group = self._Stage:GetMonsterGroupByIndex(index)
        group:SetIsShow(true)
    end
    self._CurrentIndex = index
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_UPDATE_MOB, true)
end

function XViewModelReform2ndList:RequestResetReformData()
    local stage = self._Stage
    local groups = stage:GetMonsterGroup()
    for i = 1, #groups do
        local group = groups[i]
        local mobAmount = group:GetMobAmountMax()
        for j = 1, mobAmount do
            group:ClearMob()
        end
        XDataCenter.Reform2ndManager.RequestSave(group)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_UPDATE_MOB)
end

function XViewModelReform2ndList:RequestSaveReformData()
    local stageId = self._Stage:GetId()
    local team = XDataCenter.Reform2ndManager.GetTeam(stageId)
    XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, require("XUi/XUiReform2nd/MainPage/XUiReform2ndBattleRoleRoom"))
end

---@param data UiReformMobData
function XViewModelReform2ndList:SetSelectedMobGroup(data)
    self._SelectedMob.MobGroup = data.MobGroup
    self._SelectedMob.Index = data.Index
    self.MobIndex = data.Index
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_MOB_GROUP)
end

function XViewModelReform2ndList:UpdateSelectedMob()
    local data = self.DataMob
    local mobGroup = self._SelectedMob.MobGroup
    if not mobGroup then
        return
    end
    local isHardModeUnlock = self._Stage:GetIsUnlockedDifficulty()
    local mobList = mobGroup:GetMobCanSelect()
    local mobCanSelect = {}
    for i = 1, #mobList do
        local mob = mobList[i]
        local isHardMode = mob:IsHardMode()
        local isShow = true
        if isHardMode and not isHardModeUnlock then
            isShow = false
        end
        if isShow then
            local isSelected, mobSelected = mobGroup:IsMobSelected(mob, self._SelectedMob.Index)
            -- 因为被选中的mob可能添加了词缀, 不同于候选mob
            if isSelected then
                mob = mobSelected
            end
            local affixIconList = self:GetAffixIconList(mob)
            ---@class XUiReformPanelMobData
            local mobData = {
                Name = mob:GetName(),
                Level = mob:GetLevel(),
                Icon = mob:GetIcon(),
                IconBuff = affixIconList,
                Pressure = mob:GetPressure(),
                IsSelected = isSelected,
                Mob = mob,
            }
            mobCanSelect[#mobCanSelect + 1] = mobData
        end
    end
    data.MobList = mobCanSelect
end

function XViewModelReform2ndList:UpdateMobAffix()
    local data = self.DataMob
    local mobGroup = self._SelectedMob.MobGroup
    if not mobGroup then
        return
    end
    local mob = mobGroup:GetMob(self._SelectedMob.Index)
    if not mob then
        return
    end
    local isHardModeUnlock = self._Stage:GetIsUnlockedDifficulty()

    data.AffixList = {}
    local affixList = mob:GetAffixCanSelect()
    for i = 1, #affixList do
        local affix = affixList[i]
        local isShow = true
        if affix:IsHardMode() and not isHardModeUnlock then
            isShow = false
        end
        if isShow then
            ---@class XReformAffixData
            local dataAffix = {
                Name = affix:GetName(),
                Desc = affix:GetSimpleDesc(),
                Icon = affix:GetIcon(),
                Pressure = affix:GetPressure(),
                IsSelected = mob:IsAffixSelected(affix),
                Affix = affix,
            }
            data.AffixList[#data.AffixList + 1] = dataAffix
        end
    end
end

---@param mob XReform2ndMob
function XViewModelReform2ndList:GetAffixIconList(mob)
    local affixIconList = {}
    local affixList = mob:GetAffixList()
    for i = 1, #affixList do
        local affix = affixList[i]
        local icon = affix:GetIcon()
        ---@class XUiReformAffixIconData
        local data = {
            Name = affix:GetName(),
            Desc = affix:GetSimpleDesc(),
            DescDetail = affix:GetDesc(),
            Icon = icon,
            IsEmpty = false
        }
        affixIconList[i] = data
    end
    local affixAmountMax = mob:GetAffixAmountMax()
    for i = #affixList + 1, affixAmountMax do
        affixIconList[i] = {
            Icon = false,
            IsEmpty = true
        }
    end
    return affixIconList
end

function XViewModelReform2ndList:IsMobSelected()
    local mobGroup = self._SelectedMob.MobGroup
    local index = self._SelectedMob.Index
    return mobGroup:GetMob(index) and true or false
end

function XViewModelReform2ndList:ClearSelected()
    self._SelectedMob.Index = 0
end

function XViewModelReform2ndList:ClearMobDirty()
    if self.DataMob.IsDirty then
        self.DataMob.MobIndexPlayEffect = self._SelectedMob.Index
        self.DataMob.IsDirty = false
    end
end

---@param data XUiReformPanelMobData
function XViewModelReform2ndList:SetSelectedMob(data)
    local mobGroup = self._SelectedMob.MobGroup
    local index = self._SelectedMob.Index
    if mobGroup then
        local mob = data.Mob
        if mob then
            local mobSelected = mobGroup:GetMob(index)
            if mobSelected and mobSelected:Equals(mob) then
                mobGroup:SetMob(index, false)
                self._SelectedMob.Index = mobGroup:GetMobAmount() + 1
                self.DataMob.IsDirty = true

            elseif not mobSelected then
                if self._Stage:IsOverPressure(mob:GetPressure()) then
                    XUiManager.TipText("ReformPressureMax")
                    return false
                end
                mobGroup:AddMob(mob:Clone())
                -- 新增加的放到最左边
                self._SelectedMob.Index = 1
                self.DataMob.IsDirty = true
            else
                if self._Stage:IsOverPressure(mob:GetPressure() - mobSelected:GetPressure()) then
                    XUiManager.TipText("ReformPressureMax")
                    return false
                end
                mobGroup:SetMob(index, mob:Clone())
                self.DataMob.IsDirty = true
            end
            XDataCenter.Reform2ndManager.RequestSave(mobGroup)
        else
            XLog.Error("[XViewModelReform2ndList] select mob error, mob is empty")
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_MOB)
    return true
end

---@param data XReformAffixData
function XViewModelReform2ndList:SetAffixSelected(data)
    local affix = data.Affix
    local mobGroup = self._SelectedMob.MobGroup
    local mob = mobGroup:GetMob(self._SelectedMob.Index)
    if not mob then
        return false
    end
    if data.IsSelected then
        mob:SetAffixUnselected(affix)
    else
        if mob:GetAffixAmount() >= mob:GetAffixAmountMax() then
            XUiManager.TipText("ReformAffixMax")
            return false
        end
        if self._Stage:IsOverPressure(affix:GetPressure()) then
            XUiManager.TipText("ReformPressureMax")
            return false
        end
        mob:SetAffixSelected(affix)
    end
    self.DataMob.IsDirty = true
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_AFFIX)
    XDataCenter.Reform2ndManager.RequestSave(mobGroup)
    return false
end

function XViewModelReform2ndList:UpdateStage()
    local data = self.DataStage
    local stage = self._Stage
    data.Name = stage:GetName()
    local chapter = stage:GetChapter()
    if chapter then
        data.Desc = chapter:GetThemeDesc()
    end
    data.DescTarget = stage:GetGoalDesc()
    data.Number = stage:GetStageNumberText()

    local iconList = {}
    local characterIdList = stage:GetRecommendCharacters()
    for i = 1, #characterIdList do
        local characterId = characterIdList[i]
        local icon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId)
        iconList[#iconList + 1] = icon
    end
    data.IconList = iconList
end

function XViewModelReform2ndList:SetUpdate4Affix(value)
    self.DataMob.Update4Affix = value
end

function XViewModelReform2ndList:SetPlayingAnimationScroll(value)
    self.DataMob.PlayingAnimation = value
end

return XViewModelReform2ndList
