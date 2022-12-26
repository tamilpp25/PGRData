XUiHeadPortraitSelect = XClass(nil, "XUiHeadPortraitSelect")
local DefaultIndex = 1
function XUiHeadPortraitSelect:Ctor(base,ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:InitDynamicTable()
    self.GameObject:SetActiveEx(false)
end

function XUiHeadPortraitSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ScrollView)
    self.DynamicTable:SetProxy(XUiGridHeadPortrait)
    self.DynamicTable:SetDelegate(self)
    self.HeadPortrait.gameObject:SetActiveEx(false)
end

function XUiHeadPortraitSelect:SetupDynamicTable()
    self.PageDatas = XDataCenter.MarketingActivityManager.GetCharacterList()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiHeadPortraitSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index],self)
    end
end

function XUiHeadPortraitSelect:AutoAddListener()
    self.BtnHeadSure.CallBack = function()
        self:OnBtnHeadSureClick()
    end
    self.BtnHeadCancel.CallBack = function()
        if self.ClearCb then self.ClearCb() end
        self.Base:HideHeadPortraitSelect()
    end
    self.BtnClose.CallBack = function()
        if self.ClearCb then self.ClearCb() end
        self.Base:HideHeadPortraitSelect()
    end
end

function XUiHeadPortraitSelect:OnBtnHeadSureClick()
    self.DialogueData.CharacterId = self.SelectCharacterId
    self.Base:HideHeadPortraitSelect()
    if self.CallBack then
        self.CallBack()
    end
end

function XUiHeadPortraitSelect:SetData(characterId)
    local info = XMarketingActivityConfigs.GetCompositionCharacterConfigById(characterId)
    if (info ~= nil) then
        self.RImgPlayerIcon:SetRawImage(info.Icon)
        self.SelectCharacterId = characterId
        self.TxtHeadName.text = info.Name
        self.TxtDesc.text = info.Desc
    end
end

function XUiHeadPortraitSelect:PreviewHeadPortrait(dialogueData,cb,clearCb)
    self.OldSelectGrig = nil
    self:SetupDynamicTable()
    local id = dialogueData.CharacterId or self.PageDatas[DefaultIndex].Id
    self.DialogueData = dialogueData
    self.CallBack = cb
    self.ClearCb = clearCb
    self:SetData(id)
    self.GameObject:SetActiveEx(true)
end