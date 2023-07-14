local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiPhotographPanel = XClass(nil, "XUiPhotographPanel")
local XUiGridPhotographSceneBtn = require("XUi/XUiPhotograph/XUiGridPhotographSceneBtn")
local XUiGridPhotographCharacterBtn = require("XUi/XUiPhotograph/XUiGridPhotographCharacterBtn")
local XUiGridPhotographOtherBtn = require("XUi/XUiPhotograph/XUiGridPhotographOtherBtn")

local MenuBtnType = {
    Scene = 1,
    Character = 2,
    Fashion = 3,
    Action = 4,
}

function XUiPhotographPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiPhotographPanel:Init()
    self:InitMenuBtnGroup()
    self:InitDynamicTable()
    self.BtnPhotograph.CallBack = function () self:OnBtnPhotographClick() end
    self.BtnSynchronous.CallBack = function () self:OnBtnSynchronousClick() end
    self.CurCharId = self.CurCharId and self.CurCharId or XPlayer.DisplayCharId
    self:SetBtnSynchronousActiveEx(false)
end

function XUiPhotographPanel:DefaultClick()
    self:OnSelectMenuBtn(MenuBtnType.Scene, true)
    self.MenuBtns[MenuBtnType.Scene].ButtonState = CS.UiButtonState.Select
    local data = XDataCenter.PhotographManager.GetSceneTemplateById(XDataCenter.PhotographManager.GetCurSceneId())
    self:SetInfoTextName(data.Name)
end

function XUiPhotographPanel:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPhotographPanel:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPhotographPanel:InitMenuBtnGroup()
    self.MenuBtns = {
        self.BtnScene,
        self.BtnCharacter,
        self.BtnFashion,
        self.BtnAction,
    }
    self.PanelMenu:Init(self.MenuBtns, function(index) self:OnSelectMenuBtn(index) end)
end

function XUiPhotographPanel:OnSelectMenuBtn(index, isDefault)
    if self.CurMenuType and self.CurMenuType == index then
        return
    end
    self.CurMenuType = index

    self.PanelSceneList.gameObject:SetActiveEx(false)
    self.PanelCharacterList.gameObject:SetActiveEx(false)
    self.PanelOtherList.gameObject:SetActiveEx(false)

    if index == MenuBtnType.Scene then
        self.PanelSceneList.gameObject:SetActiveEx(true)
        self.CurSceneIndex = XDataCenter.PhotographManager.GetSceneIndexById(XDataCenter.PhotographManager.GetCurSceneId())
        self.CurSceneIndex = 1
        self.DynamicTableScene:SetDataSource(XDataCenter.PhotographManager.GetSceneIdList())
        self.DynamicTableScene:ReloadDataASync(self.CurSceneIndex)
    elseif index == MenuBtnType.Character then
        self.PanelCharacterList.gameObject:SetActiveEx(true)
        self.DynamicTableCharacter:SetDataSource(XDataCenter.PhotographManager.GetCharacterList())
        self.CurCharId = self.CurCharId and self.CurCharId or XPlayer.DisplayCharId
        self.CurCharIndex = XDataCenter.PhotographManager.GetCharIndexById(self.CurCharId)
        self.DynamicTableCharacter:ReloadDataASync(self.CurCharIndex)
    elseif index == MenuBtnType.Fashion then
        self.PanelOtherList.gameObject:SetActiveEx(true)
        self.FashionList = XDataCenter.FashionManager.GetCurrentTimeFashionByCharId(self.CurCharId)
        self.CurFashionIndex = self.CurFashionIndex and self.CurFashionIndex or XDataCenter.PhotographManager.GetFashionIndexByFashionList(self.CurCharId, self.FashionList)
        self.DynamicTableOther:SetDataSource(self.FashionList)
        self.DynamicTableOther:ReloadDataASync()
    elseif index == MenuBtnType.Action then
        self.PanelOtherList.gameObject:SetActiveEx(true)
        self.ActionList = XFavorabilityConfigs.GetCharacterActionById(self.CurCharId) or {}
        self.DynamicTableOther:SetDataSource(self.ActionList)
        self.DynamicTableOther:ReloadDataASync()
    end

    self:UpdateInfoType(index)

    self:PlayPanelListAnim(index)
