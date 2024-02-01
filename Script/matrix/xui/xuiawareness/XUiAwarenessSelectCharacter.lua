local XUiAwarenessSelectCharacter = XLuaUiManager.Register(XLuaUi, "UiAwarenessSelectCharacter")

local XUiPanelCharacterOwnedInfo = require("XUi/XUiCharacter/XUiPanelCharacterOwnedInfo")
local XUiGridAwarenessSelectCharacter = require("XUi/XUiAwareness/Grid/XUiGridAwarenessSelectCharacter")
local XUiGridCondition = require("XUi/XUiExhibition/XUiGridCondition")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local ConditionDesNum = 2

function XUiAwarenessSelectCharacter:OnAwake()
    self:InitButton()
    self:InitModel()
    self:InitDynamicTable()

    self.CurrCharacter = nil
    self.CurrListIndex = 1
    self.ConditionGrids = {}
end

function XUiAwarenessSelectCharacter:OnStart(chapterId, targetCharacter)
    self.ChapterId = chapterId
    self.TargetCharacter = targetCharacter

    self.Chapter = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.ChapterId)
end

function XUiAwarenessSelectCharacter:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnJoin, self.OnBtnJoinClick)
    XUiHelper.RegisterClickEvent(self, self.BtnQuit, self.OnBtnQuitClick)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    -- 装备面板
    self.PanelCharacterOwnedInfo = XUiPanelCharacterOwnedInfo.New(self, self.Transform)
    self.PanelCharacterOwnedInfo:Init()
end

function XUiAwarenessSelectCharacter:InitModel()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiAwarenessSelectCharacter:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGridAwarenessSelectCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiAwarenessSelectCharacter:OnEnable()
    self:UpdateCharacters()
    self:UpdateRightCharacterInfo()
end

function XUiAwarenessSelectCharacter:RoleSortFun(list)
    local currOccList = {} --当前chapter驻守的
    local unInOccList = {} -- 符合条件 未驻守
    local inOccupyList = {} -- 符合条件 已驻守在其他chapter
    local unConditionList = {} -- 不符合条件
    for k, character in pairs(list) do
        if self.Chapter:IsCharConditionMatch(character.Id) then
            if XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(character.Id) then
                if XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(character.Id) == self.ChapterId then
                    table.insert(currOccList, character)
                else
                    table.insert(inOccupyList, character)
                end
            else
                table.insert(unInOccList, character)
            end
        else
            table.insert(unConditionList, character)
        end
    end

    local tempList = appendArray(currOccList, unInOccList)
    tempList = appendArray(tempList, inOccupyList)
    tempList = appendArray(tempList, unConditionList)
    return tempList
end

-- 刷新左边角色列表
function XUiAwarenessSelectCharacter:UpdateCharacters()
    local roleList = XMVCA.XCharacter:GetOwnCharacterList()
    roleList = self:RoleSortFun(roleList)
    local index = 1
    if self.TargetCharacter then
        for k, character in pairs(roleList) do
            if self.TargetCharacter == character then
                index = k              
            end
        end
    end
    self:UpdateDynamicTable(roleList, index)
end

function XUiAwarenessSelectCharacter:UpdateDynamicTable(list, index)
    self.CurrShowList = list
    self.CurrListIndex = index
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync(index or 1)
end

-- 角色被选中
function XUiAwarenessSelectCharacter:OnGridSelected(character)
    if character == self.CurrCharacter then
        return
    end

    self.CurrCharacter = character
    self:UpdateRightCharacterInfo()
    self:UpdateRoleModel()
end

-- 刷新条件解锁信息
function XUiAwarenessSelectCharacter:UpdateConditionInfo()
    local conditionIds = self.Chapter:GetSelectCharCondition()
    for i = 1, ConditionDesNum do
        local conditionGrid = self.ConditionGrids[i]
        if not conditionGrid then
            conditionGrid = XUiGridCondition.New(self["GridCondition" .. i])
            self.ConditionGrids[i] = conditionGrid
        end
        conditionGrid:Refresh(conditionIds[i], self.CurrCharacter.Id)
    end
end

-- 刷新右边角色信息
function XUiAwarenessSelectCharacter:UpdateRightCharacterInfo()
    if not self.CurrCharacter then
        return
    end
    
    local characterId = self.CurrCharacter.Id

    -- 装备面板
    self.PanelCharacterOwnedInfo:UpdateView(characterId)

    local isOccupyChar = self.Chapter:GetCharacterId() == self.CurrCharacter.Id
    self.BtnJoin.gameObject:SetActiveEx(not isOccupyChar and self.Chapter:IsCharConditionMatch(self.CurrCharacter.Id))
    self.BtnQuit.gameObject:SetActiveEx(isOccupyChar)
    self.BtnJoin.gameObject:GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("BtnOccupyJoinImg3"))
    self.TxtConditionTitle.text = CS.XTextManager.GetText("AwarenessSendMemberCalled")

    self:UpdateConditionInfo()
end

-- 刷新3D模型
function XUiAwarenessSelectCharacter:UpdateRoleModel()
    if not self.CurrCharacter then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    local cb = function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end
    
    --MODEL_UINAME对应UiModelTransform表，设置模型位置
    self.RoleModelPanel:UpdateCharacterModel(self.CurrCharacter.Id, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiSuperSmashBrosCharacter, cb)
end

function XUiAwarenessSelectCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local isCurrSelected = self.CurrListIndex == index
        grid:Refresh(self.CurrShowList[index], self.Chapter)
        grid:SetSelect(isCurrSelected)
        if isCurrSelected then
            self.CurrGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrGrid:SetSelect(false)
        grid:SetSelect(true)
        self.CurrGrid = grid
        self.CurrListIndex = index
    end
end

function XUiAwarenessSelectCharacter:OnBtnJoinClick()
    local selectCharacterId = self.CurrCharacter.Id
    if not self.Chapter:CanAssign() then
        XUiManager.TipMsg(CS.XTextManager.GetText("StageUnlockCondition", self.Chapter:GetName()))
        return
    end

    if not self.Chapter:IsCharConditionMatch(selectCharacterId) then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignSelectNotMatch")) -- "该成员不符合条件"
        return
    end

    local inOtherChapterId = XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(selectCharacterId)
    if inOtherChapterId and inOtherChapterId ~= self.ChapterId then
        XUiManager.TipMsg(CS.XTextManager.GetText("AwarenessSelectIsUsed")) -- "该成员已在其他区域驻守"
        return
    end

    XDataCenter.FubenAwarenessManager.AwarenessSetCharacterRequest(self.ChapterId, selectCharacterId, function()
        self:Close()
        XUiManager.TipMsg(CS.XTextManager.GetText("AwarenessOccupySuccess")) -- 驻守成功
    end)
end

function XUiAwarenessSelectCharacter:OnBtnQuitClick()
    local selectCharacterId = 0

    XDataCenter.FubenAwarenessManager.AwarenessSetCharacterRequest(self.ChapterId, selectCharacterId, function()
        self:Close()
        XUiManager.TipMsg(CS.XTextManager.GetText("AssignOccupyUnselected")) -- 卸下成功
    end)
end