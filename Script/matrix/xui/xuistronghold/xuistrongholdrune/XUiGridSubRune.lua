local XUiGridSubRune = XClass(nil, "XUiGridSubRune")

function XUiGridSubRune:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    self:SetSelect(false)
    self.BtnClick.CallBack = function()
        clickCb(self.SubRuneId)
    end
end

function XUiGridSubRune:Refresh(runeId, subRuneId, groupId)
    self.SubRuneId = subRuneId

    local isUsing = XDataCenter.StrongholdManager.IsSubRuneUsing(subRuneId)
    self.PanelUsing.gameObject:SetActiveEx(isUsing)

    self.ImgBg.color = XStrongholdConfigs.GetRuneColor(runeId)
    self.ImgIcon:SetSprite(XStrongholdConfigs.GetSubRuneIcon(subRuneId))
    self.TxtName.text = XStrongholdConfigs.GetSubRuneName(subRuneId)
    self.TxtDesc.text = XStrongholdConfigs.GetSubRuneDesc(subRuneId)

    local isLock = XDataCenter.StrongholdManager.IsRuneLock(runeId, groupId, subRuneId)
    self.PanelLock.gameObject:SetActiveEx(isLock)
end

function XUiGridSubRune:SetSelect(value)
    self.PanelSelect.gameObject:SetActiveEx(value)
end

return XUiGridSubRune