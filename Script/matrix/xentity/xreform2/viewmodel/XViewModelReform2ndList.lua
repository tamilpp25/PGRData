---@class XViewModelReform2ndList
local XViewModelReform2ndList = XClass(nil, "XViewModelReform2ndList")

function XViewModelReform2ndList:Ctor(model)
    ---@type XReformModel
    self._Model = model

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
    local toggleFullDesc = XSaveTool.GetData(self._Model:GetToggleFullDescKey())
    self.DataMob = {
        ---@type XUiReformPanelMobData[]
        MobList = false,
        ---@type XReformAffixData[]
        AffixList = false,
        IsDirty = false,
        MobIndexPlayEffect = false,
        Update4Affix = false,
        PlayingAnimation = false,
        IsAutoShowNextMob = false,
        IsShowCompleteButton = false,
        IsFullDesc = toggleFullDesc,
        TextAffixAmount = false,
    }
    self.DataStage = {
        Name = false,
        Number = false,
        Desc = false,
        DescTarget = false,
        IconList = false
    }
    self.DataEnvironment = {
        List = {},
        DataSelectedEnvironment = false,
        ---@type XReform2ndEnv
        SelectedEnvironment = false,
    }

    ---@type XReform2ndStage
    self._Stage = false
    self._CurrentIndex = 1
    ---@type {MobGroup:XReform2ndMobGroup,Index:number}
    self._SelectedMob = {
        MobGroup = false,
        Index = 0,
    }
    self.GridIndex = 0

    self._AffixCanSelect = {}
end

---@param stage XReform2ndStage
function XViewModelReform2ndList:SetStage(stage)
    self._Stage = stage
    self.Data.TextExtraStar = XUiHelper.GetText("ReformExtraStar", self._Model:GetStageGoalDescById(stage:GetId()))
end

function XViewModelReform2ndList:Update()
    local data = self.Data
    local stage = self._Stage

    --region pressure
    local pressure = self._Model:GetStagePressureByStage(stage)
    if data.Pressure and pressure ~= data.Pressure then
        data.IsPlayPressureEffect = true
    else
        data.IsPlayPressureEffect = false
    end
    --local pressureMax = stage:GetPressureMax()
    data.TxtPressure = string.format("<color=#ff8340>%d</color>", pressure)
    data.Pressure = pressure

    local star = self._Model:GetStageStar(stage)
    local starMax = self._Model:GetStageStarMax(stage)
    data.StarAmount = star
    data.StarAmountMax = starMax

    local pressure2NextStar = 0
    local nextStar = star + 1
    if nextStar <= starMax then
        local pressureNextStar = self._Model:GetPressureByStar(nextStar, stage:GetId())
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
    data.StageName = self._Model:GetStageName(stage:GetId())
    self:UpdateMobData()
    --endregion
end

function XViewModelReform2ndList:UpdateMobData()
    local data = self.Data
    local groupArray = self._Model:GetMobGroupByStage(self._Stage)

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
                Name = self._Model:GetMobName(mob:GetId()),
                Icon = self._Model:GetMobIcon(mob:GetId()),
                Text = false,
                TextLevel = XUiHelper.GetText("ReformMobLevel", self._Model:GetMobLevel(mob:GetId())),
                IconBuff = affixIconList,
                Pressure = self._Model:GetMobPressureByMob(mob),
                MobGroup = groupSelected,
                Index = i,
                IsSelected = i == self._SelectedMob.Index,
                IsPlayMobUpdateEffect = isPlayEffect,
            }
            data.MobData[#data.MobData + 1] = mobData
        end
    end

    local amountCanSelect = amountMax - amount
    if (amountCanSelect > 0 and not self._Model:IsStageFullPressure(self._Stage)) or amount == 0 then
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

function XViewModelReform2ndList:SetNextButtonGroupIndex()
    if self:IsMaxButtonGroupIndex() then
        return false
    end
    local groupData = self.Data.MobData
    for i = 1, #groupData do
        local data = groupData[i]
        if data.IsAdd then
            self:SetSelectedMobGroup(data)
        end
    end
    return true
end

function XViewModelReform2ndList:IsMaxButtonGroupIndex()
    local group = self._Model:GetMonsterGroupByIndex(self._Stage, self._CurrentIndex)
    return group:GetMobAmount() >= group:GetMobAmountMax()
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
        local group = self._Model:GetMonsterGroupByIndex(self._Stage, index)
        group:SetIsShow(true)
    end
    self._CurrentIndex = index
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_UPDATE_MOB, true)
end

function XViewModelReform2ndList:RequestResetReformData()
    local stage = self._Stage
    local groups = self._Model:GetMobGroupByStage(stage)
    for i = 1, #groups do
        local group = groups[i]
        local mobAmount = group:GetMobAmountMax()
        for j = 1, mobAmount do
            group:ClearMob()
        end
        XMVCA.XReform:RequestSave(group)
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
    local mobData = self.Data.MobData
    for i = 1, #mobData do
        if mobData[i] == data then
            self.GridIndex = i
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_MOB_GROUP)
end

