local XUiDormFoundryDetailRewardItem = XClass(nil, "XUiDormFoundryDetailRewardItem")

function XUiDormFoundryDetailRewardItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiDormFoundryDetailRewardItem:OnRefresh(itemData, dircount, flag)
    if not itemData then
        return
    end

    self.ExtraAwardText.text = ""
    self.GridItemUI:Refresh(itemData)
    self:RefreshCount(dircount)
    self:MarkFlag(flag)
end

function XUiDormFoundryDetailRewardItem:Init(root)
    self.GridItemUI = XUiGridCommon.New(root, self.GridIcon)
end

function XUiDormFoundryDetailRewardItem:RefreshCount(count)
    if self.GridItemUI and self.GridItemUI.TxtCount then
        self.GridItemUI.TxtCount.text = CS.XTextManager.GetText("ShopGridCommonCount", count)
        self.GridItemUI:ShowCount(true)
    end
end

function XUiDormFoundryDetailRewardItem:RefreshExCount(count)
    if count == 0 then
        return
    end

    self.ExtraAwardText.text = string.format("(+%d)", count)
end

function XUiDormFoundryDetailRewardItem:MarkFlag(flag)
    self.ExtraAward.gameObject:SetActiveEx(flag)
end

return XUiDormFoundryDetailRewardItem