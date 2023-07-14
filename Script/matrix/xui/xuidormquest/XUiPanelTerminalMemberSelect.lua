local tableInsert = table.insert
local pairs = pairs
local tableSort = table.sort
local tableContains = table.contains
local tableRemove = table.remove
local tableUnique = table.unique
local stringFormat = string.format
local tableRange = table.range

local XUiGridTerminalMemberItem = require("XUi/XUiDormQuest/XUiGridTerminalMemberItem")

---@class XUiPanelTerminalMemberSelect
local XUiPanelTerminalMemberSelect = XClass(nil, "XUiPanelTerminalMemberSelect")

function XUiPanelTerminalMemberSelect:Ctor(ui, rootUi, callBack)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.CallBack = callBack
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self:InitDynamicTable()
    self.GridTeamMemberList = {}
    self.GridTeamPropertyList = {}
    self.DormSelectItem.gameObject:SetActiveEx(false)
end

function XUiPanelTerminalMemberSelect:Refresh(questId, index)
    self:OnEnable()
    self.GameObject:SetActiveEx(true)
    self.QuestId = questId
    self.Index = index
    self.SelectMemberList = {}
    ---@type XDormQuest
    self.DormQuestViewModel = XDataCenter.DormQuestManager.GetDormQuestViewModel(self.QuestId)
    self.MemberCount = self.DormQuestViewModel:GetQuestMemberCount()
    self.RecommendAttrib = self.DormQuestViewModel:GetQuestRecommendAttrib()
    self:InitGridTeamMember()
    self:InitGridTeamProperty()
    self:UpdateUiData()
    -- 花费时间
    local needTime = self.DormQuestViewModel:GetQuestNeedTime()
    self.TxtAtTime.text = XUiHelper.GetTime(needTime, XUiHelper.TimeFormatType.DEFAULT)
    self:SetupDynamicTable()
    self.DrdSort.value = 0
end

function XUiPanelTerminalMemberSelect:InitGridTeamMember()
    local memberCount = self.MemberCount
    for i = 1, memberCount do
        local grid = self.GridTeamMemberList[i]
        if not grid then
            local go = i == 1 and self.GridTeamMember or XUiHelper.Instantiate(self.GridTeamMember, self.PanelTeamMembers)
            grid = {}
            XTool.InitUiObjectByUi(grid, go)
            self.GridTeamMemberList[i] = grid
        end
        grid.Members.gameObject:SetActiveEx(false)
        grid.GameObject:SetActiveEx(true)
    end

    for i = memberCount + 1, #self.GridTeamMemberList do
        self.GridTeamMemberList[i].GameObject:SetActiveEx(false)
    end
end

function XUiPanelTerminalMemberSelect:InitGridTeamProperty()
    -- 推荐属性
    local recommendAttrib = self.RecommendAttrib
    for i = 1, #recommendAttrib do
        local attribId = recommendAttrib[i]
        local grid = self.GridTeamPropertyList[i]
        if not grid then
            local go = i == 1 and self.GridTeamProperty or XUiHelper.Instantiate(self.GridTeamProperty, self.PanelTeamProperty)
            grid = {}
            XTool.InitUiObjectByUi(grid, go)
            self.GridTeamPropertyList[i] = grid
        end
        grid.Property:SetSprite(XDormQuestConfigs.GetQuestAttribIconById(attribId))
        grid.PropertySelect.gameObject:SetActiveEx(false)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #recommendAttrib + 1, #self.GridTeamPropertyList do
        self.GridTeamPropertyList[i].GameObject:SetActiveEx(false)
    end
end

-- 成员排序 推荐成员 > 一般成员 > 队伍中
function XUiPanelTerminalMemberSelect:SortMemberList(a, b)
    local priorityA = 0
    local priorityB = 0
    local isTeamA = XDataCenter.DormQuestManager.CheckDispatchCharacter(a)
    local isTeamB = XDataCenter.DormQuestManager.CheckDispatchCharacter(b)
    priorityA = isTeamA and priorityA - 1000 or priorityA
    priorityB = isTeamB and priorityB - 1000 or priorityB
    local coincidenceA = 0
    local coincidenceB = 0
    local propertyNumA = 0
    local propertyNumB = 0
    if not isTeamA then
        coincidenceA, propertyNumA = self:GetAttribCoincidenceNumber(a)
    end
    if not isTeamB then
        coincidenceB, propertyNumB = self:GetAttribCoincidenceNumber(b)
    end
    if priorityA ~= priorityB then
        return priorityA > priorityB
    end
    if priorityA == priorityB and priorityA == 0 then
        if coincidenceA ~= coincidenceB then
            return coincidenceA > coincidenceB
        elseif propertyNumA ~= propertyNumB then
            return propertyNumA > propertyNumB
        end
    end
    return a < b
end

