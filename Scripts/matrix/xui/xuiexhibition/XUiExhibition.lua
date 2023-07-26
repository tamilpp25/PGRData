local XUiExhibition = XLuaUiManager.Register(XLuaUi, "UiExhibition")

local XUiGridCharacterIcon = require("XUi/XUiExhibition/XUiGridCharacterIcon")
local XUiGridCharacterName = require("XUi/XUiExhibition/XUiGridCharacterName")
local XUiGridGroupIcon = require("XUi/XUiExhibition/XUiGridGroupIcon")
local XUiGridGroupName = require("XUi/XUiExhibition/XUiGridGroupName")
local XUiPanelCollection = require("XUi/XUiExhibition/XUiPanelCollection")

local ShowComponents = {
    CharacterIcon = { Name = "CharacterIcon", PrefabName = "ExhibitionCharacterIcon", LuaScript = XUiGridCharacterIcon },
    CharacterName = { Name = "CharacterName", PrefabName = "ExhibitionCharacterName", LuaScript = XUiGridCharacterName },
    GroupIcon = { Name = "GroupIcon", PrefabName = "ExhibitionGroupIcon", LuaScript = XUiGridGroupIcon },
    GroupName = { Name = "GroupName", PrefabName = "ExhibitionGroupName", LuaScript = XUiGridGroupName }
}
local CharacterPortList = {} -- 角色显示编号
local GroupPortList = {} -- 阵营显示编号

function XUiExhibition:OnAwake()
    self:AddBtnListener()
    self:InitTabGroup()
    self:InitShowComponentList()
end

function XUiExhibition:OnStart(isSelf, showType)
    self.IsSelf = isSelf --是否浏览自身的收藏
    self.ShowType = showType or XDataCenter.ExhibitionManager.ExhibitionType.STRUCT
    self.CharacterIconGridList = {}
    self.CharacterNameGridList = {}
    self.GroupIconGridList = {}
    self.GroupNameGridList = {}
    local behaviour = self.Transform.gameObject:AddComponent(typeof(CS.XLuaBehaviour))
    if self.Update then
        behaviour.LuaUpdate = function() self:Update() end
    end
    self.CurCharacterId = nil
    self.CurIndex = nil
    self.Focusing = false
    self.ShowDetailMinScale = CS.XGame.ClientConfig:GetFloat("ExhibitionShowDetailMinScale")
    self.DetailFadeTime = CS.XGame.ClientConfig:GetFloat("ExhibitionDetailFadeTime")
    self.DetailZoomTime = CS.XGame.ClientConfig:GetFloat("ExhibitionDetailZoomTime")
    self.CollectionInfoPanel = XUiPanelCollection.New(self.PanelCollection, self)
    self.PanelTab:SelectIndex(self.ShowType)
end

function XUiExhibition:OnEnable()
    self:RefreshExhibitionInfo()
    self:CheckTabRedDot()
end

function XUiExhibition:OnDestroy()

end

function XUiExhibition:InitTabGroup()
    local tabGroup = {
        self.BtnTab1,
        self.BtnTab2,
        self.BtnTab3,
    }
    self.PanelTab:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
end

function XUiExhibition:InitShowComponentList()
    local cPortNum = self.PanelCharacterIcon.transform.childCount
    for i = 0, cPortNum - 1 do
        local name = tonumber(self.PanelCharacterIcon.transform:GetChild(i).name)
        table.insert(CharacterPortList, name)
    end
    local gPortNum = self.PanelGroupIcon.transform.childCount
    for i = 0, gPortNum - 1 do
        local name = tonumber(self.PanelGroupIcon.transform:GetChild(i).name)
        table.insert(GroupPortList, name)
    end
end

function XUiExhibition:OnClickTabCallBack(tabIndex)
    self.ShowType = tabIndex
    self:RefreshExhibitionInfo()
end

function XUiExhibition:AddBtnListener()
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnOpenCollection, self.OnBtnOpenCollectionClick)
    self:RegisterClickEvent(self.BtnCloseCollection, self.OnBtnCloseCollectionClick)
