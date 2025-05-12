local Default = {
    _Id = 0, --目标Id
    _CharacterId = 0, --目标角色Id
    _Progress = 0, --当前目标进度
    _IsFinish = false, --目标是否完成
    _RecommendId = 0, --装备推荐Id, 同时是VoteId
    _SuitType = XEquipGuideConfigs.ChipSuitType.SixSuits, --意识套装类型
    _WeaponModel = {},
    _ChipModelList = {},
    _PutOnPosList = {}, --穿戴装备位置列表
    _Pos2IsPut = {},
    _Hidden = false, --是否隐藏
}

local XEquipGuideModel = require("XEntity/XEquipGuide/XEquipGuideModel")
local tableSort = table.sort
local tableInsert = table.insert
local tableRemove = table.remove
local tableIndexOf = table.indexof


local XEquipTarget = XClass(XDataEntityBase, "XEquipTarget")
function XEquipTarget:Ctor(targetId)
    self:Init(Default, targetId)
end

function XEquipTarget:InitData(id)
    self:SetProperty("_Id", id)
    self._RecommendId = XEquipGuideConfigs.TargetConfig:GetProperty(id, "EquipRecommendId")
    self._Hidden = XEquipGuideConfigs.TargetConfig:GetProperty(id, "Hidden") == 1
    local template = XMVCA.XEquip:GetCharDetailEquipTemplate(self._RecommendId)
    local suitIds = template.SuitId
    local suitLength = #suitIds
    if suitLength == 1 then
        self._SuitType = XEquipGuideConfigs.ChipSuitType.SixSuits
    elseif suitLength == 2 then
        self._SuitType = XEquipGuideConfigs.ChipSuitType.FourPlusTwoSuits
    elseif suitLength  == 3 then
        self._SuitType = XEquipGuideConfigs.ChipSuitType.TwoPlusTwoPlusTwoSuits
    end
end

function XEquipTarget:UpdateData(data)
    for key, value in pairs(data) do
        self:SetProperty(key, value)
    end
end

function XEquipTarget:UpdatePutOnPosList(list)
    list = list or {}
    self._Pos2IsPut = {}
    local tmpList = {}
    local recommend = XMVCA.XEquip:GetCharDetailEquipTemplate(self._RecommendId)
    for _, pos in ipairs(list or {}) do
        if self:CheckIsTargetEquipByPos(recommend, pos) then
            tableInsert(tmpList, pos)
        end
    end
    self:SetProperty("_PutOnPosList", tmpList)
    for _, pos in ipairs(tmpList) do
        self._Pos2IsPut[pos] = true
    end
    self:RefreshEquip()
end

function XEquipTarget:RefreshEquip()
    self:UpdateWeapon()
    self:UpdateChips()
    self:UpdateProgress()
end

function XEquipTarget:UpdateProgress()
    local config = XEquipGuideConfigs.JudgeConfig:GetConfig(XEquipGuideConfigs.JudgeConfigKey)
    local maxScore = config.GrossScore
    local weaponScore, chipScore = 0, 0
    if self._WeaponModel:IsWearTemplateIdEquip() then
        local equip = self._WeaponModel:GetWearEquip()
        weaponScore = weaponScore + config.WeaponPutOnScore 
                + equip.Breakthrough * config.WeaponBreakThroughScore 
                + equip.Level * config.WeaponUpLevelScore
    end

    for _, model in ipairs(self._ChipModelList) do
        if model:IsWearTemplateIdEquip() then
            local equip = model:GetWearEquip()
            chipScore = chipScore + config.ChipPutOnScore 
                    + equip.Breakthrough * config.ChipBreakThroughScore 
                    + equip.Level * config.ChipUpLevelScore
        end
    end
    local score = weaponScore + chipScore
    if score >= maxScore then
        XDataCenter.EquipGuideManager.EquipGuideTargetFinishRequest(self._CharacterId, function() 
            XLuaUiManager.Open("UiEquipGuideSuccess", self._CharacterId)
        end)
    end
    self:SetProperty("_Progress", XUiHelper.GetFillAmountValue(score, maxScore))
end