-- 返回1.重合属性数量、2.成员属性数量
function XUiPanelTerminalMemberSelect:GetAttribCoincidenceNumber(characterId, recommendAttrib)
    local number = 0
    local characterStyleConfig = XDormConfig.GetCharacterStyleConfigById(characterId)
    local attribs = characterStyleConfig and characterStyleConfig.QuestAttrib or {}
    recommendAttrib = recommendAttrib or self.RecommendAttrib
    for _, attribId in pairs(recommendAttrib) do
        local isContain = tableContains(attribs, attribId)
        if isContain then
            number = number + 1
        end
    end
    return number, #attribs
end

-- 获取未满足的推荐属性
function XUiPanelTerminalMemberSelect:GetUnMetRecommendAttrib()
    if XTool.IsTableEmpty(self.SelectMemberList) then
        return self.RecommendAttrib
    end
    local attribs = {}
    local allSelectMemberAttribs = self:GetAllSelectMemberAttribs()
    for _, attribId in pairs(self.RecommendAttrib) do
        local isContain = tableContains(allSelectMemberAttribs, attribId)
        if not isContain then
            tableInsert(attribs, attribId)
        end
    end
    return attribs
end

-- 获取成员信息
function XUiPanelTerminalMemberSelect:GetMemberList()
    -- 排序
    local SortMember = function(a, b)
        return self:SortMemberList(a, b)
    end

    local allCharacterIds = XDataCenter.DormManager.GetAllCharacterIds()
    if not XTool.IsNumberValid(self.PriorSortType) then
        tableSort(allCharacterIds, SortMember)
        return allCharacterIds
    end
    -- 筛选
    local memberList = {}
    local conditions = { XDormConfig.GetDormCharacterType(self.PriorSortType) }
    for _, characterId in pairs(allCharacterIds) do
        local characterType = XDormConfig.GetCharacterStyleConfigSexById(characterId)
        for _, charType in pairs(conditions) do
            if characterType == charType then
                tableInsert(memberList, characterId)
                break
            end
        end
    end
    tableSort(memberList, SortMember)
    return memberList
end

-- 刷新队伍数量和属性
function XUiPanelTerminalMemberSelect:UpdateTeamMemberAndTeamProperty(characterId, isSelect)
    self:SetSelectMemberList(characterId, isSelect)
    self:UpdateGridTeamMember()
    self:UpdateGridTeamProperty()
    self:UpdateUiData()
end

-- 更新已选择成员Id
function XUiPanelTerminalMemberSelect:SetSelectMemberList(characterId, isSelect)
    local isContain, index = tableContains(self.SelectMemberList, characterId)
    if isSelect and not isContain then
        tableInsert(self.SelectMemberList, characterId)
    end
    if not isSelect and isContain then
        tableRemove(self.SelectMemberList, index)
    end
end

-- 刷新队伍图标
function XUiPanelTerminalMemberSelect:UpdateGridTeamMember()
    for i = 1, self.MemberCount do
        local memberId = self.SelectMemberList[i]
        local grid = self.GridTeamMemberList[i]
        if memberId then
            grid.Members.gameObject:SetActiveEx(true)
            grid.Members:SetRawImage(XDormConfig.GetCharacterStyleConfigQIconById(memberId))
        else
            grid.Members.gameObject:SetActiveEx(false)
        end
    end
end

-- 刷新属性图标
function XUiPanelTerminalMemberSelect:UpdateGridTeamProperty()
    local allAttribs = self:GetAllSelectMemberAttribs()
    for i = 1, #self.RecommendAttrib do
        local attribId = self.RecommendAttrib[i]
        local grid = self.GridTeamPropertyList[i]
        local isContain = tableContains(allAttribs, attribId)
        grid.PropertySelect.gameObject:SetActiveEx(isContain)
    end
end

-- 获取选择的所有成员的属性
function XUiPanelTerminalMemberSelect:GetAllSelectMemberAttribs()
    local allAttribs = {}
    for _, characterId in pairs(self.SelectMemberList) do
        local characterStyleConfig = XDormConfig.GetCharacterStyleConfigById(characterId)
        local attribs = characterStyleConfig and characterStyleConfig.QuestAttrib or {}
        allAttribs = XTool.MergeArray(allAttribs, attribs)
    end
    -- 列表去重
    tableUnique(allAttribs, true)
    return allAttribs
end