function XViewModelReform2ndList:UpdateSelectedMob()
    local data = self.DataMob
    local mobGroup = self._SelectedMob.MobGroup
    if not mobGroup then
        return
    end
    local isHardModeUnlock = self._Model:GetStageIsUnlockedDifficulty(self._Stage)
    local mobList = mobGroup:GetMobCanSelect()
    local mobCanSelect = {}
    for i = 1, #mobList do
        local mob = mobList[i]
        local isHardMode = self._Model:GetMobIsHardMode(mob:GetId())
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
                Name = self._Model:GetMobName(mob:GetId()),
                Level = self._Model:GetMobLevel(mob:GetId()),
                Icon = self._Model:GetMobIcon(mob:GetId()),
                IconBuff = affixIconList,
                Pressure = self._Model:GetMobPressureByMob(mob),
                IsSelected = isSelected,
                Mob = mob,
            }
            mobCanSelect[#mobCanSelect + 1] = mobData
        end
    end
    data.MobList = mobCanSelect

    local stage = self._Stage
    local monsterGroup = self._Model:GetMonsterGroupByIndex(stage, self._CurrentIndex)
    if monsterGroup:IsEmpty() then
        data.IsAutoShowNextMob = true
    end

    local isShowCompleteButton = false

    -- 已选好一个怪的时候
    if self._SelectedMob.MobGroup then
        local mob = self._SelectedMob.MobGroup:GetMob(1)
        if mob then
            isShowCompleteButton = true
        end
    end

    -- 自动选择中
    if data.IsAutoShowNextMob then
        isShowCompleteButton = false

        if self._SelectedMob.MobGroup and self._SelectedMob.Index > 1 then
            local mob = self._SelectedMob.MobGroup:GetMob(self._SelectedMob.Index)
            if not mob then
                isShowCompleteButton = true
            end
        end
    end

    data.IsShowCompleteButton = isShowCompleteButton
end

function XViewModelReform2ndList:CloseAutoShowNextMob()
    self.DataMob.IsAutoShowNextMob = false
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
    local isHardModeUnlock = self._Model:GetStageIsUnlockedDifficulty(self._Stage)

    data.AffixList = {}
    local affixList = self:GetAffixCanSelectByMob(mob)
    local isFullDesc = data.IsFullDesc
    for i = 1, #affixList do
        local affix = affixList[i]
        local isShow = true
        if self._Model:GetAffixIsHardMode(affix:GetId()) and not isHardModeUnlock then
            isShow = false
        end
        if isShow then
            local desc
            if isFullDesc then
                desc = self._Model:GetAffixDesc(affix:GetId())
            else
                desc = self._Model:GetAffixSimpleDesc(affix:GetId())
            end
            ---@class XReformAffixData
            local dataAffix = {
                Name = self._Model:GetAffixName(affix:GetId()),
                Desc = desc,
                Icon = self._Model:GetAffixIcon(affix:GetId()),
                Pressure = self._Model:GetAffixPressure(affix:GetId()),
                IsSelected = mob:IsAffixSelected(affix),
                Affix = affix,
            }
            data.AffixList[#data.AffixList + 1] = dataAffix
        end
    end

    local affixAmount = mob:GetAffixAmount()
    local maxAffixAmount = self._Model:GetMobAffixMaxCountByMob(mob)
    data.TextAffixAmount = affixAmount .. "/" .. maxAffixAmount
end

function XViewModelReform2ndList:SetIsFullDesc(value)
    self.DataMob.IsFullDesc = value
    XSaveTool.SaveData(self._Model:GetToggleFullDescKey(), value)
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_AFFIX)
end

function XViewModelReform2ndList:GetIsFullDesc()
    return self.DataMob.IsFullDesc
end

---@param mob XReform2ndMob
function XViewModelReform2ndList:GetAffixIconList(mob)
    local affixIconList = {}
    local affixList = self:GetAffixCanSelectByMob(mob)
    mob:GetAffixList()
    for i = 1, #affixList do
        local affix = affixList[i]
        local icon = self._Model:GetAffixIcon(affix:GetId())
        ---@class XUiReformAffixIconData
        local data = {
            Name = self._Model:GetAffixName(affix:GetId()),
            Desc = self._Model:GetAffixSimpleDesc(affix:GetId()),
            DescDetail = self._Model:GetAffixDesc(affix:GetId()),
            Icon = icon,
            IsEmpty = false
        }
        affixIconList[i] = data
    end
    local affixAmountMax = self._Model:GetMobAffixMaxCountByMob(mob)
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
                local pressure = self._Model:GetMobPressureByMob(mob)
                if self._Model:IsOverPressure(self._Stage, pressure) then
                    XUiManager.TipText("ReformPressureMax")
                    return false
                end
                mobGroup:AddMob(mob:Clone())
                -- 新增加的放到最左边
                self._SelectedMob.Index = 1
                self.DataMob.IsDirty = true
            else
                local pressure = self._Model:GetMobPressureByMob(mob) - self._Model:GetMobPressureByMob(mobSelected)
                if self._Model:IsOverPressure(self._Stage, pressure) then
                    XUiManager.TipText("ReformPressureMax")
                    return false
                end
                mobGroup:SetMob(index, mob:Clone())
                self.DataMob.IsDirty = true
            end
            XMVCA.XReform:RequestSave(mobGroup)
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
        if mob:GetAffixAmount() >= self._Model:GetMobAffixMaxCountByMob(mob) then
            XUiManager.TipText("ReformAffixMax")
            return false
        end
        if self._Model:IsOverPressure(self._Stage, self._Model:GetAffixPressure(affix:GetId())) then
            XUiManager.TipText("ReformPressureMax")
            return false
        end
        mob:SetAffixSelected(affix)
    end
    self.DataMob.IsDirty = true
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_SELECT_AFFIX)
    XMVCA.XReform:RequestSave(mobGroup)
    return false