function XEquipTarget:UpdateWeapon()
    local template = XMVCA.XEquip:GetCharDetailEquipTemplate(self._RecommendId)
    local weaponId = template.EquipRecomend
    local model = XEquipGuideModel.New(template.EquipRecomend)
    model:SetCharacterId(self._CharacterId)
    local equipId
    --该位置已装备
    if self._Pos2IsPut[XEnumConst.EQUIP.EQUIP_SITE.WEAPON] then
        equipId = XMVCA.XEquip:GetCharacterWeaponId(self._CharacterId)
    else
        equipId = self:__FindBestOneEquip(weaponId)
    end
    self:SetProperty("_WeaponModel", model)
end

function XEquipTarget:UpdateChips()

    if self._SuitType == XEquipGuideConfigs.ChipSuitType.SixSuits then
        self:__UpdateSixChips()
    elseif self._SuitType == XEquipGuideConfigs.ChipSuitType.FourPlusTwoSuits then
        self:__UpdateFourPlusTwoChips()
    elseif self._SuitType == XEquipGuideConfigs.ChipSuitType.TwoPlusTwoPlusTwoSuits then
        self:__Update3ThTwoChips()
    end
end

--六件套
function XEquipTarget:__UpdateSixChips()
    local list = {}
    local template = XMVCA.XEquip:GetCharDetailEquipTemplate(self._RecommendId)
    local chips = XMVCA.XEquip:GetSuitEquipIds(template.SuitId[1])
    for site, chipId in ipairs(chips) do
        local model = XEquipGuideModel.New(chipId)
        model:SetCharacterId(self._CharacterId)
        list[site] = model
    end
    self:SetProperty("_ChipModelList", list)
end

