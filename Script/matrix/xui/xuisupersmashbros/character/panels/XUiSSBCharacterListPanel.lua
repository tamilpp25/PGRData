
local XUiSSBCharacterListPanel = XClass(nil, "XUiSSBCharacterListPanel")
-- groupId : XRoomCharFilterTipsConfigs.EnumFilterTagGroup
-- tagValue : XCharacterConfigs.GetCharDetailTemplate(char.Id)
local FilterJudge = function(groupId, tagValue, xRole)
    local characterViewModel = xRole:GetCharacterViewModel()
    -- 职业筛选
    if groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Career then
        if tagValue == characterViewModel:GetCareer() then
            return true
        end
        -- 能量元素筛选
    elseif groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.Element then
        local obtainElementList = characterViewModel:GetObtainElements()
        for _, element in pairs(obtainElementList) do
            if element == tagValue then
                return true
            end
        end
    else
        XLog.Error(string.format("XUiRoomCharacter:Filter函数错误，没有处理排序组：%s的逻辑", groupId))
        return false
    end
end

function XUiSSBCharacterListPanel:Ctor(ui, teamIds, pickOrReady, onSelectCb)
    self.OnSelectCallBack = onSelectCb
    self.TeamIds = teamIds
    self.PickOrReady = pickOrReady
    XTool.InitUiObjectByUi(self, ui)
    self:InitPanel()
end

function XUiSSBCharacterListPanel:InitPanel()
    self:InitBtns()
    self:InitDTables()
    self.DTableGridCharacter.gameObject:SetActiveEx(false)
    self.CharaType = XCharacterConfigs.CharacterType.Normal
    self.IsAscendOrder = true
    self.BtnAscending.gameObject:SetActiveEx(not self.IsAscendOrder)
    self.BtnDescending.gameObject:SetActiveEx(self.IsAscendOrder)
    self.SortTagType = XRoomCharFilterTipsConfigs.EnumSortTag.Default
    self.CurrentSelectTagGroup = {
        [XCharacterConfigs.CharacterType.Normal] = {},
        [XCharacterConfigs.CharacterType.Isomer] = {}
        }
    --选中构造体项
    self.PanelCharacterTypeBtns:SelectIndex(XCharacterConfigs.CharacterType.Normal)
end

function XUiSSBCharacterListPanel:InitBtns()
    XUiHelper.RegisterClickEvent(self, self.BtnFashion, function() self:OnClickBtnFashion() end) --时装
    XUiHelper.RegisterClickEvent(self, self.BtnOwnedDetail, function() self:OnClickBtnOwnedDetail() end) --角色详情
    self.BtnAscending.CallBack = function() self:OnClickBtnAscending() end --升序
    self.BtnDescending.CallBack = function() self:OnClickBtnDescending() end --降序
    self.BtnFilter.CallBack = function() self:OnClickBtnFilter() end --筛选
    --初始化角色类型页签组
    self.PanelCharacterTypeBtns:Init({self.BtnTabGouzaoti, self.BtnTabShougezhe}, function(index) self:OnSelectCharaType(index) end)
end

function XUiSSBCharacterListPanel:OnClickBtnFashion()
    XLuaUiManager.Open("UiFashion", self.CurrentChara:GetCharacterId())
end

function XUiSSBCharacterListPanel:OnClickBtnOwnedDetail()
    XLuaUiManager.Open("UiCharacterDetail", self.CurrentChara:GetCharacterId())
end

function XUiSSBCharacterListPanel:OnClickBtnDescending()
    self.BtnDescending.gameObject:SetActiveEx(false)
    self.BtnAscending.gameObject:SetActiveEx(true)
    self.IsAscendOrder = false
    self.CurrentListRoles = XDataCenter.SuperSmashBrosManager.SortRoles(self.CurrentListRoles, self.CurrentSortTagType, self.IsAscendOrder)
    self:RefreshCharacterList(self.CurrentListRoles)
end