end

function XUiPhotographPanel:InitDynamicTable()
    self.DynamicTableScene = XDynamicTableNormal.New(self.PanelSceneList)
    self.DynamicTableScene:SetProxy(XUiGridPhotographSceneBtn)
    self.DynamicTableScene:SetDelegate(self)

    self.DynamicTableCharacter = XDynamicTableNormal.New(self.PanelCharacterList)
    self.DynamicTableCharacter:SetProxy(XUiGridPhotographCharacterBtn)
    self.DynamicTableCharacter:SetDelegate(self)

    self.DynamicTableOther = XDynamicTableNormal.New(self.PanelOtherList)
    self.DynamicTableOther:SetProxy(XUiGridPhotographOtherBtn)
    self.DynamicTableOther:SetDelegate(self)
end

function XUiPhotographPanel:OnDynamicTableEvent(event, index, grid)
    if self.CurMenuType == MenuBtnType.Scene then -- 场景按钮格子事件处理回调
        self:OnDynamicTableSceneEvent(event, index, grid)
    elseif self.CurMenuType == MenuBtnType.Character then -- 角色按钮格子事件处理回调
        self:OnDynamicTableCharacterEvent(event, index, grid)
    elseif self.CurMenuType == MenuBtnType.Fashion then -- 涂装按钮格子事件处理回调
        self:OnDynamicTableFashionEvent(event, index, grid)
    elseif self.CurMenuType == MenuBtnType.Action then -- 动作按钮格子事件处理回调
        self:OnDynamicTableActionEvent(event, index, grid)
    end
end

function XUiPhotographPanel:OnDynamicTableSceneEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local sceneId = XDataCenter.PhotographManager.GetSceneIdByIndex(index)
        local data = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        grid:Reset()
        grid:Refrash(data)
        if self.CurSceneIndex and self.CurSceneIndex == index then
            self.CurSceneGrid = grid
            grid:SetSelect(true)
            self:SetInfoTextName(data.Name)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local sceneId = XDataCenter.PhotographManager.GetSceneIdByIndex(index)
        local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        local isHas = XDataCenter.PhotographManager.CheckSceneIsHaveById(sceneId)
        if not isHas then
            XUiManager.TipError(sceneTemplate.LockDec)
            return
        end
        if self.CurSceneIndex and self.CurSceneIndex == index then
            return
        end
        if self.CurSceneGrid ~= nil then
            self.CurSceneGrid:SetSelect(false)
        end
        self.CurSceneGrid = grid
        self.CurSceneIndex = index
        local sceneId = XDataCenter.PhotographManager.GetSceneIdByIndex(index)
        local data = XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
        self:SetInfoTextName(data.Name)
        grid:OnTouched(data)
    end
end

function XUiPhotographPanel:OnDynamicTableCharacterEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = XDataCenter.PhotographManager.GetCharacterDataByIndex(index)
        grid:Reset()
        grid:Refrash(data)
        if self.CurCharIndex and self.CurCharIndex == index then
            self.CurCharGrid = grid
            grid:SetSelect(true)
            self:SetInfoTextName(data.LogName)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurCharIndex and self.CurCharIndex == index then
            return
        end
        if self.CurCharGrid ~= nil then
            self.CurCharGrid:SetSelect(false)
        end
        self.CurCharGrid = grid
        local data = XDataCenter.PhotographManager.GetCharacterDataByIndex(index)
        self.CurCharId = data.Id
        self.CurCharIndex = index
        self.CurFashionIndex = nil -- 切换角色清空涂装index 再次点击涂装会重新获取index
        self:SetInfoTextName(data.LogName)
        grid:OnTouched(self.CurCharId)
    end
end