function XUiPanelTerminalMemberSelect:UpdateUiData()
    -- 已选择
    self.TxtSelected.text = stringFormat("%s/%s", #self.SelectMemberList, self.MemberCount)
    -- 确认按钮状态
    local memberLimit = self:CheckSelectMemberLimit()
    self.BtnConfirm:SetButtonState(memberLimit and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiPanelTerminalMemberSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicTable:SetProxy(XUiGridTerminalMemberItem, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelTerminalMemberSelect:SetupDynamicTable()
    self.DataList = self:GetMemberList()
    self.ImgNonePerson.gameObject:SetActiveEx(XTool.IsTableEmpty(self.DataList))
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiGridTerminalMemberItem
function XUiPanelTerminalMemberSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnBtnClick()
    end
end

-- 检查当前成员是否选中
function XUiPanelTerminalMemberSelect:CheckSelectMemberContain(characterId)
    if XTool.IsTableEmpty(self.SelectMemberList) then
        return false
    end
    local isContain = tableContains(self.SelectMemberList, characterId)
    return isContain
end

-- 检查选择成员数量上限
function XUiPanelTerminalMemberSelect:CheckSelectMemberLimit()
    return #self.SelectMemberList >= self.MemberCount
end

function XUiPanelTerminalMemberSelect:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick)
    XUiHelper.RegisterClickEvent(self, self.BtnQuickConfirm, self.OnBtnQuickConfirmClick)
    self.DrdSort.onValueChanged:AddListener(function()
        self.PriorSortType = self.DrdSort.value
        if self.PrePrior == self.PriorSortType then
            return
        end

        self.PrePrior = self.PriorSortType
        self:SetupDynamicTable()
    end)
end

function XUiPanelTerminalMemberSelect:OnBtnCloseClick()
    self:Close()
end

-- 确认
function XUiPanelTerminalMemberSelect:OnBtnConfirmClick()
    if not self:CheckSelectMemberLimit() then
        XUiManager.TipText("DormQuestTerminalMemberNumber")
        return
    end
    XDataCenter.DormQuestManager.QuestAcceptRequest(self.Index, self.SelectMemberList, function()
        if self.CallBack then
            self.CallBack()
        end
        self:OnBtnCloseClick()
        XUiManager.TipText("DormQuestTerminalQuestAccept")
    end)
end

-- 一键派遣
function XUiPanelTerminalMemberSelect:OnBtnQuickConfirmClick()
    if self:CheckSelectMemberLimit() then
        return
    end
    local isRefresh = false
    local memberNumber = self.MemberCount - #self.SelectMemberList
    for i = 1, memberNumber do
        local unMetAttrib = self:GetUnMetRecommendAttrib()
        local maxCoincidenceNum, memberData = self:GetAllQuickDispatchMemberData(unMetAttrib)
        if XTool.IsTableEmpty(memberData) then
            break
        end
        local isUnMetAndCoincidenceAttrib = #unMetAttrib > 0 and maxCoincidenceNum > 0
        -- 第一个、有推荐属性、有重叠属性
        local isPropertyOrder = i == 1 and isUnMetAndCoincidenceAttrib
        local number = isUnMetAndCoincidenceAttrib and 1 or memberNumber - i + 1
        local members = self:GetMemberData(memberData[maxCoincidenceNum], isPropertyOrder, number)
        for _, member in pairs(members) do
            if member and not self:CheckSelectMemberLimit() then
                isRefresh = true
                self:UpdateTeamMemberAndTeamProperty(member.CharacterId, true)
            end
        end
        if not isUnMetAndCoincidenceAttrib then
            break
        end
    end
    if isRefresh then
        self.DynamicTable:ReloadDataASync(1)
    end
end

function XUiPanelTerminalMemberSelect:GetAllQuickDispatchMemberData(recommendAttrib)
    local memberData = {}
    local maxCoincidenceNum = 0
    local allCharacterIds = XDataCenter.DormManager.GetAllCharacterIds()
    for _, characterId in pairs(allCharacterIds) do
        local isTeam = XDataCenter.DormQuestManager.CheckDispatchCharacter(characterId)
        local isSelectMember = tableContains(self.SelectMemberList, characterId)
        if isTeam or isSelectMember then
            goto CONTINUE
        end
        local coincidenceNum, propertyNum = self:GetAttribCoincidenceNumber(characterId, recommendAttrib)
        if coincidenceNum > maxCoincidenceNum then
            maxCoincidenceNum = coincidenceNum
        end
        if not memberData[coincidenceNum] then
            memberData[coincidenceNum] = {}
        end
        tableInsert(memberData[coincidenceNum], { CharacterId = characterId, PropertyNum = propertyNum })

        :: CONTINUE ::
    end
    return maxCoincidenceNum, memberData
end

function XUiPanelTerminalMemberSelect:GetMemberData(memberData, isPropertyOrder, number)
    if XTool.IsTableEmpty(memberData) then
        return {}
    end
    -- 排序
    tableSort(memberData, function(a, b)
        if a.PropertyNum ~= b.PropertyNum then
            if isPropertyOrder then
                return a.PropertyNum > b.PropertyNum
            else
                return a.PropertyNum < b.PropertyNum
            end
        end
        return a.CharacterId < b.CharacterId
    end)
    -- 取值
    local members = tableRange(memberData, 1, number)
    return members
end

function XUiPanelTerminalMemberSelect:OnEnable()

end

function XUiPanelTerminalMemberSelect:OnDisable()

end

function XUiPanelTerminalMemberSelect:Close()
    self:OnDisable()
    self.GameObject:SetActiveEx(false)  
end

return XUiPanelTerminalMemberSelect