function XUiSSBCharacterListPanel:OnClickBtnAscending()
    self.BtnAscending.gameObject:SetActiveEx(false)
    self.BtnDescending.gameObject:SetActiveEx(true)
    self.IsAscendOrder = true
    self.CurrentListRoles = XDataCenter.SuperSmashBrosManager.SortRoles(self.CurrentListRoles, self.CurrentSortTagType, self.IsAscendOrder)
    self:RefreshCharacterList(self.CurrentListRoles)
end

function XUiSSBCharacterListPanel:RefreshCharacterList(roles)
    self.CurrentListRoles = roles
    -- 刷新基本信息
    self.CharacterList:Refresh(roles)
end

function XUiSSBCharacterListPanel:InitDTables()
    local script = require("XUi/XUiSuperSmashBros/Character/DTables/XUiSSBCharacterList")
    self.CharacterList = script.New(self.DTableCharaList, self.TeamIds, self.PickOrReady, function(grid) self:OnSelectGrid(grid) end)
end

function XUiSSBCharacterListPanel:OnSelectCharaType(charaType)
    if charaType == XCharacterConfigs.CharacterType.Isomer
        and not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer) then
        return
    end
    self.CharaType = charaType
    local selectTagGroupDic = self.CurrentSelectTagGroup[charaType].TagGroupDic or {}
    local sortTagId = self.CurrentSelectTagGroup[charaType].SortType or XRoomCharFilterTipsConfigs.EnumSortTag.Default
    local roles = XDataCenter.SuperSmashBrosManager.GetRoleListByCharaType(self.CharaType)
    if #roles <= 0 then
        XUiManager.TipError(XUiHelper.GetText("IsomerLimitTip"))
        self.PanelCharacterTypeBtns:SelectIndex(XCharacterConfigs.CharacterType.Normal)
        return
    end
    self:Filter(selectTagGroupDic, sortTagId, function(roles)
            if #roles <= 0 then
                XUiManager.TipError(XUiHelper.GetText("IsomerLimitTip"))
                self.PanelCharacterTypeBtns:SelectIndex(XCharacterConfigs.CharacterType.Normal)
                return false
            end
            return true
        end)
end

function XUiSSBCharacterListPanel:GetCharaListFilter()
    local filter = function(chara)
        local result = chara:CheckIsIsomer() and XCharacterConfigs.CharacterType.Isomer or XCharacterConfigs.CharacterType.Normal
        return self.CharaType == result
    end
    return filter
end

function XUiSSBCharacterListPanel:OnRefresh()
    self.CharacterList:OnRefresh()
end

function XUiSSBCharacterListPanel:OnEnable()
    
end

function XUiSSBCharacterListPanel:OnDisable()
    
end

function XUiSSBCharacterListPanel:OnDestroy()
    
end

function XUiSSBCharacterListPanel:OnSelectGrid(chara)
    self.CurrentChara = chara
    if self.OnSelectCallBack then
        self.OnSelectCallBack(chara)
    end
end

function XUiSSBCharacterListPanel:OnClickBtnFilter()
    XLuaUiManager.Open("UiRoomCharacterFilterTips", self,
        XRoomCharFilterTipsConfigs.EnumFilterType.Common,
        XRoomCharFilterTipsConfigs.EnumSortType.Common,
        self.CharaType, nil, nil)
end

function XUiSSBCharacterListPanel:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
    if self.TagCacheDic == nil then self.TagCacheDic = {} end
    XDataCenter.RoomCharFilterTipsManager.Filter(self.TagCacheDic, selectTagGroupDic
        , XDataCenter.SuperSmashBrosManager.GetRoleListByCharaType(self.CharaType)
        , FilterJudge
        , function(filteredData)
            self.CurrentSelectTagGroup[self.CharaType].TagGroupDic = selectTagGroupDic
            self.CurrentSelectTagGroup[self.CharaType].SortType = sortTagId
            self:FilterRefresh(filteredData, sortTagId)
        end
        , isThereFilterDataCb)
end

function XUiSSBCharacterListPanel:FilterRefresh(filteredData, sortTagType)
    filteredData = XDataCenter.SuperSmashBrosManager.SortRoles(filteredData, sortTagType, self.IsAscendOrder)
    self:RefreshCharacterList(filteredData)
end

return XUiSSBCharacterListPanel