end

function XUiExhibition:RefreshExhibitionInfo()
    self.ShowName = false
    local exhibitionPortConfig = XExhibitionConfigs.GetExhibitionPortConfigByType(self.ShowType)
    local exhibitionGroupConfig = XExhibitionConfigs.GetExhibitionGroupConfigByType(self.ShowType)
    self:RefreshGroupLine()
    for _, port in pairs(CharacterPortList) do
        local config = exhibitionPortConfig[port]
        local iconGrid = self:UpdateGridComponent(port, ShowComponents.CharacterIcon, config)
        if not iconGrid then return end
        local nameGrid = self:UpdateGridComponent(port, ShowComponents.CharacterName, config)
        if not nameGrid then return end
        nameGrid:ResetPosition(iconGrid.Transform.position)
    end
    for _, port in pairs(GroupPortList) do
        local config = exhibitionGroupConfig[port]
        local iconGrid = self:UpdateGridComponent(port, ShowComponents.GroupIcon, config)
        if not iconGrid then return end
        local nameGrid = self:UpdateGridComponent(port, ShowComponents.GroupName, config)
        if not nameGrid then return end
        nameGrid:ResetPosition(iconGrid.Transform.position)
    end
    self:RefreshCollectionInfo()
end

function XUiExhibition:RefreshGroupLine()
    local inVisibleTable = XExhibitionConfigs.GetExhibitionInVisbleGroupTable(self.ShowType)
    for groupId, visible in pairs(inVisibleTable) do
        local lineGroup = self.LineRoot.transform:Find(string.format("LineGroup%02d", groupId))
        if lineGroup then lineGroup.gameObject:SetActiveEx(visible) end
    end
end

function XUiExhibition:UpdateGridComponent(portId, showComponentsType, exhibitionConfig)
    local gridComponent
    local name = showComponentsType.Name
    local gridParent = self["Panel" .. name]:Find(portId)

    if not gridParent then
        XLog.Error("XUiExhibition:UpdateGridComponent error: UI节点数量与配置不对应，请检查UI路径Panel" .. name .. "下是否存在id为: " .. portId .. "的节点")
        return
    end

    local gridList = self[name .. "GridList"]
    local visible = XExhibitionConfigs.GetIsExhibitionInVisbleGroup(self.ShowType, exhibitionConfig and exhibitionConfig.GroupId or 0)
    gridParent.gameObject:SetActiveEx(visible)
    if gridList[portId] ~= nil then
        gridComponent = gridList[portId]
        gridComponent:Refresh(exhibitionConfig or nil)
    else
        local gridGo = gridParent.childCount > 0 and gridParent:GetChild(0) or CS.UnityEngine.Object.Instantiate(self.Obj:GetPrefab(showComponentsType.PrefabName))
        gridGo.transform:SetParent(gridParent, false)
        if gridGo == nil or not gridGo:Exist() then
            return
        end
        if showComponentsType == ShowComponents.CharacterIcon or showComponentsType == ShowComponents.CharacterName then
            gridComponent = showComponentsType.LuaScript.New(self, portId, gridGo, exhibitionConfig)
        else
            gridComponent = showComponentsType.LuaScript.New(gridGo, exhibitionConfig)
        end
        gridList[portId] = gridComponent
    end
    return gridComponent
end

function XUiExhibition:Update()
    if self.Focusing then
        return
    end
    local curScale = self.PanelCharacter.localScale.x
    if curScale > self.ShowDetailMinScale and not self.ShowName then
        self.ShowName = true
        self:ShowNameLayer()
    elseif curScale < self.ShowDetailMinScale and self.ShowName then
        self.ShowName = false
        self:HideNameLayer()
    end
end

function XUiExhibition:ShowNameLayer()
    self.LayerNameCanvasGroup:DOFade(1, self.DetailFadeTime)
end

function XUiExhibition:HideNameLayer()
    self.LayerNameCanvasGroup:DOFade(0, self.DetailFadeTime)
end

