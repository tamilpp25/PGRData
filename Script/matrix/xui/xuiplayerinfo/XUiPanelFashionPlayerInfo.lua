local XUiPlayerInfoClothGrid = require("XUi/XUiPlayerInfo/XUiPlayerInfoClothGrid")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelFashionPlayerInfo = XClass(nil, "XUiPanelFashionPlayerInfo")

local FASHION_QUALITY_LIMIT = 2

local TextManager = CS.XTextManager
local tableInsert = table.insert
local tableSort = table.sort

local Sort = function(a, b, fashionType)
    if a.IsLocked ~= b.IsLocked then
        return not a.IsLocked
    end
    if a.Data.Quality ~= b.Data.Quality then
        return a.Data.Quality > b.Data.Quality
    end
    if fashionType == XPlayerInfoConfigs.FashionType.Character then
        return a.Data.CharacterId > b.Data.CharacterId
    else
        return a.Data.Id > b.Data.Id
    end
end

function XUiPanelFashionPlayerInfo:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    self.FashionType = XPlayerInfoConfigs.FashionType.Character
    XTool.InitUiObject(self)

    self.FashionList = {}           --拥有的成员涂装
    self.WeaponFashionList = {}     --拥有的武器涂装
    self.AllFashionList = {}        --全部成员涂装信息
    self.AllWeaponFashionList = {}  --全部武器涂装信息

    self:AutoAddListener()
    self:InitDynamicTable()
end

function XUiPanelFashionPlayerInfo:AutoAddListener()
    self.BtnDropDown.onValueChanged:AddListener(function()
        self.FashionList = {}
        self.WeaponFashionList = {}
        self.AllFashionList = {}
        self.AllWeaponFashionList = {}
        self.AppearanceSettingInfo = nil
        self.FashionType = self.BtnDropDown.value

        if self.RootUi.IsOpenFromSetting then
            --从设置面板进入，使用预览数据
            self.FashionList = self.RootUi.Data.FashionShow
            self.WeaponFashionList = self.RootUi.Data.WeaponFashionShow
            self:Refresh(true)
        else
            self:Refresh()
            if self:HasPermission() then
                self:RequestData()
            end
        end
    end)
end

function XUiPanelFashionPlayerInfo:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.FashionDynamicTable)
    self.DynamicTable:SetProxy(XUiPlayerInfoClothGrid)
    self.DynamicTable:SetDelegate(self)
    self.ClothGrid.gameObject:SetActiveEx(false)
end

function XUiPanelFashionPlayerInfo:Show()
    self.GameObject:SetActiveEx(true)

    if self.RootUi.IsOpenFromSetting then
        --从设置面板进入，使用预览数据
        self.FashionList = self.RootUi.Data.FashionShow
        self.WeaponFashionList = self.RootUi.Data.WeaponFashionShow
        self:Refresh(true)
    else
        self:Refresh()
        if self:HasPermission() then
            self:RequestData()
        end
    end
end

function XUiPanelFashionPlayerInfo:RequestData()
        if self.FashionType == XPlayerInfoConfigs.FashionType.Character then
            --请求成员涂装数据
            XDataCenter.PlayerInfoManager.RequestPlayerFashionData(self.RootUi.Data.Id, function(data)
                self.FashionList = data
                self:Refresh(true)
            end)
        else
            --请求武器涂装数据
            XDataCenter.PlayerInfoManager.RequestPlayerWeaponFashionData(self.RootUi.Data.Id, function(data)
                self.WeaponFashionList = data
                self:Refresh(true)
            end)
        end
end

function XUiPanelFashionPlayerInfo:Refresh(hasPermission)
    self:SetupDynamicTable(hasPermission)
end

