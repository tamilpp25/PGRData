local XUiDrawOptional = XLuaUiManager.Register(XLuaUi, "UiDrawOptional")
local CombinationGrid = require("XUi/XUiDraw/XUiPanelCombination")
local XGridDrawTarget = require("XUi/XUiDraw/TargetActivity/XGridDrawTarget")
local CSTextManagerGetText = CS.XTextManager.GetText
local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal
local DEFAULT_UP_IMG = CS.XGame.ClientConfig:GetString("DrawDefaultUpImg")

---@class XUiDrawOptional:XLuaUi
function XUiDrawOptional:OnAwake()
    self.PanelRole.gameObject:SetActiveEx(false)
    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.BtnTab.gameObject:SetActiveEx(false)
    self.GridRole.gameObject:SetActiveEx(false)
    self.GridWeapon.gameObject:SetActiveEx(false)
    self.RoleContent = self.GridRole.transform.parent:GetComponent("RectTransform")
    self.WeaponContent = self.GridWeapon.transform.parent:GetComponent("RectTransform")
    ---@type XUiPanelCombination[]
    self.GridRoleList = {}
    self.GridWeaponList = {}
    self.AllRecomCharIdList = {} -- 所有推荐的角色
    self.CharRecommendDic = {} -- 角色对应推荐武器和辅助机
end

function XUiDrawOptional:OnStart(parentUi, optionalCb, allTimeOverCb, notSelectCb, isTargetActivity)
    self.ParentUi = parentUi
    self.OptionalCb = optionalCb
    self.AllTimeOverCb = allTimeOverCb
    self.NotSelectCb = notSelectCb
    self.CurSuitId = 0
    self:AutoAddListener()

    self._IsTargetActivity = isTargetActivity
    if isTargetActivity then
        self:InitDrawActivityTarget(self.ParentUi.GroupId)
    else
        self:SetData(self.ParentUi.GroupId)
    end

    self:UpdatePredictButton()
end

function XUiDrawOptional:OnEnable()
    self:AddEventListener()
end

function XUiDrawOptional:OnDisable()
    self:RemoveEventListener()
end

function XUiDrawOptional:SetActiveEx(bool)
    self.GameObject:SetActiveEx(bool)
end

--region Ui - SelectGroup
function XUiDrawOptional:SetData(groupId)
    self.GroupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(groupId)
    self.AllInfoList = XDataCenter.DrawManager.GetDrawInfoListByGroupId(groupId) -- 所有商品
    self.GoodsType = self:GetGoodType(self.AllInfoList)
    self.LastSelectDrawId = self:IsMustSelectDefault() and self.ParentUi.DrawInfo.Id or self.GroupInfo.UseDrawId
    self.CurSelectDrawId = self.LastSelectDrawId

    -- 刷新界面
    if self.GoodsType == XArrangeConfigs.Types.Character then
        self:RefreshCharacterPanel()
    elseif self.GoodsType == XArrangeConfigs.Types.Weapon then
        self:RefreshWeaponPanel()
    elseif self.GoodsType == XArrangeConfigs.Types.Partner then
        self:RefreshPartnerPanel()
    end

    -- 不一定有筛选栏，刷新显示所有物品
    self:RefreshGoodList(self.AllInfoList)

    -- 刷新当前选中
    self:SelectCombination(self.CurSelectDrawId)
end