function XUiExhibition:StartFocus(index, characterId)

    -- self.Focusing = true
    -- self.CurIndex = index
    -- self.CurGridCanvasGroup = self.CharacterIconGridList[index].GameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    -- self.CurGridCanvasGroup.ignoreParentGroups = true
    -- self:PlayAnimation("AnimPanelTaskHide")
    -- local offset = CS.UnityEngine.Vector3(self.IconPosition.position.x, 0, 0)
    -- self.DragArea:StartFocus(self.CharacterIconGridList[index].Transform.position, 1.0, self.DetailZoomTime, offset, true)
    self:ShowExhibitionInfo(characterId)
end

function XUiExhibition:EndFocus()
    self:PlayAnimation("AnimPanelTaskShow", function()
        CS.UnityEngine.GameObject.Destroy(self.CurGridCanvasGroup)
    end)
    self.DragArea:EndFocus(function()
        self.Focusing = false
    end)
end

function XUiExhibition:ShowExhibitionInfo(characterId)
    self.CurCharacterId = characterId
    XLuaUiManager.Open("UiExhibitionInfo", characterId, self.ShowType)
end

function XUiExhibition:OnBtnOpenCollectionClick()
    self.CollectionInfoPanel:Show(self.ShowType)
    self:PlayAnimation("AnimPanelCollectionEnable")
end

function XUiExhibition:OnBtnCloseCollectionClick()
    self:PlayAnimation("AnimPanelCollectionDisable", function()
        self.CollectionInfoPanel:Hide()
    end)
end

function XUiExhibition:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", CS.XTextManager.GetText("ExhibitionExplain") or "")
end

-- function XUiExhibition:HandleCharacterGrowUp()
--     self.CharacterIconGridList[self.CurIndex]:CharacterGrowUp()
--     self:RefreshCollectionInfo()
-- end
function XUiExhibition:RefreshCollectionInfo()
    local collectionRate = XDataCenter.ExhibitionManager.GetCollectionRate(true, self.ShowType)
    self.TxtCollectionRate.text = math.floor(collectionRate * 100)
    self.ImgRate.fillAmount = collectionRate
    if self.ShowType then
        self.TxtCenterRate.text = CS.XTextManager.GetText("ExhibitionCollectionLable" .. self.ShowType)
    else
        self.TxtCenterRate.text = CS.XTextManager.GetText("ExhibitionCollectionDefaultLable")
    end
    local totleCollectionRate = XDataCenter.ExhibitionManager.GetCollectionRate(true)
    self.TxtTotalCollectRate.text = string.format("%d%s", math.floor(totleCollectionRate * 100), "%")
end

function XUiExhibition:OnBtnBackClick()
    self:Close()
end

function XUiExhibition:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiExhibition:OnGetEvents()
    return { XEventId.EVENT_CHARACTER_EXHIBITION_AUTOSELECT }
end

function XUiExhibition:OnNotify(evt, ...)
    local args = { ... }

    if evt == XEventId.EVENT_CHARACTER_EXHIBITION_AUTOSELECT then
        if not args[1] then return end
        local selectGrid = nil
        for _, v in pairs(self.CharacterIconGridList or {}) do
            if v.CharacterId == args[1] then
                selectGrid = v
                break
            end
        end
        if not selectGrid then return end
        selectGrid:BtnSelectClick()
    end
end

--============
--检查每个页签蓝点
--============
function XUiExhibition:CheckTabRedDot()
    local manager = XDataCenter.ExhibitionManager
    local allTypes = manager.ExhibitionType
    for _, showType in pairs(allTypes or {}) do
        local tab = self["BtnTab" .. showType]
        if tab then
            local exhibitionPortConfig = XExhibitionConfigs.GetExhibitionPortConfigByType(showType)
            for _, config in pairs(exhibitionPortConfig or {}) do
                if manager.CheckNewRewardByCharacterId(config.CharacterId) then
                    tab:ShowReddot(true)
                    goto nextTab
                end
            end
            tab:ShowReddot(false)
        end
        :: nextTab ::
    end
end