function XUiPanelFashionPlayerInfo:SetupDynamicTable(hasPermission,index)
    if self.FashionType == XPlayerInfoConfigs.FashionType.Character then
        self.AllFashionList = self:HandleData(XDataCenter.FashionManager.GetAllFashionTemplateInTime(), self.FashionList, XPlayerInfoConfigs.FashionType.Character, hasPermission)
        self.DynamicTable:SetDataSource(self.AllFashionList)
    else
        self.AllWeaponFashionList = self:HandleData(XWeaponFashionConfigs.GetWeaponFashionResTemplatesInTime(), self.WeaponFashionList, XPlayerInfoConfigs.FashionType.Weapon, hasPermission)
        self.DynamicTable:SetDataSource(self.AllWeaponFashionList)
    end
    self.DynamicTable:ReloadDataSync(index and index or 1)
end

--==============================--
--desc: 是否拥有权限查看信息
--@return: 有true，无false
--==============================--
function XUiPanelFashionPlayerInfo:HasPermission()
    local isFriend = XDataCenter.SocialManager.CheckIsFriend(self.RootUi.Data.Id)

    if self.FashionType == XPlayerInfoConfigs.FashionType.Character then
        self.AppearanceSettingInfo = self.RootUi.Data.AppearanceSettingInfo
                and self.RootUi.Data.AppearanceSettingInfo.FashionType or XUiAppearanceShowType.ToSelf
    else
        self.AppearanceSettingInfo = self.RootUi.Data.AppearanceSettingInfo
                and self.RootUi.Data.AppearanceSettingInfo.WeaponFashionType or XUiAppearanceShowType.ToSelf
    end

    local hasPermission = (self.AppearanceSettingInfo == XUiAppearanceShowType.ToAll)
            or (self.AppearanceSettingInfo == XUiAppearanceShowType.ToFriend and isFriend)

    return hasPermission
end

--==============================--
--desc: 获得涂装数据
--@allFashion: 配置表得到的全部涂装数据
--@ownFashion: 服务器返回的已拥有涂装
--@fashionType: 涂装类型，成员涂装需要过滤泛用式涂装
--@return: 有序的涂装数据
--==============================--
function XUiPanelFashionPlayerInfo:HandleData(allFashion, ownFashion, fashionType, hasPermission)
    if not hasPermission then
        self.PanelScore.gameObject:SetActiveEx(false)
        self.PanelFashionNone.gameObject:SetActiveEx(true)
        self.EmptyText.text = TextManager.GetText("PlayerInfoWithoutPermission")

        return {}
    end

    self.PanelScore.gameObject:SetActiveEx(true)
    self.PanelFashionNone.gameObject:SetActiveEx(false)

    local ownCount = 0
    local allFashionList = {}       --最终数据，拥有涂装排在前面
    local fashionListById = {}      --拥有涂装字典,Id做索引，用来查询未解锁成员

    for _, v in ipairs(ownFashion) do
        fashionListById[v] = v
    end

    for k, v in pairs(allFashion) do
        -- 成员涂装需要去除泛用式涂装
        local isWeaponFashion = fashionType ~= XPlayerInfoConfigs.FashionType.Character
        if isWeaponFashion or v.Quality > FASHION_QUALITY_LIMIT then
            local temData = { Data = v, IsLocked = true }
            if fashionListById[k] then
                temData.IsLocked = false
                ownCount = ownCount + 1
            end
            tableInsert(allFashionList, temData)
        end
    end
    tableSort(allFashionList, function(item1, item2)
        return Sort(item1, item2, self.FashionType)
    end)

    -- 计算收集率
    local score = string.format("%.1f", (ownCount / #allFashionList) * 100)
    self.TxtShouJiLv.text = score .. "%"

    return allFashionList
end

function XUiPanelFashionPlayerInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.FashionType == XPlayerInfoConfigs.FashionType.Character then
            grid:UpdateGrid(self.AllFashionList[index], self.FashionType)
        else
            grid:UpdateGrid(self.AllWeaponFashionList[index], self.FashionType)
        end
    end
end

function XUiPanelFashionPlayerInfo:Close()
    self.FashionList = {}
    self.WeaponFashionList = {}
    self.AllFashionList = {}
    self.AllWeaponFashionList = {}
    self.AppearanceSettingInfo = nil
    self.GameObject:SetActiveEx(false)
end



return XUiPanelFashionPlayerInfo