function XUiPhotographPanel:OnDynamicTableFashionEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.FashionList[index]
        grid:Reset()
        grid:RefrashFashion(data)
        if self.CurFashionIndex and self.CurFashionIndex == index then
            self.CurFashionGrid = grid
            grid:SetSelect(true)
            self:SetInfoTextName(XDataCenter.FashionManager.GetFashionName(data))
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local isHas = XDataCenter.FashionManager.CheckHasFashion(self.FashionList[index])
        if not isHas then
            XUiManager.TipError(CS.XTextManager.GetText("PhotoModeNoFashion"))
            return
        end
        if self.CurFashionIndex and self.CurFashionIndex == index then
            return
        end
        if self.CurFashionGrid ~= nil then
            self.CurFashionGrid:SetSelect(false)
        end
        self.CurFashionGrid = grid
        self.CurFashionIndex = index
        self:SetInfoTextName(XDataCenter.FashionManager.GetFashionName(self.FashionList[index]))
        grid:OnFashionTouched(self.CurCharId, self.FashionList[index])
    end
end

function XUiPhotographPanel:OnDynamicTableActionEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ActionList[index]
        local charData = XDataCenter.PhotographManager.GetCharacterDataById(self.CurCharId)
        grid:Reset()
        grid:RefrashAction(data, charData)
        self:SetInfoTextName()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local isHas = XDataCenter.PhotographManager.GetCharacterDataById(self.CurCharId).TrustLv >= self.ActionList[index].UnlockLv
        if not isHas then
            XUiManager.TipError(self.ActionList[index].ConditionDescript)
            return
        end
        if self.CurActionGrid ~= nil then
            self.CurActionGrid:SetSelect(false)
        end
        self.CurActionGrid = grid
        self:SetInfoTextName(self.ActionList[index].Name)
        grid:OnActionTouched(self.ActionList[index])
    end
end

function XUiPhotographPanel:OnBtnPhotographClick()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_PHOTOGRAPH)
end

function XUiPhotographPanel:OnBtnSynchronousClick()
    XDataCenter.PhotographManager.ChangeDisplay(XDataCenter.PhotographManager.GetCurSelectSceneId(), self.RootUi.SelectCharacterId, self.RootUi.SelectFashionId, function ()
        self.RootUi.CurCharacterId = self.RootUi.SelectCharacterId
        self.RootUi.CurFashionId = self.RootUi.SelectFashionId
        self:SetBtnSynchronousActiveEx(self.RootUi:CheckHasChanged())
    end)
end

function XUiPhotographPanel:SetBtnSynchronousActiveEx(bool)
    self.BtnSynchronous.gameObject:SetActiveEx(bool)
end

function XUiPhotographPanel:UpdateInfoType(btnType)
    self.TxtAction.gameObject:SetActiveEx(false)
    self.TxtScene.gameObject:SetActiveEx(false)
    self.TxTFashion.gameObject:SetActiveEx(false)
    self.TxTCharacter.gameObject:SetActiveEx(false)
    if btnType == MenuBtnType.Scene then
        self.TxtScene.gameObject:SetActiveEx(true)
    elseif btnType == MenuBtnType.Character then
        self.TxTCharacter.gameObject:SetActiveEx(true)
    elseif btnType == MenuBtnType.Fashion then
        self.TxTFashion.gameObject:SetActiveEx(true)
    elseif btnType == MenuBtnType.Action then
        self.TxtAction.gameObject:SetActiveEx(true)
    end
end

function XUiPhotographPanel:SetInfoTextName(textName)
    if not textName or textName == "" then
        self.TxtName.text = CSXTextManagerGetText("PhotoModeNotChooseText")
        return
    end

    self.TxtName.text = textName
end

function XUiPhotographPanel:PlayPanelListAnim(menuBtnType)
    self.RootUi:PlayAnimation("Qiehuan")
    if menuBtnType == MenuBtnType.Scene then
        self.RootUi:PlayAnimation("PanelSceneListEnable")
    elseif menuBtnType == MenuBtnType.Character then
        self.RootUi:PlayAnimation("PanelCharacterListEnable")
    elseif menuBtnType == MenuBtnType.Fashion or menuBtnType == MenuBtnType.Action then
        self.RootUi:PlayAnimation("PanelOtherListEnable")
    end
end

return XUiPhotographPanel