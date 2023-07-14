XUiGridExploreItem = XClass(nil, "XUiGridExploreItem")
local FirstIndex = 1

function XUiGridExploreItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridExploreItem:SetButtonCallBack()
    self.BtnRole.CallBack = function()
        self:OnBtnRoleClick()
    end
end

function XUiGridExploreItem:OnBtnRoleClick()
    self.Base:SetItemData(self.CharacterId)
    self:SetSelectShow(self.Base)
    self.Base.OldSelectGrig:SetSelectShow(self.Base)
    self.Base.OldSelectGrig = self
    self:ClearRedPoint()
end

function XUiGridExploreItem:UpdateGrid(chapter, parent, index)
    self.Base = parent
    self.CharacterId = chapter.Id
    if chapter.Icon ~= nil then
        self.RItemImg:SetRawImage(chapter.Icon)
    end
    if index and index == FirstIndex then
        self:OnBtnRoleClick()
    end
    self:SetSelectShow(parent)
    self:CheckRedPoint()
end

function XUiGridExploreItem:SetSelectShow(parent)
    if parent.SelectCharacterId == self.CharacterId then
        self:ShowSelect(true)
    else
        self:ShowSelect(false)
    end
    if not self.Base.OldSelectGrig then
        self.Base.OldSelectGrig = self
    end
end

function XUiGridExploreItem:ShowSelect(bShow)
    self.ImgRoleSelect.gameObject:SetActiveEx(bShow)
end

function XUiGridExploreItem:CheckRedPoint()
    self.BtnRole:ShowReddot(XDataCenter.FubenMainLineManager.CheckHaveNewExploreItemByItemId(self.CharacterId))
end

function XUiGridExploreItem:ClearRedPoint()
    XDataCenter.FubenMainLineManager.MarkNewExploreItemRedPointByItemId(self.CharacterId)
    self.BtnRole:ShowReddot(false)
end