end

function XViewModelReform2ndList:UpdateStage()
    local data = self.DataStage
    local stage = self._Stage
    data.Name = self._Model:GetStageName(stage:GetId())
    local chapter = stage:GetChapter(self._Model)
    if chapter then
        data.Desc = self._Model:GetChapterEventDescById(chapter:GetId())
    end
    data.DescTarget = self._Model:GetStageGoalDescById(stage:GetId())
    data.Number = stage:GetStageNumberText()

    local iconList = {}
    local characterIdList = self._Model:GetStageRecommendCharacterIds(stage:GetId())
    for i = 1, #characterIdList do
        local characterId = characterIdList[i]
        local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
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

--region environment
function XViewModelReform2ndList:UpdateEnvironment()
    local stage = self._Stage
    local environments = stage:GetEnvironments(self._Model)
    local list = {}
    self.DataEnvironment.List = list
    local currentEnvironment = stage:GetSelectedEnvironment(self._Model)

    for i = 1, #environments do
        local environment = environments[i]
        ---@class XViewModelReformEnvironment
        local dataEnvironment = {
            Name = environment:GetName(self._Model),
            Icon = environment:GetIcon(self._Model),
            Desc = environment:GetDesc(self._Model),
            AddScore = environment:GetAddScore(self._Model),
            EnvironmentId = environment:GetId(),
            IsSelected = environment == currentEnvironment,
        }
        list[#list + 1] = dataEnvironment
    end
end

function XViewModelReform2ndList:UpdateSelectedEnvironment()
    local stage = self._Stage
    local currentEnvironment = stage:GetSelectedEnvironment(self._Model)
    if currentEnvironment then
        local data = {}
        self.DataEnvironment.DataSelectedEnvironment = data
        data.Name = currentEnvironment:GetName(self._Model)
        data.Icon = currentEnvironment:GetIcon(self._Model)
    else
        self.DataEnvironment.DataSelectedEnvironment = nil
    end
end

function XViewModelReform2ndList:GetUiDataEnvironment()
    return self.DataEnvironment
end

function XViewModelReform2ndList:RequestSetEnvironment()
    if not self.DataEnvironment.SelectedEnvironment then
        XLog.Error("[XViewModelReform2ndList] select nothing")
        return
    end
    local stageId = self._Stage:GetId()
    local environmentId = self.DataEnvironment.SelectedEnvironment:GetId()
    XMVCA.XReform:RequestSelectEnvironment(stageId, environmentId)
end

function XViewModelReform2ndList:SetSelectedEnvironment(environmentId)
    local stage = self._Stage
    local environments = stage:GetEnvironments()
    for i = 1, #environments do
        local environment = environments[i]
        if environment:GetId() == environmentId then
            self.DataEnvironment.SelectedEnvironment = environment
            self:RequestSetEnvironment()
        end
    end
end
--endregion

---@param mob XReform2ndMob
function XViewModelReform2ndList:GetAffixCanSelectByMob(mob)
    if not self._AffixCanSelect[mob:GetId()] then
        self._AffixCanSelect[mob:GetId()] = {}
        local groupId = self._Model:GetMobAffixGroupId(mob:GetId())
        local affixIdList = self._Model:GetAffixGroupByGroupId(groupId)
        for i = 1, #affixIdList do
            local id = affixIdList[i]
            local XReform2ndAffix = require("XEntity/XReform2/XReform2ndAffix")
            local affix = XReform2ndAffix.New(id)
            self._AffixCanSelect[mob:GetId()][i] = affix
        end
    end
    return self._AffixCanSelect[mob:GetId()]
end

return XViewModelReform2ndList