--4+2件套
function XEquipTarget:__UpdateFourPlusTwoChips()
    local template = XMVCA.XEquip:GetCharDetailEquipTemplate(self._RecommendId)
    --套装1的意识
    local templateAIds = XMVCA.XEquip:GetSuitEquipIds(template.SuitId[1])
    --套装2的意识
    local templateBIds = XMVCA.XEquip:GetSuitEquipIds(template.SuitId[2])
    --套装1，2的数量
    local numA, numB = template.Number[1], template.Number[2]
    --除去已经装备的意识，剩下的数量
    local leftNumA, leftNumB = numA, numB
    local scores = {}
    local equips = {}
    --确认有争议位置(不判断已经装备的)
    for site = 1, XEnumConst.EQUIP.MAX_SUIT_COUNT do
        if not self._Pos2IsPut[site] then
            local tAId, tBId = templateAIds[site], templateBIds[site]
            local activeA = XMVCA.XEquip:IsEquipActive(tAId, self._CharacterId)
            local activeB = XMVCA.XEquip:IsEquipActive(tBId, self._CharacterId)
            scores[site] = (activeA and numA or 0) + (activeB and numB or 0)
        else
            --该位置已经装备了对应的意识
            local equipId = XMVCA.XEquip:GetCharacterEquipId(self._CharacterId, site)
            if XTool.IsNumberValid(equipId) and leftNumA > 0 and leftNumB > 0 then
                local equip = XMVCA.XEquip:GetEquip(equipId)
                local templateId = equip.TemplateId
                --已经装备A套
                if table.contains(templateAIds, templateId) then
                    leftNumA = leftNumA - 1
                end
                --已经装备B套
                if table.contains(templateBIds, templateId) then
                    leftNumB = leftNumB - 1
                end
                equips[site] = equipId
            else
                local tAId, tBId = templateAIds[site], templateBIds[site]
                local activeA = XMVCA.XEquip:IsEquipActive(tAId, self._CharacterId)
                local activeB = XMVCA.XEquip:IsEquipActive(tBId, self._CharacterId)
                scores[site] = (activeA and numA or 0) + (activeB and numB or 0)
            end
            
        end
    end

    local tmpChips = {
        [numA] = {},
        [numB] = {}
    }
    --意识排序(不判断已经装备的)
    local sort = function(a, b)
        local baseScoreA = XEquipGuideConfigs.CalEquipBaseScore(a)
        local baseScoreB = XEquipGuideConfigs.CalEquipBaseScore(b)
        if baseScoreA ~= baseScoreB then
            return baseScoreA > baseScoreB
        end
        local resonanceScoreA = XEquipGuideConfigs.CalEquipResonanceScore(a, self._CharacterId)
        local resonanceScoreB = XEquipGuideConfigs.CalEquipResonanceScore(b, self._CharacterId)
        if resonanceScoreA ~= resonanceScoreB then
            return resonanceScoreA > resonanceScoreB
        end
        if numA ~= numB then
            return numA > numB
        end
        return a < b
    end
    for pos, score in pairs(scores) do
        --该位置存在两个意识
        if score == (numA + numB) then
            local tAId, tBId = templateAIds[pos], templateBIds[pos]
            local equipAId, equipBId = self:__FindBestOneEquip(tAId), self:__FindBestOneEquip(tBId)
            local twoEquips = {equipAId, equipBId}
            table.sort(twoEquips, sort)
            equips[pos] = twoEquips
            if twoEquips[1] == equipAId then
                table.insert(tmpChips[numA], pos)
            else
                table.insert(tmpChips[numB], pos)
            end
        elseif score == numA  then
            local tmpId = templateAIds[pos]
            local equipId = self:__FindBestOneEquip(tmpId)
            equips[pos] = {equipId, 0}
            table.insert(tmpChips[numA], pos)
        elseif score == numB then
            local tmpId = templateBIds[pos]
            local equipId = self:__FindBestOneEquip(tmpId)
            equips[pos] = {equipId, 0}
            table.insert(tmpChips[numB], pos)
        else
            equips[pos] = {0, 0}
        end
    end

    local suitFitter = function(arrayA, arrayB)
        local t = {}
        for _, pos in ipairs(arrayA) do
            local eIdA, eIdB = equips[pos][1], equips[pos][2]
            tableInsert(t, {
                Pos = pos,
                Score = XEquipGuideConfigs.CalEquipBaseScore(eIdA) - XEquipGuideConfigs.CalEquipBaseScore(eIdB),
                EquipId = { eIdA, eIdB }
            })
        end
        tableSort(t, function(a, b)
            if a.Score ~= b.Score then
                return a.Score > b.Score
            end
            return a.Pos < b.Pos end
        )
        local tmp = t[#t]
        if not tmp then return end
        local index = tableIndexOf(arrayA, tmp.Pos)
        if index then
            tableRemove(arrayA, index)
        end
        if XTool.IsNumberValid(tmp.EquipId[2]) then
            tableInsert(arrayB, tmp.Pos)
        end
        equips[tmp.Pos] = tmp.EquipId[2]
    end
    --评分差值调整
    while true do
        local tmpNumA, tmpNumB = #tmpChips[numA], #tmpChips[numB]

        if tmpNumA <= leftNumA and tmpNumB <= leftNumB then
            break
        end

        if leftNumA < 0 or leftNumB < 0 then
            break
        end
        
        if tmpNumA > leftNumA and tmpNumA ~= 0 then 
            suitFitter(tmpChips[numA], tmpChips[numB])
        end
        if tmpNumB > leftNumB and tmpNumB ~= 0 then 
            suitFitter(tmpChips[numB], tmpChips[numA])
        end
    end

    local first, second
    local firstTemplateIds, secondTemplateIds
    if numA > numB then
        first, second = leftNumA - #tmpChips[numA],  leftNumB - #tmpChips[numB]
        firstTemplateIds, secondTemplateIds = templateAIds, templateBIds
    else
        first, second =  leftNumB - #tmpChips[numB], leftNumA - #tmpChips[numA]
        firstTemplateIds, secondTemplateIds = templateBIds, templateAIds
    end
    --待定处理
    local models = {}
    for pos, data in pairs(equips) do
        local equipId
        local model
        equipId = type(data) == "table" and data[1] or data
        if XTool.IsNumberValid(equipId) then
            local equip = XMVCA.XEquip:GetEquip(equipId)
            model = XEquipGuideModel.New(equip.TemplateId)
        else
            if first > 0 then
                model = XEquipGuideModel.New(firstTemplateIds[pos])
                first = first - 1
            elseif second > 0 then
                model = XEquipGuideModel.New(secondTemplateIds[pos])
                second = second - 1
            end
        end
        
        model:SetCharacterId(self._CharacterId)
        table.insert(models, model)
    end
    self:SetProperty("_ChipModelList", models)
end

function XEquipTarget:__Update3ThTwoChips()
    
end

function XEquipTarget:__Sort(equipIdA, equipIdB)
    local baseScoreA = XEquipGuideConfigs.CalEquipBaseScore(equipIdA)
    local baseScoreB = XEquipGuideConfigs.CalEquipBaseScore(equipIdB)
    if baseScoreA ~= baseScoreB then
        return baseScoreA > baseScoreB
    end

    local resonanceScoreA = XEquipGuideConfigs.CalEquipResonanceScore(equipIdA, self._CharacterId)
    local resonanceScoreB = XEquipGuideConfigs.CalEquipResonanceScore(equipIdB, self._CharacterId)
    if resonanceScoreA ~= resonanceScoreB then
        return resonanceScoreA > resonanceScoreB
    end

    return equipIdA < equipIdB
end

function XEquipTarget:__FindBestOneEquip(templateId)
    local equipIds = XMVCA.XEquip:GetEnableEquipIdsByTemplateId(templateId, self._CharacterId)
    local equipId, equipCount = 0, #equipIds
    if equipCount == 0 then
        equipId = 0
    elseif equipCount == 1 then
        equipId = equipIds[1]
    else
        local sort = handler(self, self.__Sort)
        table.sort(equipIds, sort)
        equipId = equipIds[1]
    end
    return equipId
end

function XEquipTarget:CreatePutOnPosList()
    local putOnPosList = {}
    --武器
    self:UpdateWeapon()
    local weaponId = self._WeaponModel:GetProperty("_Id")
    if XDataCenter.EquipGuideManager.CheckEquipIsWearingOnCharacter(weaponId, self._CharacterId) then
        tableInsert(putOnPosList, XEnumConst.EQUIP.EQUIP_SITE.WEAPON)
    end
    
    --意识
    self:UpdateChips()
    for i, model in ipairs(self._ChipModelList) do
        local equipId = model:GetProperty("_Id")
        if XDataCenter.EquipGuideManager.CheckEquipIsWearingOnCharacter(equipId, self._CharacterId) then
            tableInsert(putOnPosList,  i)
        end
    end
    return putOnPosList
end

function XEquipTarget:CheckIsTargetEquipByTemplateId(templateId)
    if self._WeaponModel:GetProperty("_TemplateId") == templateId then
        return true
    end

    local template = XMVCA.XEquip:GetCharDetailEquipTemplate(self._RecommendId)
    local suitIds = template.SuitId
    local suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
    for _, id in ipairs(suitIds) do
        if id == suitId then
            return true
        end
    end
    return false
end

--检测模板与身上穿戴的装备是否一致
function XEquipTarget:CheckIsFullEquipped()
    local template = XMVCA.XEquip:GetCharDetailEquipTemplate(self._RecommendId)
    local weaponId = template.EquipRecomend
    local weapon = XMVCA.XEquip:GetCharacterEquip(self._CharacterId, XEnumConst.EQUIP.EQUIP_SITE.WEAPON)
    if not weapon then
        return false
    end
    if weaponId ~= weapon.TemplateId then
        return false
    end
    
    local tmpSuit = {}
    for site = 1, XEnumConst.EQUIP.MAX_SUIT_COUNT do
        local eId = XMVCA.XEquip:GetCharacterEquipId(self._CharacterId, site)
        if not XTool.IsNumberValid(eId) then
            return false
        end
        local suitId = XMVCA.XEquip:GetEquipSuitIdByEquipId(eId)
        tmpSuit[suitId] = tmpSuit[suitId] or 0
        tmpSuit[suitId] = tmpSuit[suitId]  + 1
    end
    local suitIds, numbers = template.SuitId, template.Number
    for i, suit in ipairs(suitIds) do
        local num = numbers[i]
        if num ~= tmpSuit[suit] then
            return false
        end
    end
    return true
end

function XEquipTarget:CheckIsTargetEquipByPos(recommend, pos)
    local equip = XMVCA.XEquip:GetCharacterEquip(self._CharacterId, pos)
    if not equip then
        return false
    end
    local templateId = equip.TemplateId
    if XMVCA.XEquip:IsEquipWeapon(templateId) then
        if templateId == recommend.EquipRecomend then
            return true
        end
    else
        local suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
        for _, sId in ipairs(recommend.SuitId or {}) do
            if suitId == sId then
                return true
            end
        end
    end
    return false
end

--region   ------------------红点检查 start-------------------

function XEquipTarget:CheckEquipCanEquip(templateId)
    
    local check = function(tId)
        local equipIds =  XMVCA.XEquip:GetEnableEquipIdsByTemplateId(tId, self._CharacterId)
        if XTool.IsTableEmpty(equipIds) then
            return false
        end
        table.sort(equipIds, handler(self, self.__Sort))
        local equipId = equipIds[1]
        local equip = XMVCA.XEquip:GetEquip(equipId)
        return equip and equip.CharacterId ~= self._CharacterId
    end

    if XTool.IsNumberValid(templateId) then
        return check(templateId)
    else
        if check(self._WeaponModel:GetProperty("_TemplateId")) then
            return true
        end
        for _, model in ipairs(self._ChipModelList) do
            if check(model:GetProperty("_TemplateId")) then
                return true
            end 
        end
        return false
    end
    return false
end

function XEquipTarget:CheckHasStrongerWeapon()
    --不存在目标
    local curTarget = XDataCenter.EquipGuideManager.GetCurrentTarget()
    if not curTarget or curTarget:GetProperty("_Id") == self._Id then
        return false
    end
    local weaponModel = curTarget:GetProperty("_WeaponModel")
    if not weaponModel then
        return false 
    end
    local templateId = curTarget:GetProperty("_RecommendId")
    local template = XMVCA.XEquip:GetCharDetailEquipTemplate(templateId)
    local weaponId = template.EquipRecomend
    local star = XMVCA.XEquip:GetEquipStar(weaponId)
    --当前的目标武器需小于6星
    if star >= XEnumConst.EQUIP.MAX_STAR_COUNT then
        return false
    end
    --当前组合
    local recommendId = self._RecommendId
    if not XTool.IsNumberValid(recommendId) then
        return false
    end
    local recommend = XMVCA.XEquip:GetCharDetailEquipTemplate(recommendId)
    local selfWeaponId = recommend.EquipRecomend
    local selfStar = XMVCA.XEquip:GetEquipStar(selfWeaponId)
    if selfStar < XEnumConst.EQUIP.MAX_STAR_COUNT then
        return false
    end
    
    local suitIds, numbers = template.SuitId, template.Number
    local selfSuitIds, selfNumbers = template.SuitId, template.Number
    --检查意识组合是否一致
    for i, suitId in ipairs(suitIds or {}) do
        if suitId ~= selfSuitIds[i] or numbers[i] ~= selfNumbers[i] then
            return false
        end 
    end
    local isActive = XMVCA.XEquip:IsEquipActive(selfWeaponId, self._CharacterId)
    return isActive
end

--endregion------------------红点检查 finish------------------

function XEquipTarget:Clear()
    self._Progress = 0
    self._IsFinish = false
    self._WeaponModel = {}
    self._ChipModelList = {}
    self._Pos2IsPut = {}
    self._PutOnPosList = {}
end

--region   ------------------运营埋点 start-------------------
function XEquipTarget:__GetEquipState(model)
    if not model then
        return XEquipGuideConfigs.EquipState.None
    end
    local exist = model:IsExistEquip()
    if not exist then
        return XEquipGuideConfigs.EquipState.None
    end
    local wearing = model:GetWearEquip() ~= nil
    if not wearing then
        return XEquipGuideConfigs.EquipState.WaitWear
    end
    local max = XMVCA.XEquip:IsMaxLevelAndBreakthrough(model:GetProperty("_Id"))
    return max and XEquipGuideConfigs.EquipState.Complete or XEquipGuideConfigs.EquipState.Culture
end

function XEquipTarget:GetWeaponState()
    return self:__GetEquipState(self._WeaponModel)
end

function XEquipTarget:GetChipsState()
    local states = {}
    for pos, model in ipairs(self._ChipModelList or {}) do
        --Key只能为字符串,否则在C#层解析不了
        states[tostring(pos)] = self:__GetEquipState(model)
    end
    return states
end
--endregion------------------运营埋点 finish------------------





return XEquipTarget