function XUiDrawOptional:OnClickTabBtn(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end

    self.TabIndex = tabIndex
    if tabIndex == 1 then
        self:RefreshGoodList(self.AllInfoList)
    else
        local groupRuleCfg = XDrawConfigs.GetDrawGroupRuleById(self.GroupInfo.Id)
        local filterElementList = groupRuleCfg.CharFilterElementList or {}
        local elementCfgId = filterElementList[tabIndex - 1]
        self:OnClickElementTab(elementCfgId)
    end
    self:PlayAnimation("QieHuan")
end

-- 选中能量页签
function XUiDrawOptional:OnClickElementTab(elementCfgId)
    local infoList = {}
    for i, info in ipairs(self.AllInfoList) do
        local drawId = info.Id
        local combination = XDataCenter.DrawManager.GetDrawCombination(drawId)
        if combination.GoodsId and #combination.GoodsId > 0 then
            local charId = combination.GoodsId[1]
            local charCfg = XMVCA.XCharacter:GetCharacterTemplate(charId)
            if charCfg.Element == elementCfgId then
                table.insert(infoList, info)
            end
        end
    end
    self:RefreshGoodList(infoList)
end

-- 刷新物品列表
function XUiDrawOptional:RefreshGoodList(infoList)
    self.InfoList = infoList -- 筛选后的商品列表
    self.RoleContent.anchoredPosition = CS.UnityEngine.Vector2(0, 0)
    self.WeaponContent.anchoredPosition = CS.UnityEngine.Vector2(0, 0)

    for _, gridRole in ipairs(self.GridRoleList) do
        gridRole.GameObject:SetActiveEx(false)
    end
    for _, gridWeapon in ipairs(self.GridWeaponList) do
        gridWeapon.GameObject:SetActiveEx(false)
    end

    for i, info in ipairs(infoList) do
        ---@type XUiPanelCombination
        local combinationGrid = nil
        if self.GoodsType == XArrangeConfigs.Types.Character then
            if i <= #self.GridRoleList then
                combinationGrid = self.GridRoleList[i]
            else
                local go = CS.UnityEngine.Object.Instantiate(self.GridRole, self.GridRole.transform.parent)
                go.gameObject:SetActiveEx(true)
                combinationGrid = CombinationGrid.New(go, self)
                table.insert(self.GridRoleList, combinationGrid)
            end
        elseif self.GoodsType == XArrangeConfigs.Types.Weapon or self.GoodsType == XArrangeConfigs.Types.Partner then
            if i <= #self.GridWeaponList then
                combinationGrid = self.GridWeaponList[i]
            else
                local go = CS.UnityEngine.Object.Instantiate(self.GridWeapon, self.GridWeapon.transform.parent)
                go.gameObject:SetActiveEx(true)
                combinationGrid = CombinationGrid.New(go, self)
                table.insert(self.GridWeaponList, combinationGrid)
            end
        end

        local isSelect = self.CurSelectDrawId == info.Id
        combinationGrid:SetData(i, infoList[i].Id, self.GoodsType, isSelect)
        combinationGrid.GameObject:SetActiveEx(true)
    end
end

function XUiDrawOptional:SelectCombination(drawId)
    local isShow = drawId ~= 0
    self.PanelSelectedChar.gameObject:SetActiveEx(isShow)
    self.PanelSelectedWeapon.gameObject:SetActiveEx(isShow)
    self.BtnRoleComfirm.gameObject:SetActiveEx(isShow)
    self.BtnWeaponComfirm.gameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end

    -- 刷新选中
    local gridList = self.GoodsType == XArrangeConfigs.Types.Character and self.GridRoleList or self.GridWeaponList
    for i, info in ipairs(self.InfoList) do
        local isSelect = info.Id == drawId
        gridList[i]:SetSelectState(isSelect)
    end
    self.CurSelectDrawId = drawId

    -- 刷新右下角当前选中的信息
    local combination = XDataCenter.DrawManager.GetDrawCombination(drawId)
    if self.GoodsType == XArrangeConfigs.Types.Character then
        if combination.GoodsId == nil or #combination.GoodsId == 0 then
            self.RImgSelCharIcon:SetRawImage(DEFAULT_UP_IMG)
            local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
            self.TxtSelCharName.text = drawAimProbability[drawId].UpProbability or ""
        else
            local charId = combination.GoodsId[1]
            local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(charId, true)
            self.RImgSelCharIcon:SetRawImage(icon)
            self.TxtSelCharName.text = XMVCA.XCharacter:GetCharacterLogName(charId)
        end

    elseif self.GoodsType == XArrangeConfigs.Types.Weapon then
        local equipTemplateId = combination.GoodsId[1]
        local goodPara = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(equipTemplateId)
        self.RImgSelWeaponIcon:SetRawImage(goodPara.Icon)
        self.TxtSelWeaponName.text = goodPara.Name

    elseif self.GoodsType == XArrangeConfigs.Types.Partner then
        local partnerTemplateId = combination.GoodsId[1]
        local goodPara = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(partnerTemplateId)
        self.RImgSelWeaponIcon:SetRawImage(goodPara.Icon)
        self.TxtSelWeaponName.text = goodPara.Name
    end

    -- 禁用状态
    local isSame = self.CurSelectDrawId == self.LastSelectDrawId
    local canSelect = not isSame and self.IsCanSwitch
    local notSelect = not isSame and not self.IsCanSwitch
    self.BtnRoleComfirm:SetDisable(not canSelect)
    self.TexCharHaveSelect.gameObject:SetActiveEx(isSame)
    self.TexCharCurSelect.gameObject:SetActiveEx(canSelect)
    self.TexCharNotSelect.gameObject:SetActiveEx(notSelect)

    self.BtnWeaponComfirm:SetDisable(not canSelect)
    self.TexWeaponHaveSelect.gameObject:SetActiveEx(isSame)
    self.TexWeaponCurSelect.gameObject:SetActiveEx(canSelect)
    self.TexWeaponNotSelect.gameObject:SetActiveEx(notSelect)
end

function XUiDrawOptional:CheckIsAllTimeOver()
    for _, info in pairs(self.AllInfoList) do
        if not XDataCenter.DrawManager.CheckDrawIsTimeOver(info.Id) then
            return false
        end
    end
    return true
end

function XUiDrawOptional:IsHaveSwitchLimit()
    return self.GroupInfo and self.GroupInfo.MaxSwitchDrawIdCount and self.GroupInfo.MaxSwitchDrawIdCount > 0
end

-- 判断是否打开页面后必须得选一个
function XUiDrawOptional:IsMustSelectDefault()
    local groupRuleCfg = XDrawConfigs.GetDrawGroupRuleById(self.GroupInfo.Id)
    -- 既没有切换次数限制，也没有配置默认不选中
    return (not self:IsHaveSwitchLimit()) and (not groupRuleCfg.IsNotSelectDefault)
end

function XUiDrawOptional:GetGoodType(infoList)
    for _, info in ipairs(infoList) do
        local drawCt = XDataCenter.DrawManager.GetDrawCombination(info.Id)
        if drawCt and drawCt.GoodsId and #drawCt.GoodsId > 0 then
            return XArrangeConfigs.GetType(drawCt.GoodsId[1])
        end
    end
    return
end
--endregion

--region Ui - SelectByRecommendCharFilter
-- 初始化推荐角色筛选器
function XUiDrawOptional:InitRecommendCharFilter()
    local groupRuleCfg = XDrawConfigs.GetDrawGroupRuleById(self.GroupInfo.Id)
    local filterElementList = groupRuleCfg.CharFilterElementList or {}
    local showFilter = groupRuleCfg.IsShowFilter == 1
    self.BtnRecommendCharFilter.gameObject:SetActiveEx(showFilter)

    if showFilter then
        self.BtnRecommendCharFilter:SetNameByGroup(0, XUiHelper.GetText("DrawFilterDefaultTagName"))
    end

    self.CharRecommendDic = {}
    if self.GoodsType == XArrangeConfigs.Types.Weapon then
        for _, info in ipairs(self.AllInfoList) do
            local drawId = info.Id
            local combination = XDataCenter.DrawManager.GetDrawCombination(drawId)
            local equipTemplateId = combination.GoodsId[1]
            local equipCfg = XMVCA.XEquip:GetConfigEquip(equipTemplateId)
            local charId = equipCfg.RecommendCharacterId
            if not self.CharRecommendDic[charId] then
                self.CharRecommendDic[charId] = { Weapon = {}, Partner = {} }
            end
            table.insert(self.CharRecommendDic[charId].Weapon, drawId)
        end
    elseif self.GoodsType == XArrangeConfigs.Types.Partner then
        for _, info in ipairs(self.AllInfoList) do
            local drawId = info.Id
            local combination = XDataCenter.DrawManager.GetDrawCombination(drawId)
            local partnerTemplateId = combination.GoodsId[1]
            local partnerCfg = XPartnerConfigs.GetPartnerTemplateById(partnerTemplateId)
            local charId = partnerCfg.RecommendCharacterId
            if not self.CharRecommendDic[charId] then
                self.CharRecommendDic[charId] = { Weapon = {}, Partner = {} }
            end
            table.insert(self.CharRecommendDic[charId].Partner, drawId)
        end
    end

    self.AllRecomCharIdList = {}
    for charId, _ in pairs(self.CharRecommendDic) do
        table.insert(self.AllRecomCharIdList, { Id = charId })
    end
end

function XUiDrawOptional:OnRecommendCharFilter(charList, selectTagId)
    local showDrawDic = {}
    for _, charData in ipairs(charList) do
        local charId = charData.Id
        local recommend = self.CharRecommendDic[charId]
        if recommend then
            for _, drawId in ipairs(recommend.Weapon) do
                showDrawDic[drawId] = true
            end
            for _, drawId in ipairs(recommend.Partner) do
                showDrawDic[drawId] = true
            end
        end
    end

    local infoList = {}
    for _, info in ipairs(self.AllInfoList) do
        if showDrawDic[info.Id] then
            table.insert(infoList, info)
        end
    end

    if XTool.IsNumberValid(selectTagId) then
        self.BtnRecommendCharFilter:SetNameByGroup(0, XRoomCharFilterTipsConfigs.GetFilterTagName(selectTagId))
    else
        self.BtnRecommendCharFilter:SetNameByGroup(0, XUiHelper.GetText("DrawFilterDefaultTagName"))
    end

    self:RefreshGoodList(infoList)
end
--endregion

--region Ui - Character
function XUiDrawOptional:RefreshCharacterPanel()
    self.PanelRole.gameObject:SetActiveEx(true)
    self.TextRoleTitle.text = CSTextManagerGetText("AimCharacterSelectTitle")
    self:_SortCharInfoList(self.AllInfoList)
    self:_RefreshSwitchLimitChar()
    self:_InitCharTabList()
end

-- 切换选择次数限制
function XUiDrawOptional:_RefreshSwitchLimitChar()
    local maxSwitchCount = self.GroupInfo.MaxSwitchDrawIdCount
    local curSwitchCount = self.GroupInfo.SwitchDrawIdCount
    self.IsCanSwitch = not self:IsHaveSwitchLimit() or maxSwitchCount > curSwitchCount
    self.PanelQieHuanChar.gameObject:SetActiveEx(maxSwitchCount > 0)
    if self:IsHaveSwitchLimit() then
        local count = maxSwitchCount - curSwitchCount
        self.TxtHaveCountChar.text = CSTextManagerGetText("DrawSelectCountFullText", count)
        self.TxtNotHaveCountChar.text = CSTextManagerGetText("DrawSelectNotCountFullText")
        self.TxtHaveCountChar.gameObject:SetActiveEx(count > 0)
        self.TxtNotHaveCountChar.gameObject:SetActiveEx(count <= 0)
    end
    self.BtnRoleComfirm:SetDisable(not self.IsCanSwitch)
end

-- 角色列表排序
function XUiDrawOptional:_SortCharInfoList(infoList)
    -- 已拥有
    local ownDic = {}
    for _, info in ipairs(infoList) do
        local combination = XDataCenter.DrawManager.GetDrawCombination(info.Id)
        local charId = combination.GoodsId[1]
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(charId)
        ownDic[info.Id] = { CharId = charId, IsOwn = isOwn }
    end

    -- 排序
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    table.sort(infoList, function(a, b)
        local priorityA = 0
        local priorityB = 0

        -- 是否是角色
        local isNotCharA = ownDic[a.Id].CharId == nil
        local isNotCharB = ownDic[b.Id].CharId == nil
        if isNotCharA or isNotCharB then
            priorityA = priorityA + (isNotCharA and 1000000 or 0)
            priorityB = priorityB + (isNotCharB and 1000000 or 0)
            return priorityA > priorityB
        end

        -- 是否选中
        priorityA = priorityA + (a.Id == self.CurSelectDrawId and 100000 or 0)
        priorityB = priorityB + (b.Id == self.CurSelectDrawId and 100000 or 0)

        -- 是否活动中
        priorityA = priorityA + (a.EndTime > 0 and 10000 or 0)
        priorityB = priorityB + (b.EndTime > 0 and 10000 or 0)

        -- 是否是新加的
        if XFunctionManager.CheckInTimeByTimeId(drawAimProbability[a.Id].NewTimeId) then
            priorityA = priorityA + 1000
        end
        if XFunctionManager.CheckInTimeByTimeId(drawAimProbability[b.Id].NewTimeId) then
            priorityB = priorityB + 1000
        end

        -- 是否拥有
        local isOwnA = ownDic[a.Id].IsOwn
        local isOwnB = ownDic[b.Id].IsOwn
        priorityA = priorityA + (isOwnA and 0 or 100)
        priorityB = priorityB + (isOwnB and 0 or 100)

        -- 已拥有则未满阶角色优先
        if isOwnA and isOwnB then
            local isMaxA = XMVCA.XCharacter:IsMaxQualityById(ownDic[a.Id].CharId)
            local isMaxB = XMVCA.XCharacter:IsMaxQualityById(ownDic[b.Id].CharId)
            priorityA = priorityA + (isMaxA and 0 or 10)
            priorityB = priorityB + (isMaxB and 0 or 10)
        end

        -- 最后按照Priority排序
        priorityA = priorityA + (drawAimProbability[a.Id].Priority > drawAimProbability[b.Id].Priority and 1 or 0)
        priorityB = priorityB + (drawAimProbability[b.Id].Priority > drawAimProbability[a.Id].Priority and 1 or 0)
        return priorityA > priorityB
    end)
end

-- 初始化角色的页签列表
function XUiDrawOptional:_InitCharTabList()
    local groupRuleCfg = XDrawConfigs.GetDrawGroupRuleById(self.GroupInfo.Id)
    local filterElementList = groupRuleCfg.CharFilterElementList or {}
    local showFilter = groupRuleCfg.IsShowFilter and #filterElementList > 0
    self.PanelTabList.gameObject:SetActiveEx(showFilter)
    if showFilter then
        self.TabBtnList = { self.BtnTabAll }

        -- 能量类型
        for index, elementId in ipairs(filterElementList) do
            local go = CS.UnityEngine.Object.Instantiate(self.BtnTab)
            go.gameObject:SetActiveEx(true)
            go.transform:SetParent(self.BtnTab.transform.parent, false)
            local btn = go:GetComponent("XUiButton")
            table.insert(self.TabBtnList, btn)

            -- 刷新按钮ui
            local element = XMVCA.XCharacter:GetCharElement(elementId)
            btn:SetNameByGroup(0, element.ElementName)
            btn:SetRawImage(element.Icon2)
        end

        self.PanelTabList:Init(self.TabBtnList, function(tabIndex)
            self:OnClickTabBtn(tabIndex)
        end)
        self.PanelTabList:SelectIndex(1)
    end
end
--endregion

--region Ui - Weapon
function XUiDrawOptional:RefreshWeaponPanel()
    self.PanelWeapon.gameObject:SetActiveEx(true)
    self.TextWeaponTitle.text = CSTextManagerGetText("AimEquipSelectTitle")
    self:_SortWeaponInfoList(self.AllInfoList)
    self:_RefreshSwitchLimitWeapon()
    self:InitRecommendCharFilter()
end

function XUiDrawOptional:_SortWeaponInfoList(infoList)
    -- 已拥有
    local ownDic = {}
    for _, info in ipairs(infoList) do
        local combination = XDataCenter.DrawManager.GetDrawCombination(info.Id)
        local equipTemplateId = combination.GoodsId[1]
        local isOwnEquip = XMVCA.XEquip:IsOwnEquip(equipTemplateId)
        local isOwnChar = false
        local equipCfg = XMVCA.XEquip:GetConfigEquip(equipTemplateId)
        local charId = equipCfg.RecommendCharacterId
        if charId then
            isOwnChar = XMVCA.XCharacter:IsOwnCharacter(charId)
        end
        ownDic[info.Id] = { IsOwnWeapon = isOwnEquip, IsOwnChar = isOwnChar }
    end

    -- 排序
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    table.sort(infoList, function(a, b)
        local priorityA = 0
        local priorityB = 0

        -- 是否选中
        priorityA = priorityA + (a.Id == self.CurSelectDrawId and 100000 or 0)
        priorityB = priorityB + (b.Id == self.CurSelectDrawId and 100000 or 0)

        -- 是否活动中
        priorityA = priorityA + (a.EndTime > 0 and 10000 or 0)
        priorityB = priorityB + (b.EndTime > 0 and 10000 or 0)

        -- 是否是新加的
        if XFunctionManager.CheckInTimeByTimeId(drawAimProbability[a.Id].NewTimeId) then
            priorityA = priorityA + 1000
        end
        if XFunctionManager.CheckInTimeByTimeId(drawAimProbability[b.Id].NewTimeId) then
            priorityB = priorityB + 1000
        end

        -- 是否拥有装备
        local isOwnA = ownDic[a.Id].IsOwnWeapon
        local isOwnB = ownDic[b.Id].IsOwnWeapon
        priorityA = priorityA + (isOwnA and 0 or 100)
        priorityB = priorityB + (isOwnB and 0 or 100)

        -- 未拥有装备，则优先有推荐角色的
        if isOwnA == false and isOwnB == false then
            local isOwnCharA = ownDic[a.Id].IsOwnChar
            local isOwnCharB = ownDic[b.Id].IsOwnChar
            priorityA = priorityA + (isOwnCharA and 10 or 0)
            priorityB = priorityB + (isOwnCharB and 10 or 0)
        end

        -- 最后按照Priority排序
        priorityA = priorityA + (drawAimProbability[a.Id].Priority > drawAimProbability[b.Id].Priority and 1 or 0)
        priorityB = priorityB + (drawAimProbability[b.Id].Priority > drawAimProbability[a.Id].Priority and 1 or 0)

        return priorityA > priorityB
    end)
end

-- 切换选择次数限制
function XUiDrawOptional:_RefreshSwitchLimitWeapon()
    local maxSwitchCount = self.GroupInfo.MaxSwitchDrawIdCount
    local curSwitchCount = self.GroupInfo.SwitchDrawIdCount
    self.IsCanSwitch = not self:IsHaveSwitchLimit() or maxSwitchCount > curSwitchCount
    self.PanelQieHuanWeapon.gameObject:SetActiveEx(maxSwitchCount > 0)
    if self:IsHaveSwitchLimit() then
        local count = maxSwitchCount - curSwitchCount
        self.TxtHaveCountWeapon.text = CSTextManagerGetText("DrawSelectCountFullText", count)
        self.TxtNotHaveCountWeapon.text = CSTextManagerGetText("DrawSelectNotCountFullText")
        self.TxtHaveCountWeapon.gameObject:SetActiveEx(count > 0)
        self.TxtNotHaveCountWeapon.gameObject:SetActiveEx(count <= 0)
    end
    self.BtnWeaponComfirm:SetDisable(not self.IsCanSwitch)
end
--endregion

--region Ui - Partner
function XUiDrawOptional:RefreshPartnerPanel()
    self.PanelWeapon.gameObject:SetActiveEx(true)
    self:_SortPartnerInfoList(self.AllInfoList)
    self:_RefreshSwitchLimitWeapon()
    self:InitRecommendCharFilter()

    local isLink = false
    for _, info in ipairs(self.AllInfoList) do
        local combination = XDataCenter.DrawManager.GetDrawCombination(info.Id)
        local partnerTemplateId = combination.GoodsId[1]
        -- 有一个异界装备则显示异界装备
        if XPartnerConfigs.GetPartnerType(partnerTemplateId) == XPartnerConfigs.PartnerType.Link then
            isLink = true
            break
        end
    end

    if isLink then
        self.TextWeaponTitle.text = CSTextManagerGetText("AimPartnerLinkSelectTitle")
    else
        self.TextWeaponTitle.text = CSTextManagerGetText("AimPartnerSelectTitle")
    end
end

function XUiDrawOptional:_SortPartnerInfoList(infoList)
    -- 已拥有
    local ownDic = {}
    for _, info in ipairs(infoList) do
        local combination = XDataCenter.DrawManager.GetDrawCombination(info.Id)
        local partnerTemplateId = combination.GoodsId[1]
        local isOwnPartner = XDataCenter.PartnerManager.GetPartnerCountByTemplateId(partnerTemplateId) > 0
        local isOwnChar = false
        local partnerCfg = XPartnerConfigs.GetPartnerTemplateById(partnerTemplateId)
        local charId = partnerCfg.RecommendCharacterId
        if charId then
            isOwnChar = XMVCA.XCharacter:IsOwnCharacter(charId)
        end
        ownDic[info.Id] = { IsOwnPartner = isOwnPartner, IsOwnChar = isOwnChar }
    end

    -- 排序
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    table.sort(infoList, function(a, b)
        local priorityA = 0
        local priorityB = 0

        -- 是否选中
        priorityA = priorityA + (a.Id == self.CurSelectDrawId and 100000 or 0)
        priorityB = priorityB + (b.Id == self.CurSelectDrawId and 100000 or 0)

        -- 是否活动中
        priorityA = priorityA + (a.EndTime > 0 and 10000 or 0)
        priorityB = priorityB + (b.EndTime > 0 and 10000 or 0)

        -- 是否是新加的
        if XFunctionManager.CheckInTimeByTimeId(drawAimProbability[a.Id].NewTimeId) then
            priorityA = priorityA + 1000
        end
        if XFunctionManager.CheckInTimeByTimeId(drawAimProbability[b.Id].NewTimeId) then
            priorityB = priorityB + 1000
        end

        -- 是否拥有辅助机
        local isOwnA = ownDic[a.Id].IsOwnPartner
        local isOwnB = ownDic[b.Id].IsOwnPartner
        priorityA = priorityA + (isOwnA and 0 or 100)
        priorityB = priorityB + (isOwnB and 0 or 100)

        -- 未拥有辅助机，则优先有推荐角色的
        if isOwnA == false and isOwnB == false then
            local isOwnCharA = ownDic[a.Id].IsOwnChar
            local isOwnCharB = ownDic[b.Id].IsOwnChar
            priorityA = priorityA + (isOwnCharA and 10 or 0)
            priorityB = priorityB + (isOwnCharB and 10 or 0)
        end

        -- 最后按照Priority排序
        priorityA = priorityA + (drawAimProbability[a.Id].Priority > drawAimProbability[b.Id].Priority and 1 or 0)
        priorityB = priorityB + (drawAimProbability[b.Id].Priority > drawAimProbability[a.Id].Priority and 1 or 0)

        return priorityA > priorityB
    end)
end
--endregion

--region Ui - DrawActivityTarget
function XUiDrawOptional:InitDrawActivityTarget(drawGroupId)
    self._TargetActivityData = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(drawGroupId)
    -- v3.2打打印
    if not self._TargetActivityData then
        XDataCenter.DrawManager.DebugActivityTargetInfo(drawGroupId)
    end
    ---@type XGridDrawTarget[]
    self._GridDrawTargetList = {}
    self._DrawTargetTemplateList = { 0 }

    local templateIdList = self._TargetActivityData:GetTargetTemplateIds()
    if not XTool.IsTableEmpty(templateIdList) then
        for _, id in ipairs(templateIdList) do
            self._DrawTargetTemplateList[#self._DrawTargetTemplateList + 1] = id
        end
        table.sort(self._DrawTargetTemplateList, self._DrawActivityTargetSortFunc)
        self.GoodsType = XArrangeConfigs.GetType(templateIdList[1])
    end
    self.LastSelectDrawId = self._TargetActivityData:GetTargetId()
    self.CurSelectDrawId = self.LastSelectDrawId

    self.TextRoleTitle.text = XUiHelper.GetText("DrawTargetFirstTitle")
    self.TxtHaveCountChar.text = XUiHelper.GetText("DrawTargetSecondTitle", self._TargetActivityData:GetTargetCount())

    -- 刷新界面
    if self.GoodsType == XArrangeConfigs.Types.Character then
        -- 角色筛选
        self:_InitTargetSelectFilter()
        -- 刷新列表
        self:_RefreshCharacterDrawTarget(self._DrawTargetTemplateList)
    end

    -- 刷新当前选中
    self:SelectTargetTemplate(self.CurSelectDrawId)
end

function XUiDrawOptional._DrawActivityTargetSortFunc(characterIdA, characterIdB)
    if characterIdA == 0 or characterIdB == 0 then
        return characterIdA == 0
    end

    local isHaveA = XMVCA.XCharacter:IsOwnCharacter(characterIdA)
    local isHaveB = XMVCA.XCharacter:IsOwnCharacter(characterIdB)
    if isHaveA ~= isHaveB then
        return isHaveB -- 未拥有排前面
    end
    
    local assignTagCfgA = XDrawConfigs.GetDrawNewPlayerAssignTagCfg(characterIdA)
    local assignTagCfgB = XDrawConfigs.GetDrawNewPlayerAssignTagCfg(characterIdB)
    local isCfgEmptyA = XTool.IsTableEmpty(assignTagCfgA)
    local isCfgEmptyB = XTool.IsTableEmpty(assignTagCfgB)
    if isCfgEmptyA ~= isCfgEmptyB then
        return isCfgEmptyB -- 配置表里有的排前面
    end
    
    if not isCfgEmptyA then -- 都存在标签配置
        if assignTagCfgA.IsRecommend ~= assignTagCfgB.IsRecommend then
            return assignTagCfgA.IsRecommend -- 推荐排前面
        else
            return assignTagCfgA.Order > assignTagCfgB.Order -- 优先级高排前面
        end
    else -- 都不存在标签配置
        return XMVCA.XCharacter:GetCharacterPriority(characterIdA) > XMVCA.XCharacter:GetCharacterPriority(characterIdB) -- 优先级高排前面
    end
    
    return false
end

function XUiDrawOptional:_InitTargetSelectFilter()
    self.PanelTabList.gameObject:SetActiveEx(true)
    self.TabBtnList = { self.BtnTabAll }
    -- 能量类型
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local elementList = characterAgency:GetModelCharacterElement()
    for i = 1, XEnumConst.Filter.MaxEnableElementNum do
        local go = CS.UnityEngine.Object.Instantiate(self.BtnTab)
        go.gameObject:SetActiveEx(true)
        go.transform:SetParent(self.BtnTab.transform.parent, false)
        local btn = go:GetComponent("XUiButton")
        table.insert(self.TabBtnList, btn)

        -- 刷新按钮ui
        btn:SetNameByGroup(0, elementList[i].ElementName)
        btn:SetRawImage(elementList[i].Icon2)
    end
    self.PanelTabList:Init(self.TabBtnList, function(tabIndex)
        self:_OnClickTabSelectTab(tabIndex)
    end)
    self.PanelTabList:SelectIndex(1)
end

function XUiDrawOptional:_OnClickTabSelectTab(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end

    self.TabIndex = tabIndex
    if tabIndex == 1 then
        self:_RefreshCharacterDrawTarget(self._DrawTargetTemplateList)
    else
        ---@type XCharacterAgency
        local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
        local elementList = characterAgency:GetModelCharacterElement()
        local elementCfg = elementList[tabIndex - 1]
        local templateList = {}
        for _, characterId in ipairs(self._DrawTargetTemplateList) do
            if XTool.IsNumberValid(characterId) and characterAgency:GetCharacterElement(characterId) == elementCfg.Id then
                templateList[#templateList + 1] = characterId
            end
        end
        self:_RefreshCharacterDrawTarget(templateList)
    end
    self:PlayAnimation("QieHuan")
end

function XUiDrawOptional:SelectTargetTemplate(templateId)
    self.PanelSelectedChar.gameObject:SetActiveEx(true)
    self.PanelSelectedWeapon.gameObject:SetActiveEx(true)
    self.BtnRoleComfirm.gameObject:SetActiveEx(true)
    self.BtnWeaponComfirm.gameObject:SetActiveEx(true)

    -- 刷新选中
    local gridList = self.GoodsType == XArrangeConfigs.Types.Character and self._GridDrawTargetList
    for _, grid in ipairs(gridList) do
        local isSelect = grid:GetTemplateId() == templateId
        grid:SetSelectState(isSelect)
    end
    self.CurSelectDrawId = templateId
    -- 禁用状态
    local isSame = self.CurSelectDrawId == self.LastSelectDrawId

    -- 刷新右下角当前选中的信息
    if self.GoodsType == XArrangeConfigs.Types.Character then
        if not XTool.IsNumberValid(templateId) then
            self.RImgSelCharIcon:SetRawImage(XDrawConfigs.GetDrawClientConfig("DrawTargetSelectNoneRoleImg"))
            self.TxtSelCharName.text = XDrawConfigs.GetDrawClientConfig("DrawTargetSelectNoneRoleText")

            self.TexCharHaveSelect.gameObject:SetActiveEx(false)
            self.TexCharCurSelect.gameObject:SetActiveEx(false)
            self.TexCharNotSelect.gameObject:SetActiveEx(false)
        else
            local charId = templateId
            local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(charId, true)
            self.RImgSelCharIcon:SetRawImage(icon)
            self.TxtSelCharName.text = XMVCA.XCharacter:GetCharacterLogName(charId)

            self.TexCharHaveSelect.gameObject:SetActiveEx(isSame)
            self.TexCharCurSelect.gameObject:SetActiveEx(not isSame)
            self.TexCharNotSelect.gameObject:SetActiveEx(false)
        end
    end
    self.BtnRoleComfirm:SetDisable(isSame)
end

function XUiDrawOptional:_RefreshCharacterDrawTarget(templateIds)
    -- 空状态
    local isEmpty = XTool.IsTableEmpty(templateIds)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self.BtnRoleComfirm.gameObject:SetActiveEx(not isEmpty)
    self.PanelSelectedChar.gameObject:SetActiveEx(not isEmpty)

    self.RoleContent.anchoredPosition = CS.UnityEngine.Vector2(0, 0)
    self.WeaponContent.anchoredPosition = CS.UnityEngine.Vector2(0, 0)

    for _, gridRole in ipairs(self.GridRoleList) do
        gridRole.GameObject:SetActiveEx(false)
    end
    for _, gridWeapon in ipairs(self.GridWeaponList) do
        gridWeapon.GameObject:SetActiveEx(false)
    end

    for i, id in ipairs(templateIds) do
        ---@type XGridDrawTarget
        local gridDrawTarget
        if self.GoodsType == XArrangeConfigs.Types.Character then
            if i <= #self._GridDrawTargetList then
                gridDrawTarget = self._GridDrawTargetList[i]
            else
                local go = CS.UnityEngine.Object.Instantiate(self.GridRole, self.GridRole.transform.parent)
                go.gameObject:SetActiveEx(true)
                gridDrawTarget = XGridDrawTarget.New(go, self)
                table.insert(self._GridDrawTargetList, gridDrawTarget)
            end
        end

        local isSelect = self.CurSelectDrawId == id
        gridDrawTarget:SetData(i, id, self.GoodsType, isSelect)
        gridDrawTarget.GameObject:SetActiveEx(true)
    end
    for i = #templateIds + 1, #self._GridDrawTargetList do
        self._GridDrawTargetList[i].GameObject:SetActiveEx(false)
    end

    self.PanelRole.gameObject:SetActiveEx(true)
end
--endregion

--region Event
function XUiDrawOptional:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_DRAW_TARGET_ACTIVITY_CHANGE, self.Close, self)
end

function XUiDrawOptional:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_DRAW_TARGET_ACTIVITY_CHANGE, self.Close, self)
end
--endregion

--region BtnListener
function XUiDrawOptional:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseRole, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCloseWeapon, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRoleComfirm, self.OnBtnComfirmClick)
    XUiHelper.RegisterClickEvent(self, self.BtnWeaponComfirm, self.OnBtnComfirmClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRecommendCharFilter, self.OnBtnRecommendCharFilterClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPredict, self.OnBtnPredictClick)
end

function XUiDrawOptional:OnBtnCloseClick()
    local isDoNotSelectCb = false
    if self._IsTargetActivity then
        self.CurSelectDrawId = self._TargetActivityData:GetTargetId()
        isDoNotSelectCb = self.CurSelectDrawId == 0
    else
        -- 重新获取当前选中
        self.CurSelectDrawId = self:IsHaveSwitchLimit() and self.GroupInfo.UseDrawId or self.ParentUi.DrawInfo.Id
        local groupRuleCfg = XDrawConfigs.GetDrawGroupRuleById(self.GroupInfo.Id)
        isDoNotSelectCb = self.CurSelectDrawId == 0 and not groupRuleCfg.IsNotSelectDefault

        if self:CheckIsAllTimeOver() then
            XLuaUiManager.RunMain()
            XUiManager.TipText("DrawAimLeftTimeOver")
            return
        end
    end

    if isDoNotSelectCb then
        if self.NotSelectCb then
            self.NotSelectCb()
        end
        self:Close()
        return
    end

    self:Close()
end

function XUiDrawOptional:OnBtnComfirmClick()
    if self.CurSelectDrawId == self.LastSelectDrawId then
        return
    end

    if self._IsTargetActivity then
        -- 非校准活动过期判断
        self:_OnBtnComfirmSelectDrawTarget()
    else
        self:_OnBtnComfirmSelectDrawAnim()
    end
end

---校准活动选择
function XUiDrawOptional:_OnBtnComfirmSelectDrawTarget()
    XDataCenter.DrawManager.RequestSelectTargetActivity(self._TargetActivityData:GetActivityId(), self.CurSelectDrawId, function()
        self.OptionalCb(self._TargetActivityData)
        self:Close()
    end)
end

---限定角色选择
function XUiDrawOptional:_OnBtnComfirmSelectDrawAnim()
    if not self.IsCanSwitch then
        return
    end

    if self:CheckIsAllTimeOver() then
        XLuaUiManager.RunMain()
        XUiManager.TipText("DrawAimLeftTimeOver")
        return
    end

    if XDataCenter.DrawManager.CheckDrawIsTimeOver(self.CurSelectDrawId) then
        XUiManager.TipText("DrawAimLeftTimeOver")
        return
    end

    local sureFun = function(IsChange)
        if IsChange then
            XDataCenter.DrawManager.SaveDrawAimId(self.CurSelectDrawId, self.ParentUi.GroupId, function()
                self.OptionalCb(self.CurSelectDrawId)
                self:Close()
            end)
        end
    end

    local combination = XDataCenter.DrawManager.GetDrawCombination(self.CurSelectDrawId)
    local goodsList = combination and combination.GoodsId or {}
    local IsRandom = #goodsList == 0
    local maxSwitchCount = self.GroupInfo.MaxSwitchDrawIdCount
    local curSwitchCount = self.GroupInfo.SwitchDrawIdCount
    local count = maxSwitchCount - curSwitchCount
    local IsChang = self.GroupInfo.UseDrawId ~= self.CurSelectDrawId
    if (IsChang or IsRandom) and maxSwitchCount > 0 then
        XLuaUiManager.Open("UiChangeCombination", self.CurSelectDrawId, count, IsChang, sureFun)
    else
        sureFun(IsChang)
    end
end

function XUiDrawOptional:OnBtnRecommendCharFilterClick()
    local cacheKey = "UiDrawOptional" .. self.GroupInfo.Id
    local groupNameList = {}
    groupNameList[1] = XUiHelper.GetText("FitterCharCareer")
    groupNameList[2] = XUiHelper.GetText("FitterCharElement")

    XLuaUiManager.Open("UiCommonCharacterFilterTipsOptimization", self.AllRecomCharIdList, cacheKey, function(charList, tagId)
        self:OnRecommendCharFilter(charList, tagId)
        XDataCenter.CommonCharacterFiltManager.ClearSelectTagData(cacheKey)
    end, CharacterFilterGroupType.Draw, nil, groupNameList, true)
end
--endregion

--region 降临角色轮换预告

function XUiDrawOptional:UpdatePredictButton()
    local isShow = false
    if self.GroupInfo then
        if self.GroupInfo.ShowPredictType then
            if self.GroupInfo.ShowPredictType == XDrawConfigs.DrawShowPredictType.Predict then
                for _, v in pairs(XDrawConfigs.GetDrawPredictConfigs()) do
                    if XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
                        isShow = true
                        break
                    end
                end
            end
        end
    end
    self.BtnPredict.gameObject:SetActiveEx(isShow)
end

function XUiDrawOptional:OnBtnPredictClick()
    self:OpenChildUi("UiDrawOptionalPredict")
end

--endregion