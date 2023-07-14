--=================
--选人界面主面板
--=================
local XUiSSBPickPanelHead = XClass(nil, "XUiSSBPickPanelHead")

local FilterJudge = {
    [XSuperSmashBrosConfig.RoleType.Chara] = function(groupId, tagValue, xRole)
        local characterViewModel = xRole:GetCharacterViewModel()
        -- 职业筛选
        if groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.SSBRole then
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
    end,
    [XSuperSmashBrosConfig.RoleType.Monster] = function(groupId, tagValue, xMonster)
        -- 怪物阶级筛选
        if groupId == XRoomCharFilterTipsConfigs.EnumFilterTagGroup.SSBMonster then
            if tagValue == xMonster:GetMonsterType() then
                return true
            end
        else
            XLog.Error(string.format("XUiRoomCharacter:Filter函数错误，没有处理排序组：%s的逻辑", groupId))
            return false
        end
    end
}

function XUiSSBPickPanelHead:Ctor(rootUi)
    self.Mode = rootUi.Mode
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, self.RootUi.PanelHead)
    self:Init()
end
--=================
--初始化
--=================
function XUiSSBPickPanelHead:Init()
    self:InitBtnFilter()
    self:InitCharaHeadList()
    self:InitMonsterHeadList()
    self.SortTagType = XRoomCharFilterTipsConfigs.EnumSortTag.Default
    self.CurrentSelectTagGroup = {
        [XSuperSmashBrosConfig.RoleType.Chara] = {},
        [XSuperSmashBrosConfig.RoleType.Monster] = {}
    }
    self.TagCacheDic = {
        [XSuperSmashBrosConfig.RoleType.Chara] = {},
        [XSuperSmashBrosConfig.RoleType.Monster] = {}
    }

end
--=================
--初始化筛选按钮
--=================
function XUiSSBPickPanelHead:InitBtnFilter()
    if self.BtnFilter then
        self.BtnFilter.CallBack = function() self:OnClickBtnFilter() end
    end
end

function XUiSSBPickPanelHead:OnClickBtnFilter()
    local filterType = 
    self.ShowType == XSuperSmashBrosConfig.RoleType.Chara and XRoomCharFilterTipsConfigs.EnumFilterType.SSBRole
    or XRoomCharFilterTipsConfigs.EnumFilterType.SSBMonster
    local enumSortType =
    self.ShowType == XSuperSmashBrosConfig.RoleType.Chara and XRoomCharFilterTipsConfigs.EnumFilterType.SSBRole
    or XRoomCharFilterTipsConfigs.EnumSortType.SSBMonster
    XLuaUiManager.Open("UiRoomCharacterFilterTips", self,
        filterType,
        enumSortType,
        nil, nil, nil) --XCharacterConfigs.CharacterType.Normal
end
--=================
--初始化角色头像列表
--=================
function XUiSSBPickPanelHead:InitCharaHeadList()
    local script = require("XUi/XUiSuperSmashBros/Pick/DTable/XUiSSBPickCharaHeadList")
    self.CharacterList = script.New(self.PanelCharacterList, self)
end
--=================
--初始化怪物头像列表
--=================
function XUiSSBPickPanelHead:InitMonsterHeadList()
    local script = require("XUi/XUiSuperSmashBros/Pick/DTable/XUiSSBPickMonsterHeadList")
    self.MonsterList = script.New(self.PanelMonsterList, self)
end
--=================
--显示面板
--=================
function XUiSSBPickPanelHead:ShowPanel(...)
    local args = {...}
    self.ShowType = args[1] or XSuperSmashBrosConfig.RoleType.Chara
    self.TeamData = args[2]
    self.ChangePos = args[3]
    self.GameObject:SetActiveEx(true)
    self:OnEnable()
end
--=================
--隐藏面板
--=================
function XUiSSBPickPanelHead:HidePanel()
    self:OnDisable()
    self.GameObject:SetActiveEx(false)
end
--=================
--显示时
--=================
function XUiSSBPickPanelHead:OnEnable()
    XDataCenter.RoomCharFilterTipsManager.Reset()
    local sortTagId
    if self.ShowType == XSuperSmashBrosConfig.RoleType.Chara then
        self.MonsterList:Hide()
        self.CharacterList:Show()
        sortTagId = XRoomCharFilterTipsConfigs.EnumSortTag.Default
    elseif self.ShowType == XSuperSmashBrosConfig.RoleType.Monster then
        self.MonsterList:Show()
        self.CharacterList:Hide()
        sortTagId = XRoomCharFilterTipsConfigs.EnumSortTag.SSBMonsterDefault
    end
    local selectTagGroupDic = self.CurrentSelectTagGroup[self.ShowType].TagGroupDic or {}
    self:Filter(selectTagGroupDic, sortTagId, function(roles)
            return true
        end)
end

function XUiSSBPickPanelHead:Filter(selectTagGroupDic, sortTagId, isThereFilterDataCb)
    local roleList = self.ShowType == XSuperSmashBrosConfig.RoleType.Chara and XDataCenter.SuperSmashBrosManager.GetRoleList()
    or XDataCenter.SuperSmashBrosManager.GetMonsterGroupListByModeId(self.Mode:GetId())
    XDataCenter.RoomCharFilterTipsManager.Filter(self.TagCacheDic[self.ShowType], selectTagGroupDic
        , roleList
        , FilterJudge[self.ShowType]
        , function(filteredData)
            self.CurrentSelectTagGroup[self.ShowType].TagGroupDic = selectTagGroupDic
            self.CurrentSelectTagGroup[self.ShowType].SortType = sortTagId
            self:FilterRefresh(filteredData, sortTagId)
        end
        , isThereFilterDataCb)
end

function XUiSSBPickPanelHead:FilterRefresh(filteredData, sortTagType)
    if self.ShowType == XSuperSmashBrosConfig.RoleType.Chara then
        filteredData = XDataCenter.SuperSmashBrosManager.SortRoles(filteredData, sortTagType, true)
        self.CharacterList:Refresh(self.TeamData, self.ChangePos, filteredData)
    else
        filteredData = XDataCenter.SuperSmashBrosManager.SortMonsters(filteredData, sortTagType, true)
        self.MonsterList:Refresh(self.TeamData, self.ChangePos, filteredData)
    end
end
--=================
--隐藏时
--=================
function XUiSSBPickPanelHead:OnDisable()

end
--=================
--销毁时
--=================
function XUiSSBPickPanelHead:OnDestroy()

end

return XUiSSBPickPanelHead